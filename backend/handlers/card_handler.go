package handlers

import (
	"card-separator/database"
	"card-separator/services"
	"encoding/json"
	"log"
	"net/http"
	"strconv"

	"github.com/gorilla/mux"
)

type CardHandler struct {
	db          *database.DB
	syncService *services.CardSyncService
}

func NewCardHandler(db *database.DB, syncService *services.CardSyncService) *CardHandler {
	return &CardHandler{
		db:          db,
		syncService: syncService,
	}
}

// GetSetCards handles GET /api/sets/{set_id}/cards
func (h *CardHandler) GetSetCards(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	setID := vars["set_id"]

	cards, err := h.db.GetCardsBySet(setID)
	if err != nil {
		log.Printf("[API] Failed to fetch cards for set %s: %v", setID, err)
		http.Error(w, "Failed to fetch cards", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(cards)
}

// SyncSetCards handles POST /api/sets/{set_id}/sync
func (h *CardHandler) SyncSetCards(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	setID := vars["set_id"]

	count, err := h.syncService.SyncSetCards(setID)
	if err != nil {
		log.Printf("[API] Failed to sync cards for set %s: %v", setID, err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	response := map[string]interface{}{
		"synced_cards": count,
		"set_id":       setID,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// SearchCards handles GET /api/cards?color=...&type=...&rarity=...
func (h *CardHandler) SearchCards(w http.ResponseWriter, r *http.Request) {
	color := r.URL.Query().Get("color")
	cardType := r.URL.Query().Get("type")
	rarity := r.URL.Query().Get("rarity")

	limitStr := r.URL.Query().Get("limit")
	offsetStr := r.URL.Query().Get("offset")

	limit := 100
	offset := 0

	if limitStr != "" {
		if l, err := strconv.Atoi(limitStr); err == nil {
			limit = l
		}
	}
	if offsetStr != "" {
		if o, err := strconv.Atoi(offsetStr); err == nil {
			offset = o
		}
	}

	cards, err := h.db.SearchCards(color, cardType, rarity, limit, offset)
	if err != nil {
		log.Printf("[API] Failed to search cards: %v", err)
		http.Error(w, "Failed to search cards", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(cards)
}
