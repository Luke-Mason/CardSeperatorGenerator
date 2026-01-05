package main

import (
	"crypto/md5"
	"encoding/hex"
	"encoding/json"
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/disintegration/imaging"
	"github.com/gorilla/mux"
	"github.com/rs/cors"
)

const (
	cacheDir       = "./cache"
	thumbnailSize  = 300
	mediumSize     = 600
	originalSize   = 1200
	maxConcurrent  = 10
	cacheMaxAge    = 7 * 24 * time.Hour // 7 days
)

var (
	downloadSemaphore = make(chan struct{}, maxConcurrent)
	cacheLocks        = sync.Map{}
)

type ImageService struct {
	cacheDir string
}

type CardImage struct {
	Thumbnail string `json:"thumbnail"`
	Medium    string `json:"medium"`
	Full      string `json:"full"`
	Original  string `json:"original"`
}

func NewImageService() *ImageService {
	// Create cache directories
	os.MkdirAll(filepath.Join(cacheDir, "thumbnail"), 0755)
	os.MkdirAll(filepath.Join(cacheDir, "medium"), 0755)
	os.MkdirAll(filepath.Join(cacheDir, "full"), 0755)
	os.MkdirAll(filepath.Join(cacheDir, "original"), 0755)

	return &ImageService{
		cacheDir: cacheDir,
	}
}

// getImageHash creates a unique hash for the image URL
func getImageHash(url string) string {
	hash := md5.Sum([]byte(url))
	return hex.EncodeToString(hash[:])
}

// getLock gets or creates a mutex for a specific image hash
func getLock(hash string) *sync.Mutex {
	lock, _ := cacheLocks.LoadOrStore(hash, &sync.Mutex{})
	return lock.(*sync.Mutex)
}

// downloadImage downloads an image from a URL
func downloadImage(url string) ([]byte, error) {
	downloadSemaphore <- struct{}{}
	defer func() { <-downloadSemaphore }()

	resp, err := http.Get(url)
	if err != nil {
		return nil, fmt.Errorf("failed to download image: %w", err)
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("bad status code: %d", resp.StatusCode)
	}

	data, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read image data: %w", err)
	}

	return data, nil
}

// processImage resizes an image to the specified width
func processImage(data []byte, width int) ([]byte, error) {
	img, err := imaging.Decode(strings.NewReader(string(data)))
	if err != nil {
		return nil, fmt.Errorf("failed to decode image: %w", err)
	}

	// Resize maintaining aspect ratio
	resized := imaging.Resize(img, width, 0, imaging.Lanczos)

	// Save to temp file and read back (most reliable method)
	tmpFile := filepath.Join(os.TempDir(), fmt.Sprintf("resize_%d.jpg", time.Now().UnixNano()))
	err = imaging.Save(resized, tmpFile, imaging.JPEGQuality(85))
	if err != nil {
		return nil, fmt.Errorf("failed to encode image: %w", err)
	}
	defer os.Remove(tmpFile)

	return os.ReadFile(tmpFile)
}

// getOrCreateImage gets a cached image or creates it if it doesn't exist
func (s *ImageService) getOrCreateImage(url, size string, width int) ([]byte, error) {
	hash := getImageHash(url)
	cachePath := filepath.Join(s.cacheDir, size, hash+".jpg")

	// Check if cached file exists and is recent
	if info, err := os.Stat(cachePath); err == nil {
		if time.Since(info.ModTime()) < cacheMaxAge {
			return os.ReadFile(cachePath)
		}
	}

	// Lock this specific image to prevent concurrent downloads
	lock := getLock(hash)
	lock.Lock()
	defer lock.Unlock()

	// Double-check after acquiring lock
	if data, err := os.ReadFile(cachePath); err == nil {
		return data, nil
	}

	// Download original image
	log.Printf("Downloading image: %s (size: %s)", url, size)
	originalData, err := downloadImage(url)
	if err != nil {
		return nil, err
	}

	// Save original
	originalPath := filepath.Join(s.cacheDir, "original", hash+".jpg")
	if err := os.WriteFile(originalPath, originalData, 0644); err != nil {
		log.Printf("Warning: failed to save original: %v", err)
	}

	// Process image if not original size
	var processedData []byte
	if size == "original" {
		processedData = originalData
	} else {
		processedData, err = processImage(originalData, width)
		if err != nil {
			log.Printf("Warning: failed to process image, using original: %v", err)
			processedData = originalData
		}
	}

	// Save to cache
	if err := os.WriteFile(cachePath, processedData, 0644); err != nil {
		log.Printf("Warning: failed to cache image: %v", err)
	}

	return processedData, nil
}

// handleImageProxy proxies and caches card images
func (s *ImageService) handleImageProxy(w http.ResponseWriter, r *http.Request) {
	vars := mux.Vars(r)
	size := vars["size"]
	imageURL := r.URL.Query().Get("url")

	if imageURL == "" {
		http.Error(w, "missing url parameter", http.StatusBadRequest)
		return
	}

	var width int
	switch size {
	case "thumbnail":
		width = thumbnailSize
	case "medium":
		width = mediumSize
	case "full":
		width = originalSize
	case "original":
		width = 0 // no resize
	default:
		http.Error(w, "invalid size (use: thumbnail, medium, full, original)", http.StatusBadRequest)
		return
	}

	data, err := s.getOrCreateImage(imageURL, size, width)
	if err != nil {
		log.Printf("Error processing image: %v", err)
		http.Error(w, "failed to process image", http.StatusInternalServerError)
		return
	}

	// Set caching headers
	w.Header().Set("Content-Type", "image/jpeg")
	w.Header().Set("Cache-Control", "public, max-age=604800") // 7 days
	w.Header().Set("Content-Length", strconv.Itoa(len(data)))

	w.Write(data)
}

// handleGetCardImages returns URLs for all image sizes
func (s *ImageService) handleGetCardImages(w http.ResponseWriter, r *http.Request) {
	imageURL := r.URL.Query().Get("url")
	if imageURL == "" {
		http.Error(w, "missing url parameter", http.StatusBadRequest)
		return
	}

	baseURL := fmt.Sprintf("http://%s/api/images", r.Host)

	response := CardImage{
		Thumbnail: fmt.Sprintf("%s/thumbnail?url=%s", baseURL, imageURL),
		Medium:    fmt.Sprintf("%s/medium?url=%s", baseURL, imageURL),
		Full:      fmt.Sprintf("%s/full?url=%s", baseURL, imageURL),
		Original:  fmt.Sprintf("%s/original?url=%s", baseURL, imageURL),
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(response)
}

// handleHealth returns health status
func handleHealth(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]string{
		"status": "ok",
		"time":   time.Now().Format(time.RFC3339),
	})
}

// handleCacheStats returns cache statistics
func (s *ImageService) handleCacheStats(w http.ResponseWriter, r *http.Request) {
	stats := make(map[string]int)

	for _, size := range []string{"thumbnail", "medium", "full", "original"} {
		dir := filepath.Join(s.cacheDir, size)
		entries, err := os.ReadDir(dir)
		if err != nil {
			stats[size] = 0
			continue
		}
		stats[size] = len(entries)
	}

	w.Header().Set("Content-Type", "application/json")
	json.NewEncoder(w).Encode(map[string]interface{}{
		"cached_images": stats,
		"cache_dir":     s.cacheDir,
	})
}

func main() {
	imageService := NewImageService()

	r := mux.NewRouter()

	// API routes
	api := r.PathPrefix("/api").Subrouter()
	api.HandleFunc("/health", handleHealth).Methods("GET")
	api.HandleFunc("/images/{size}", imageService.handleImageProxy).Methods("GET")
	api.HandleFunc("/images", imageService.handleGetCardImages).Methods("GET")
	api.HandleFunc("/cache/stats", imageService.handleCacheStats).Methods("GET")

	// CORS middleware
	handler := cors.New(cors.Options{
		AllowedOrigins:   []string{"http://localhost:5173", "http://localhost:3000"},
		AllowedMethods:   []string{"GET", "POST", "OPTIONS"},
		AllowedHeaders:   []string{"*"},
		AllowCredentials: true,
	}).Handler(r)

	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	log.Printf("Starting server on port %s", port)
	log.Printf("Cache directory: %s", cacheDir)
	log.Fatal(http.ListenAndServe(":"+port, handler))
}
