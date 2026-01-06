package database

import (
	"database/sql"
	"fmt"
	"os"
	"path/filepath"

	_ "modernc.org/sqlite"
)

type DB struct {
	*sql.DB
}

// NewDB creates a new database connection
func NewDB(dbPath string) (*DB, error) {
	// Ensure directory exists
	dir := filepath.Dir(dbPath)
	if err := os.MkdirAll(dir, 0755); err != nil {
		return nil, fmt.Errorf("failed to create database directory: %w", err)
	}

	// Open database with SQLite-specific options
	db, err := sql.Open("sqlite", dbPath+"?_foreign_keys=on&_journal_mode=WAL&cache=shared")
	if err != nil {
		return nil, fmt.Errorf("failed to open database: %w", err)
	}

	// Configure connection pool
	db.SetMaxOpenConns(25)
	db.SetMaxIdleConns(5)

	// Test connection
	if err := db.Ping(); err != nil {
		return nil, fmt.Errorf("failed to ping database: %w", err)
	}

	return &DB{db}, nil
}

// Initialize creates all tables and indexes
func (db *DB) Initialize() error {
	schema := `
	-- Sets table
	CREATE TABLE IF NOT EXISTS sets (
		set_id TEXT PRIMARY KEY,
		set_name TEXT NOT NULL,
		card_count INTEGER DEFAULT 0,
		last_synced TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
	);

	-- Cards table
	CREATE TABLE IF NOT EXISTS cards (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		card_set_id TEXT UNIQUE NOT NULL,
		card_name TEXT NOT NULL,
		set_id TEXT NOT NULL,
		set_name TEXT NOT NULL,
		card_image_url TEXT,
		card_color TEXT,
		card_type TEXT,
		card_cost INTEGER,
		card_power INTEGER,
		rarity TEXT,
		attribute TEXT,
		card_text TEXT,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		FOREIGN KEY (set_id) REFERENCES sets(set_id) ON DELETE CASCADE
	);

	-- Images table
	CREATE TABLE IF NOT EXISTS images (
		id INTEGER PRIMARY KEY AUTOINCREMENT,
		url_hash TEXT NOT NULL,
		original_url TEXT NOT NULL,
		minio_object_key TEXT NOT NULL,
		image_size TEXT NOT NULL,
		file_size_bytes INTEGER,
		created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		last_accessed TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
		UNIQUE(url_hash, image_size)
	);

	-- Performance indexes
	CREATE INDEX IF NOT EXISTS idx_cards_set_id ON cards(set_id);
	CREATE INDEX IF NOT EXISTS idx_cards_color ON cards(card_color);
	CREATE INDEX IF NOT EXISTS idx_cards_type ON cards(card_type);
	CREATE INDEX IF NOT EXISTS idx_cards_rarity ON cards(rarity);
	CREATE INDEX IF NOT EXISTS idx_images_hash_size ON images(url_hash, image_size);
	CREATE INDEX IF NOT EXISTS idx_sets_last_synced ON sets(last_synced);
	`

	_, err := db.Exec(schema)
	if err != nil {
		return fmt.Errorf("failed to initialize schema: %w", err)
	}

	// Set SQLite pragmas for performance
	pragmas := []string{
		"PRAGMA journal_mode=WAL",
		"PRAGMA synchronous=NORMAL",
		"PRAGMA cache_size=10000",
		"PRAGMA temp_store=MEMORY",
	}

	for _, pragma := range pragmas {
		if _, err := db.Exec(pragma); err != nil {
			return fmt.Errorf("failed to set pragma %s: %w", pragma, err)
		}
	}

	return nil
}
