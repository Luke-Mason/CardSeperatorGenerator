/**
 * Separator pairing logic for double-sided printing
 *
 * Physical layout: |1 1|2 2|3 3|4 4|5
 *
 * Each partition is surrounded by separators showing its ID:
 * - Partition 1 has: |1 (with white back) and 1|2
 * - Partition 2 has: 1|2 and 2|3
 * - Partition N has: (N-1)|N and N| (with white back)
 *
 * For N cards, we need N+1 separators:
 * - Separator 1: Front=Card1, Back=blank
 * - Separator 2: Front=Card2, Back=Card1
 * - Separator 3: Front=Card3, Back=Card2
 * - ...
 * - Separator N: Front=CardN, Back=CardN-1
 * - Separator N+1: Front=blank, Back=CardN
 */

export interface CardDetails {
	id: string;
	cardSetId: string;
	name: string;
	cost?: string;
	power?: string;
	image?: string;
	color?: string;
	type?: string;
	rarity?: string;
	attribute?: string;
}

export interface PrintPage {
	type: 'front' | 'back';
	cards: CardDetails[];
}

export interface SeparatorPair {
	position: number; // 0-indexed position
	front: CardDetails; // Blank card for collection boundaries
	back: CardDetails; // Blank card for collection boundaries
}

/**
 * Generate separator pairs for N cards
 * Returns N+1 separator pairs
 */
export function generateSeparatorPairs(cards: CardDetails[]): SeparatorPair[] {
	if (cards.length === 0) return [];

	const separators: SeparatorPair[] = [];
	const blankCard = createBlankCard();

	// First separator: Front=Card1, Back=blank
	separators.push({
		position: 0,
		front: cards[0],
		back: blankCard
	});

	// Middle separators: Front=CardN, Back=CardN-1
	for (let i = 1; i < cards.length; i++) {
		separators.push({
			position: i,
			front: cards[i],
			back: cards[i - 1]
		});
	}

	// Last separator: Front=blank, Back=CardN (last card)
	separators.push({
		position: cards.length,
		front: blankCard,
		back: cards[cards.length - 1]
	});

	return separators;
}

/**
 * Create a blank card placeholder for collection boundaries
 */
export function createBlankCard(): CardDetails {
	return {
		id: '---',
		cardSetId: '---',
		name: 'Collection Boundary',
		cost: '',
		power: '',
		image: ''
	};
}

/**
 * Chunk separators into pages
 */
export function chunkSeparators(
	separators: SeparatorPair[],
	separatorsPerPage: number
): SeparatorPair[][] {
	const chunks: SeparatorPair[][] = [];
	for (let i = 0; i < separators.length; i += separatorsPerPage) {
		chunks.push(separators.slice(i, i + separatorsPerPage));
	}
	return chunks;
}

/**
 * Apply flip transformation for double-sided printing
 * @param backCards - The back face cards before flipping
 * @param flipEdge - 'long' (book flip) or 'short' (calendar flip)
 * @param cardsPerRow - Number of cards per row on the page
 * @returns The cards after flip transformation
 */
export function applyFlipTransformation(
	backCards: CardDetails[],
	flipEdge: 'long' | 'short',
	cardsPerRow: number
): CardDetails[] {
	if (flipEdge === 'long') {
		// Long edge flip: horizontal mirror each row
		const flippedCards: CardDetails[] = [];
		const totalRows = Math.ceil(backCards.length / cardsPerRow);

		for (let row = 0; row < totalRows; row++) {
			const rowStart = row * cardsPerRow;
			const rowEnd = Math.min(rowStart + cardsPerRow, backCards.length);
			const rowCards = backCards.slice(rowStart, rowEnd);
			flippedCards.push(...rowCards.reverse());
		}

		return flippedCards;
	} else {
		// Short edge flip: reverse entire page
		return [...backCards].reverse();
	}
}

/**
 * Generate print pages from separator pairs for double-sided printing
 */
export function generatePrintPages(
	separators: SeparatorPair[],
	separatorsPerPage: number,
	flipEdge: 'long' | 'short',
	cardsPerRow: number,
	doubleSided: boolean
): PrintPage[] {
	if (separators.length === 0) return [];

	const pages: PrintPage[] = [];
	const chunks = chunkSeparators(separators, separatorsPerPage);

	for (const chunk of chunks) {
		// Front page: show the front face of each separator
		const frontCards = chunk.map((sep) => sep.front);
		pages.push({ type: 'front', cards: frontCards });

		if (doubleSided) {
			// Back page: show the back face of each separator
			const backCards = chunk.map((sep) => sep.back);
			const flippedBackCards = applyFlipTransformation(backCards, flipEdge, cardsPerRow);
			pages.push({ type: 'back', cards: flippedBackCards });
		}
	}

	return pages;
}
