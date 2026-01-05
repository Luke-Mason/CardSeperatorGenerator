package database

import (
	"database/sql"
	"time"
)

// TrackImage inserts or updates an image record
func (db *DB) TrackImage(urlHash, originalURL, minioObjectKey, imageSize string, fileSizeBytes int64) error {
	query := `
		INSERT INTO images (url_hash, original_url, minio_object_key, image_size, file_size_bytes, last_accessed)
		VALUES (?, ?, ?, ?, ?, ?)
		ON CONFLICT(url_hash, image_size) DO UPDATE SET
			last_accessed = excluded.last_accessed
	`
	_, err := db.Exec(query, urlHash, originalURL, minioObjectKey, imageSize, fileSizeBytes, time.Now())
	return err
}

// GetImage retrieves an image record
func (db *DB) GetImage(urlHash, imageSize string) (*Image, error) {
	query := `
		SELECT id, url_hash, original_url, minio_object_key, image_size, file_size_bytes, created_at, last_accessed
		FROM images
		WHERE url_hash = ? AND image_size = ?
	`
	var img Image
	err := db.QueryRow(query, urlHash, imageSize).Scan(
		&img.ID, &img.URLHash, &img.OriginalURL, &img.MinioObjectKey,
		&img.ImageSize, &img.FileSizeBytes, &img.CreatedAt, &img.LastAccessed,
	)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &img, nil
}

// UpdateImageAccess updates the last_accessed timestamp
func (db *DB) UpdateImageAccess(urlHash, imageSize string) error {
	query := `UPDATE images SET last_accessed = ? WHERE url_hash = ? AND image_size = ?`
	_, err := db.Exec(query, time.Now(), urlHash, imageSize)
	return err
}

// GetCacheStats returns cache statistics
func (db *DB) GetCacheStats() (map[string]interface{}, error) {
	stats := make(map[string]interface{})

	// Count images by size
	query := `
		SELECT image_size, COUNT(*) as count, SUM(file_size_bytes) as total_size
		FROM images
		GROUP BY image_size
	`
	rows, err := db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	imageCounts := make(map[string]int)
	imageSizes := make(map[string]int64)
	for rows.Next() {
		var size string
		var count int
		var totalSize int64
		if err := rows.Scan(&size, &count, &totalSize); err != nil {
			return nil, err
		}
		imageCounts[size] = count
		imageSizes[size] = totalSize
	}

	stats["image_counts"] = imageCounts
	stats["image_sizes_bytes"] = imageSizes

	// Total images
	var totalImages int
	if err := db.QueryRow("SELECT COUNT(*) FROM images").Scan(&totalImages); err != nil {
		return nil, err
	}
	stats["total_images"] = totalImages

	// Total cards
	var totalCards int
	if err := db.QueryRow("SELECT COUNT(*) FROM cards").Scan(&totalCards); err != nil {
		return nil, err
	}
	stats["total_cards"] = totalCards

	// Total sets
	var totalSets int
	if err := db.QueryRow("SELECT COUNT(*) FROM sets").Scan(&totalSets); err != nil {
		return nil, err
	}
	stats["total_sets"] = totalSets

	return stats, nil
}
