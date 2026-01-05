package services

import (
	"bytes"
	"card-separator/database"
	"card-separator/storage"
	"context"
	"crypto/md5"
	"fmt"
	"image"
	"image/jpeg"
	"io"
	"log"
	"net/http"
	"sync"

	"github.com/disintegration/imaging"
)

type ImageService struct {
	db         *database.DB
	storage    *storage.MinIOStorage
	imageSizes map[string]int

	// Concurrency control
	downloadSemaphore chan struct{}
	cacheLocks        sync.Map // Per-image mutex locks
}

// NewImageService creates a new image service
func NewImageService(db *database.DB, storage *storage.MinIOStorage, imageSizes map[string]int) *ImageService {
	return &ImageService{
		db:                db,
		storage:           storage,
		imageSizes:        imageSizes,
		downloadSemaphore: make(chan struct{}, 10), // Max 10 concurrent downloads
	}
}

// GetImage retrieves or creates an image at the specified size
func (s *ImageService) GetImage(ctx context.Context, imageURL string, size string) ([]byte, error) {
	// Get target width
	width, ok := s.imageSizes[size]
	if !ok {
		return nil, fmt.Errorf("invalid image size: %s", size)
	}

	// Generate hash for cache key
	hash := getImageHash(imageURL)
	objectKey := fmt.Sprintf("%s/%s.jpg", size, hash)

	// Check if image exists in MinIO
	if s.storage.Exists(ctx, objectKey) {
		// Update last accessed time
		s.db.UpdateImageAccess(hash, size)
		return s.storage.Get(ctx, objectKey)
	}

	// Image not in cache, need to download and process
	return s.downloadAndProcessImage(ctx, imageURL, hash, size, width, objectKey)
}

func (s *ImageService) downloadAndProcessImage(ctx context.Context, imageURL, hash, size string, width int, objectKey string) ([]byte, error) {
	// Get or create per-image lock
	lockInterface, _ := s.cacheLocks.LoadOrStore(hash, &sync.Mutex{})
	lock := lockInterface.(*sync.Mutex)

	lock.Lock()
	defer lock.Unlock()

	// Double-check after acquiring lock
	if s.storage.Exists(ctx, objectKey) {
		return s.storage.Get(ctx, objectKey)
	}

	// Acquire download semaphore
	s.downloadSemaphore <- struct{}{}
	defer func() { <-s.downloadSemaphore }()

	// Download original image
	log.Printf("[IMAGE] Downloading: %s", imageURL)
	originalData, err := s.downloadImage(imageURL)
	if err != nil {
		return nil, fmt.Errorf("failed to download image: %w", err)
	}

	// Save original to MinIO
	originalKey := fmt.Sprintf("original/%s.jpg", hash)
	if !s.storage.Exists(ctx, originalKey) {
		if err := s.storage.Put(ctx, originalKey, originalData, "image/jpeg"); err != nil {
			log.Printf("[IMAGE] Warning: failed to save original: %v", err)
		} else {
			s.db.TrackImage(hash, imageURL, originalKey, "original", int64(len(originalData)))
		}
	}

	// Process image to requested size
	var processedData []byte
	if size == "original" || width == 0 {
		processedData = originalData
	} else {
		processedData, err = s.processImage(originalData, width)
		if err != nil {
			log.Printf("[IMAGE] Warning: using original due to processing error: %v", err)
			processedData = originalData
		}
	}

	// Save processed image to MinIO
	if err := s.storage.Put(ctx, objectKey, processedData, "image/jpeg"); err != nil {
		return nil, fmt.Errorf("failed to save processed image: %w", err)
	}

	// Track in database
	s.db.TrackImage(hash, imageURL, objectKey, size, int64(len(processedData)))

	log.Printf("[IMAGE] Cached: %s (%s, %d bytes)", objectKey, size, len(processedData))

	return processedData, nil
}

func (s *ImageService) downloadImage(url string) ([]byte, error) {
	resp, err := http.Get(url)
	if err != nil {
		return nil, err
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("unexpected status code: %d", resp.StatusCode)
	}

	return io.ReadAll(resp.Body)
}

func (s *ImageService) processImage(data []byte, targetWidth int) ([]byte, error) {
	// Decode image
	img, format, err := image.Decode(bytes.NewReader(data))
	if err != nil {
		return nil, fmt.Errorf("failed to decode image: %w", err)
	}

	// Only process if not JPEG or if we need to resize
	bounds := img.Bounds()
	currentWidth := bounds.Dx()

	// If image is already smaller than target, don't upscale
	if currentWidth <= targetWidth {
		if format == "jpeg" {
			return data, nil
		}
		// Convert to JPEG
		var buf bytes.Buffer
		if err := jpeg.Encode(&buf, img, &jpeg.Options{Quality: 85}); err != nil {
			return nil, err
		}
		return buf.Bytes(), nil
	}

	// Resize image
	resized := imaging.Resize(img, targetWidth, 0, imaging.Lanczos)

	// Encode as JPEG
	var buf bytes.Buffer
	if err := jpeg.Encode(&buf, resized, &jpeg.Options{Quality: 85}); err != nil {
		return nil, err
	}

	return buf.Bytes(), nil
}

func getImageHash(url string) string {
	hash := md5.Sum([]byte(url))
	return fmt.Sprintf("%x", hash)
}
