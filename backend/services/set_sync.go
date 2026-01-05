package services

import (
	"card-separator/database"
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"time"
)

type SetSyncService struct {
	db         *database.DB
	httpClient *http.Client
}

type OPTCGSet struct {
	SetID   string `json:"set_id"`
	SetName string `json:"set_name"`
}

// NewSetSyncService creates a new set sync service
func NewSetSyncService(db *database.DB) *SetSyncService {
	return &SetSyncService{
		db: db,
		httpClient: &http.Client{
			Timeout: 30 * time.Second,
		},
	}
}

// SyncAllSets fetches all sets from OPTCG API and caches them
func (s *SetSyncService) SyncAllSets() (int, error) {
	log.Println("[SYNC] Fetching sets from OPTCG API...")

	// Fetch from OPTCG API
	resp, err := s.httpClient.Get("https://optcgapi.com/api/allSets/")
	if err != nil {
		return 0, fmt.Errorf("failed to fetch sets from API: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return 0, fmt.Errorf("unexpected status code from OPTCG API: %d", resp.StatusCode)
	}

	var sets []OPTCGSet
	if err := json.NewDecoder(resp.Body).Decode(&sets); err != nil {
		return 0, fmt.Errorf("failed to decode sets response: %w", err)
	}

	// Upsert into database
	for _, set := range sets {
		if err := s.db.UpsertSet(set.SetID, set.SetName); err != nil {
			return 0, fmt.Errorf("failed to upsert set %s: %w", set.SetID, err)
		}
	}

	log.Printf("[SYNC] Successfully synced %d sets", len(sets))
	return len(sets), nil
}

// StartAutoSync starts a background goroutine that syncs sets periodically
func (s *SetSyncService) StartAutoSync(interval time.Duration) {
	ticker := time.NewTicker(interval)
	go func() {
		for range ticker.C {
			if _, err := s.SyncAllSets(); err != nil {
				log.Printf("[SYNC] Auto-sync failed: %v", err)
			}
		}
	}()
	log.Printf("[SYNC] Auto-sync started (interval: %v)", interval)
}
