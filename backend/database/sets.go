package database

import (
	"database/sql"
	"time"
)

// UpsertSet inserts or updates a set
func (db *DB) UpsertSet(setID, setName string) error {
	query := `
		INSERT INTO sets (set_id, set_name, last_synced)
		VALUES (?, ?, ?)
		ON CONFLICT(set_id) DO UPDATE SET
			set_name = excluded.set_name,
			last_synced = excluded.last_synced
	`
	_, err := db.Exec(query, setID, setName, time.Now())
	return err
}

// GetSet retrieves a single set by ID
func (db *DB) GetSet(setID string) (*Set, error) {
	query := `SELECT set_id, set_name, card_count, last_synced, created_at FROM sets WHERE set_id = ?`
	var set Set
	err := db.QueryRow(query, setID).Scan(
		&set.SetID,
		&set.SetName,
		&set.CardCount,
		&set.LastSynced,
		&set.CreatedAt,
	)
	if err == sql.ErrNoRows {
		return nil, nil
	}
	if err != nil {
		return nil, err
	}
	return &set, nil
}

// GetAllSets retrieves all sets from the database
func (db *DB) GetAllSets() ([]Set, error) {
	query := `SELECT set_id, set_name, card_count, last_synced, created_at FROM sets ORDER BY set_id`
	rows, err := db.Query(query)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var sets []Set
	for rows.Next() {
		var set Set
		if err := rows.Scan(&set.SetID, &set.SetName, &set.CardCount, &set.LastSynced, &set.CreatedAt); err != nil {
			return nil, err
		}
		sets = append(sets, set)
	}
	return sets, rows.Err()
}

// UpdateSetCardCount updates the card count for a set
func (db *DB) UpdateSetCardCount(setID string, count int) error {
	query := `UPDATE sets SET card_count = ? WHERE set_id = ?`
	_, err := db.Exec(query, count, setID)
	return err
}
