package services

import (
	"card-separator/database"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"strconv"
	"time"
)

type CardSyncService struct {
	db         *database.DB
	httpClient *http.Client
}

// APICard represents a card from the OPTCG API
type APICard struct {
	CardName      string `json:"card_name"`
	CardSetID     string `json:"card_set_id"`
	CardCost      string `json:"card_cost"`
	CardPower     string `json:"card_power"`
	CardColor     string `json:"card_color"`
	CardType      string `json:"card_type"`
	Rarity        string `json:"rarity"`
	Attribute     string `json:"attribute"`
	CardText      string `json:"card_text"`
	CardImage     string `json:"card_image"`
	SetID         string `json:"set_id"`
	SetName       string `json:"set_name"`
	CounterAmount int    `json:"counter_amount"`
}

// NewCardSyncService creates a new card sync service
func NewCardSyncService(db *database.DB) *CardSyncService {
	return &CardSyncService{
		db: db,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// SyncSetCards fetches all cards for a specific set from OPTCG API
func (s *CardSyncService) SyncSetCards(setID string) (int, error) {
	log.Printf("[SYNC] Fetching cards for set %s from OPTCG API...", setID)

	// Fetch from OPTCG API
	url := fmt.Sprintf("https://optcgapi.com/api/sets/%s/", setID)
	resp, err := s.httpClient.Get(url)
	if err != nil {
		return 0, fmt.Errorf("failed to fetch cards from API: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return 0, fmt.Errorf("unexpected status code from OPTCG API: %d", resp.StatusCode)
	}

	var apiCards []APICard
	if err := json.NewDecoder(resp.Body).Decode(&apiCards); err != nil {
		return 0, fmt.Errorf("failed to decode cards response: %w", err)
	}

	// Convert and upsert cards
	count := 0
	for _, apiCard := range apiCards {
		card := s.convertAPICard(&apiCard)
		if err := s.db.UpsertCard(card); err != nil {
			log.Printf("[SYNC] Warning: failed to upsert card %s: %v", card.CardSetID, err)
			continue
		}
		count++
	}

	// Update set card count
	if err := s.db.UpdateSetCardCount(setID, count); err != nil {
		log.Printf("[SYNC] Warning: failed to update set card count: %v", err)
	}

	log.Printf("[SYNC] Successfully synced %d cards for set %s", count, setID)
	return count, nil
}

func (s *CardSyncService) convertAPICard(apiCard *APICard) *database.Card {
	// Parse cost and power as integers
	cost, _ := strconv.Atoi(apiCard.CardCost)
	power, _ := strconv.Atoi(apiCard.CardPower)

	return &database.Card{
		CardSetID:    apiCard.CardSetID,
		CardName:     apiCard.CardName,
		SetID:        apiCard.SetID,
		SetName:      apiCard.SetName,
		CardImageURL: apiCard.CardImage,
		CardColor:    apiCard.CardColor,
		CardType:     apiCard.CardType,
		CardCost:     cost,
		CardPower:    power,
		Rarity:       apiCard.Rarity,
		Attribute:    apiCard.Attribute,
		CardText:     apiCard.CardText,
	}
}
