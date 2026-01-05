package config

import (
	"os"
	"strconv"
	"time"
)

type Config struct {
	// Server
	Port string

	// Database
	DatabasePath string

	// MinIO
	MinIOEndpoint  string
	MinIOAccessKey string
	MinIOSecretKey string
	MinIOBucket    string
	MinIOUseSSL    bool
	MinIORegion    string

	// Cache
	CacheMaxAge time.Duration
	ImageSizes  map[string]int

	// Sync
	SetSyncInterval   time.Duration
	AutoSyncOnStartup bool
}

func Load() *Config {
	return &Config{
		Port:                getEnv("PORT", "8080"),
		DatabasePath:        getEnv("DATABASE_PATH", "./data/cards.db"),
		MinIOEndpoint:       getEnv("MINIO_ENDPOINT", "localhost:9000"),
		MinIOAccessKey:      getEnv("MINIO_ACCESS_KEY", "minioadmin"),
		MinIOSecretKey:      getEnv("MINIO_SECRET_KEY", "minioadmin"),
		MinIOBucket:         getEnv("MINIO_BUCKET", "card-images"),
		MinIOUseSSL:         getEnvBool("MINIO_USE_SSL", false),
		MinIORegion:         getEnv("MINIO_REGION", "us-east-1"),
		CacheMaxAge:         time.Duration(getEnvInt("CACHE_MAX_AGE_HOURS", 168)) * time.Hour, // 7 days
		SetSyncInterval:     time.Duration(getEnvInt("SET_SYNC_INTERVAL_HOURS", 24)) * time.Hour,
		AutoSyncOnStartup:   getEnvBool("AUTO_SYNC_ON_STARTUP", true),
		ImageSizes: map[string]int{
			"thumbnail": 300,
			"medium":    600,
			"full":      1200,
			"original":  0, // 0 means no resize
		},
	}
}

func getEnv(key, defaultVal string) string {
	if val := os.Getenv(key); val != "" {
		return val
	}
	return defaultVal
}

func getEnvInt(key string, defaultVal int) int {
	if val := os.Getenv(key); val != "" {
		if i, err := strconv.Atoi(val); err == nil {
			return i
		}
	}
	return defaultVal
}

func getEnvBool(key string, defaultVal bool) bool {
	if val := os.Getenv(key); val != "" {
		if b, err := strconv.ParseBool(val); err == nil {
			return b
		}
	}
	return defaultVal
}
