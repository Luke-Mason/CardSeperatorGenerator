package database

import "time"

// Set represents a card set (e.g., OP-01, OP-02)
type Set struct {
	SetID      string    `json:"set_id"`
	SetName    string    `json:"set_name"`
	CardCount  int       `json:"card_count"`
	LastSynced time.Time `json:"last_synced"`
	CreatedAt  time.Time `json:"created_at"`
}

// Card represents a single card with all its metadata
type Card struct {
	ID           int       `json:"id"`
	CardSetID    string    `json:"card_set_id"`    // e.g., "OP01-077"
	CardName     string    `json:"card_name"`
	SetID        string    `json:"set_id"`         // e.g., "OP-01"
	SetName      string    `json:"set_name"`
	CardImageURL string    `json:"card_image_url"` // Original OPTCG URL
	CardColor    string    `json:"card_color"`
	CardType     string    `json:"card_type"`
	CardCost     int       `json:"card_cost"`
	CardPower    int       `json:"card_power"`
	Rarity       string    `json:"rarity"`
	Attribute    string    `json:"attribute"`
	CardText     string    `json:"card_text"`
	CreatedAt    time.Time `json:"created_at"`
}

// Image tracks where images are stored in MinIO
type Image struct {
	ID             int       `json:"id"`
	URLHash        string    `json:"url_hash"`         // MD5 hash of original URL
	OriginalURL    string    `json:"original_url"`
	MinioObjectKey string    `json:"minio_object_key"` // e.g., "thumbnail/abc123.jpg"
	ImageSize      string    `json:"image_size"`       // thumbnail, medium, full, original
	FileSizeBytes  int64     `json:"file_size_bytes"`
	CreatedAt      time.Time `json:"created_at"`
	LastAccessed   time.Time `json:"last_accessed"`
}
