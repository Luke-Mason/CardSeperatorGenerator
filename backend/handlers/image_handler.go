package handlers

import (
	"card-separator/services"
	"context"
	"encoding/json"
	"log"
	"net/http"
	"time"

	"github.com/gorilla/mux"
)

type ImageHandler struct {
	service *services.ImageService
}

func NewImageHandler(service *services.ImageService) *ImageHandler {
	return &ImageHandler{service: service}
}

// GetImage handles GET /api/images/{size}?url=...
func (h *ImageHandler) GetImage(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	size := vars["size"]
	imageURL := r.URL.Query().Get("url")

	if imageURL == "" {
		http.Error(w, "Missing 'url' query parameter", http.StatusBadRequest)
		return
	}

	ctx, cancel := context.WithTimeout(r.Context(), 30*time.Second)
	defer cancel()

	imageData, err := h.service.GetImage(ctx, imageURL, size)
	if err != nil {
		log.Printf("[API] Failed to get image: %v", err)
		http.Error(w, "Failed to retrieve image", http.StatusInternalServerError)
		return
	}

	w.Header().Set("Content-Type", "image/jpeg")
	w.Header().Set("Cache-Control", "public, max-age=604800") // 7 days
	w.Write(imageData)
}

// GetAllSizes handles GET /api/images?url=...
// Returns JSON with URLs for all image sizes
func (h *ImageHandler) GetAllSizes(w http.ResponseWriter, r *http.Request) {
	imageURL := r.URL.Query().Get("url")

	if imageURL == "" {
		http.Error(w, "Missing 'url' query parameter", http.StatusBadRequest)
		return
	}

	// Build response with all size URLs
	baseURL := "http://" + r.Host
	if r.TLS != nil {
		baseURL = "https://" + r.Host
	}

	response := map[string]string{
		"thumbnail": baseURL + "/api/images/thumbnail?url=" + imageURL,
		"medium":    baseURL + "/api/images/medium?url=" + imageURL,
		"full":      baseURL + "/api/images/full?url=" + imageURL,
		"original":  baseURL + "/api/images/original?url=" + imageURL,
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}
