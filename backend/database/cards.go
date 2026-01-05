package database

// UpsertCard inserts or updates a card
func (db *DB) UpsertCard(card *Card) error {
	query := `
		INSERT INTO cards (
			card_set_id, card_name, set_id, set_name, card_image_url,
			card_color, card_type, card_cost, card_power, rarity, attribute, card_text
		) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
		ON CONFLICT(card_set_id) DO UPDATE SET
			card_name = excluded.card_name,
			set_name = excluded.set_name,
			card_image_url = excluded.card_image_url,
			card_color = excluded.card_color,
			card_type = excluded.card_type,
			card_cost = excluded.card_cost,
			card_power = excluded.card_power,
			rarity = excluded.rarity,
			attribute = excluded.attribute,
			card_text = excluded.card_text
	`
	_, err := db.Exec(query,
		card.CardSetID, card.CardName, card.SetID, card.SetName, card.CardImageURL,
		card.CardColor, card.CardType, card.CardCost, card.CardPower,
		card.Rarity, card.Attribute, card.CardText,
	)
	return err
}

// GetCardsBySet retrieves all cards for a specific set
func (db *DB) GetCardsBySet(setID string) ([]Card, error) {
	query := `
		SELECT id, card_set_id, card_name, set_id, set_name, card_image_url,
		       card_color, card_type, card_cost, card_power, rarity, attribute, card_text, created_at
		FROM cards
		WHERE set_id = ?
		ORDER BY card_set_id
	`
	rows, err := db.Query(query, setID)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var cards []Card
	for rows.Next() {
		var card Card
		if err := rows.Scan(
			&card.ID, &card.CardSetID, &card.CardName, &card.SetID, &card.SetName,
			&card.CardImageURL, &card.CardColor, &card.CardType, &card.CardCost,
			&card.CardPower, &card.Rarity, &card.Attribute, &card.CardText, &card.CreatedAt,
		); err != nil {
			return nil, err
		}
		cards = append(cards, card)
	}
	return cards, rows.Err()
}

// SearchCards searches for cards with filters
func (db *DB) SearchCards(color, cardType, rarity string, limit, offset int) ([]Card, error) {
	query := `
		SELECT id, card_set_id, card_name, set_id, set_name, card_image_url,
		       card_color, card_type, card_cost, card_power, rarity, attribute, card_text, created_at
		FROM cards
		WHERE 1=1
	`
	args := []interface{}{}

	if color != "" {
		query += " AND card_color LIKE ?"
		args = append(args, "%"+color+"%")
	}
	if cardType != "" {
		query += " AND card_type LIKE ?"
		args = append(args, "%"+cardType+"%")
	}
	if rarity != "" {
		query += " AND rarity = ?"
		args = append(args, rarity)
	}

	query += " ORDER BY card_set_id LIMIT ? OFFSET ?"
	args = append(args, limit, offset)

	rows, err := db.Query(query, args...)
	if err != nil {
		return nil, err
	}
	defer rows.Close()

	var cards []Card
	for rows.Next() {
		var card Card
		if err := rows.Scan(
			&card.ID, &card.CardSetID, &card.CardName, &card.SetID, &card.SetName,
			&card.CardImageURL, &card.CardColor, &card.CardType, &card.CardCost,
			&card.CardPower, &card.Rarity, &card.Attribute, &card.CardText, &card.CreatedAt,
		); err != nil {
			return nil, err
		}
		cards = append(cards, card)
	}
	return cards, rows.Err()
}

// CountCardsBySet counts cards in a set
func (db *DB) CountCardsBySet(setID string) (int, error) {
	var count int
	query := `SELECT COUNT(*) FROM cards WHERE set_id = ?`
	err := db.QueryRow(query, setID).Scan(&count)
	return count, err
}
