package handlers

import (
	"card-separator/database"
	"card-separator/services"
	"encoding/json"
	"log"
	"net/http"
	"time"
)

type SetHandler struct {
	db          *database.DB
	syncService *services.SetSyncService
}

func NewSetHandler(db *database.DB, syncService *services.SetSyncService) *SetHandler {
	return &SetHandler{
		db:          db,
		syncService: syncService,
	}
}

// ListSets handles GET /api/sets
func (h *SetHandler) ListSets(w http.ResponseWriter, r *http.Request) {
	sets, err := h.db.GetAllSets()
	if err != nil {
		log.Printf("[API] Failed to fetch sets: %v", err)
		http.Error(w, "Failed to fetch sets", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(sets)
}

// SyncSets handles POST /api/sets/sync
func (h *SetHandler) SyncSets(w http.ResponseWriter, r *http.Request) {
	count, err := h.syncService.SyncAllSets()
	if err != nil {
		log.Printf("[API] Failed to sync sets: %v", err)
		http.Error(w, err.Error(), http.StatusInternalServerError)
		return
	}

	response := map[string]interface{}{
		"synced_sets": count,
		"timestamp":   time.Now().Format(time.RFC3339),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}
