import { describe, test, expect } from 'vitest';
import {
	generateSeparatorPairs,
	chunkSeparators,
	applyFlipTransformation,
	generatePrintPages,
	createBlankCard,
	type CardDetails
} from './separatorLogic';

// Helper to create test cards
function createCard(id: string, name: string): CardDetails {
	return {
		id,
		cardSetId: id,
		name,
		cost: '1',
		power: '1000',
		image: `https://example.com/${id}.jpg`
	};
}

describe('Separator Pairing Logic', () => {
	describe('generateSeparatorPairs', () => {
		test('should return empty array for no cards', () => {
			const result = generateSeparatorPairs([]);
			expect(result).toEqual([]);
		});

		test('should generate 2 separators for 1 card', () => {
			const cards = [createCard('OP01-001', 'Card 1')];
			const separators = generateSeparatorPairs(cards);

			expect(separators).toHaveLength(2);

			// Separator 1: Front=Card1, Back=blank
			expect(separators[0].position).toBe(0);
			expect(separators[0].front).toEqual(cards[0]);
			expect(separators[0].back.name).toBe('Collection Boundary');

			// Separator 2: Front=blank, Back=Card1
			expect(separators[1].position).toBe(1);
			expect(separators[1].front.name).toBe('Collection Boundary');
			expect(separators[1].back).toEqual(cards[0]);
		});

		test('should generate 3 separators for 2 cards', () => {
			const cards = [createCard('OP01-001', 'Card 1'), createCard('OP01-002', 'Card 2')];
			const separators = generateSeparatorPairs(cards);

			expect(separators).toHaveLength(3);

			// Separator 1: Front=Card1, Back=blank
			expect(separators[0].position).toBe(0);
			expect(separators[0].front).toEqual(cards[0]);
			expect(separators[0].back.name).toBe('Collection Boundary');

			// Separator 2: Front=Card2, Back=Card1
			expect(separators[1].position).toBe(1);
			expect(separators[1].front).toEqual(cards[1]);
			expect(separators[1].back).toEqual(cards[0]);

			// Separator 3: Front=blank, Back=Card2
			expect(separators[2].position).toBe(2);
			expect(separators[2].front.name).toBe('Collection Boundary');
			expect(separators[2].back).toEqual(cards[1]);
		});

		test('should generate N+1 separators for N cards', () => {
			const cards = Array.from({ length: 10 }, (_, i) =>
				createCard(`OP01-${String(i + 1).padStart(3, '0')}`, `Card ${i + 1}`)
			);
			const separators = generateSeparatorPairs(cards);

			expect(separators).toHaveLength(11); // 10 cards + 1 = 11 separators
		});

		test('should have correct pairing for 5 cards (|1 1|2 2|3 3|4 4|5)', () => {
			const cards = Array.from({ length: 5 }, (_, i) =>
				createCard(`OP01-${String(i + 1).padStart(3, '0')}`, `Card ${i + 1}`)
			);
			const separators = generateSeparatorPairs(cards);

			expect(separators).toHaveLength(6);

			// |1 - Separator before partition 1
			expect(separators[0].front.name).toBe('Card 1');
			expect(separators[0].back.name).toBe('Collection Boundary'); // white backing

			// 1|2 - Separator between partition 1 and 2
			expect(separators[1].front.name).toBe('Card 2');
			expect(separators[1].back.name).toBe('Card 1');

			// 2|3 - Separator between partition 2 and 3
			expect(separators[2].front.name).toBe('Card 3');
			expect(separators[2].back.name).toBe('Card 2');

			// 3|4 - Separator between partition 3 and 4
			expect(separators[3].front.name).toBe('Card 4');
			expect(separators[3].back.name).toBe('Card 3');

			// 4|5 - Separator between partition 4 and 5
			expect(separators[4].front.name).toBe('Card 5');
			expect(separators[4].back.name).toBe('Card 4');

			// 5| - Separator after partition 5
			expect(separators[5].front.name).toBe('Collection Boundary'); // white front
			expect(separators[5].back.name).toBe('Card 5');
		});

		test('should maintain card references correctly', () => {
			const card1 = createCard('OP01-001', 'Card 1');
			const card2 = createCard('OP01-002', 'Card 2');
			const cards = [card1, card2];
			const separators = generateSeparatorPairs(cards);

			// Check that references are preserved
			expect(separators[0].front).toBe(card1);
			expect(separators[1].front).toBe(card2);
			expect(separators[1].back).toBe(card1);
			expect(separators[2].back).toBe(card2);
		});
	});

	describe('chunkSeparators', () => {
		test('should chunk separators correctly', () => {
			const cards = Array.from({ length: 10 }, (_, i) =>
				createCard(`OP01-${String(i + 1).padStart(3, '0')}`, `Card ${i + 1}`)
			);
			const separators = generateSeparatorPairs(cards); // 11 separators
			const chunks = chunkSeparators(separators, 4); // 4 per page

			expect(chunks).toHaveLength(3); // 11 / 4 = 3 pages (4, 4, 3)
			expect(chunks[0]).toHaveLength(4);
			expect(chunks[1]).toHaveLength(4);
			expect(chunks[2]).toHaveLength(3);
		});

		test('should handle exact division', () => {
			const cards = Array.from({ length: 8 }, (_, i) =>
				createCard(`OP01-${String(i + 1).padStart(3, '0')}`, `Card ${i + 1}`)
			);
			const separators = generateSeparatorPairs(cards); // 9 separators
			const chunks = chunkSeparators(separators, 3); // 3 per page

			expect(chunks).toHaveLength(3); // 9 / 3 = 3 pages
			expect(chunks[0]).toHaveLength(3);
			expect(chunks[1]).toHaveLength(3);
			expect(chunks[2]).toHaveLength(3);
		});
	});

	describe('applyFlipTransformation', () => {
		test('should flip long edge correctly (book flip)', () => {
			// 2x2 grid: [A B]
			//           [C D]
			const cards = [
				createCard('A', 'A'),
				createCard('B', 'B'),
				createCard('C', 'C'),
				createCard('D', 'D')
			];
			const flipped = applyFlipTransformation(cards, 'long', 2);

			// After long edge flip (horizontal mirror each row):
			// [B A]
			// [D C]
			expect(flipped[0].name).toBe('B');
			expect(flipped[1].name).toBe('A');
			expect(flipped[2].name).toBe('D');
			expect(flipped[3].name).toBe('C');
		});

		test('should flip short edge correctly (calendar flip)', () => {
			// 2x2 grid: [A B]
			//           [C D]
			const cards = [
				createCard('A', 'A'),
				createCard('B', 'B'),
				createCard('C', 'C'),
				createCard('D', 'D')
			];
			const flipped = applyFlipTransformation(cards, 'short', 2);

			// After short edge flip (reverse entire page):
			// [D C]
			// [B A]
			expect(flipped[0].name).toBe('D');
			expect(flipped[1].name).toBe('C');
			expect(flipped[2].name).toBe('B');
			expect(flipped[3].name).toBe('A');
		});

		test('should handle blank cards in flip', () => {
			const cards = [createCard('A', 'A'), createBlankCard(), createCard('C', 'C'), createBlankCard()];
			const flipped = applyFlipTransformation(cards, 'long', 2);

			expect(flipped[0].name).toBe('Collection Boundary');
			expect(flipped[1].name).toBe('A');
			expect(flipped[2].name).toBe('Collection Boundary');
			expect(flipped[3].name).toBe('C');
		});

		test('should handle 3x2 grid long edge flip', () => {
			// 3x2 grid (3 per row, 2 rows): [A B C]
			//                               [D E F]
			const cards = [
				createCard('A', 'A'),
				createCard('B', 'B'),
				createCard('C', 'C'),
				createCard('D', 'D'),
				createCard('E', 'E'),
				createCard('F', 'F')
			];
			const flipped = applyFlipTransformation(cards, 'long', 3);

			// After long edge flip:
			// [C B A]
			// [F E D]
			expect(flipped.map((c) => c.name)).toEqual(['C', 'B', 'A', 'F', 'E', 'D']);
		});

		test('should handle incomplete last row', () => {
			// 3x2 grid with incomplete row: [A B C]
			//                               [D E]
			const cards = [
				createCard('A', 'A'),
				createCard('B', 'B'),
				createCard('C', 'C'),
				createCard('D', 'D'),
				createCard('E', 'E')
			];
			const flipped = applyFlipTransformation(cards, 'long', 3);

			// After long edge flip:
			// [C B A]
			// [E D]
			expect(flipped.map((c) => c.name)).toEqual(['C', 'B', 'A', 'E', 'D']);
		});
	});

	describe('generatePrintPages', () => {
		test('should generate correct pages for single-sided printing', () => {
			const cards = [createCard('OP01-001', 'Card 1'), createCard('OP01-002', 'Card 2')];
			const separators = generateSeparatorPairs(cards); // 3 separators
			const pages = generatePrintPages(separators, 2, 'long', 2, false);

			// Should have 2 front pages only (3 separators / 2 per page = 2 pages)
			expect(pages).toHaveLength(2);
			expect(pages[0].type).toBe('front');
			expect(pages[1].type).toBe('front');
		});

		test('should generate correct pages for double-sided printing', () => {
			const cards = [createCard('OP01-001', 'Card 1'), createCard('OP01-002', 'Card 2')];
			const separators = generateSeparatorPairs(cards); // 3 separators
			const pages = generatePrintPages(separators, 2, 'long', 2, true);

			// Should have 4 pages (front, back, front, back)
			expect(pages).toHaveLength(4);
			expect(pages[0].type).toBe('front');
			expect(pages[1].type).toBe('back');
			expect(pages[2].type).toBe('front');
			expect(pages[3].type).toBe('back');
		});

		test('should have correct front faces', () => {
			const cards = [createCard('OP01-001', 'Card 1'), createCard('OP01-002', 'Card 2')];
			const separators = generateSeparatorPairs(cards);
			const pages = generatePrintPages(separators, 3, 'long', 3, true);

			// First page front should show: Card 1, Card 2, blank
			const frontPage = pages[0];
			expect(frontPage.cards[0].name).toBe('Card 1');
			expect(frontPage.cards[1].name).toBe('Card 2');
			expect(frontPage.cards[2].name).toBe('Collection Boundary'); // blank
		});

		test('should have correct back faces before flipping', () => {
			const cards = [createCard('OP01-001', 'Card 1'), createCard('OP01-002', 'Card 2')];
			const separators = generateSeparatorPairs(cards);
			// Use short edge to avoid row-based flipping complexity
			const pages = generatePrintPages(separators, 3, 'short', 3, true);

			// Back faces before flip: blank, Card 1, Card 2
			// After short edge flip: Card 2, Card 1, blank
			const backPage = pages[1];
			expect(backPage.cards[0].name).toBe('Card 2');
			expect(backPage.cards[1].name).toBe('Card 1');
			expect(backPage.cards[2].name).toBe('Collection Boundary'); // blank
		});

		test('should apply long edge flip correctly to back pages', () => {
			const cards = Array.from({ length: 6 }, (_, i) =>
				createCard(`OP01-${String(i + 1).padStart(3, '0')}`, `Card ${i + 1}`)
			);
			const separators = generateSeparatorPairs(cards); // 7 separators
			// 2x3 grid (2 per row)
			const pages = generatePrintPages(separators, 6, 'long', 2, true);

			const frontPage = pages[0];
			const backPage = pages[1];

			// Front page (2 per row):
			// [C1 C2]
			// [C3 C4]
			// [C5 C6]
			expect(frontPage.cards.map((c) => c.name)).toEqual([
				'Card 1',
				'Card 2',
				'Card 3',
				'Card 4',
				'Card 5',
				'Card 6'
			]);

			// Back page before flip (2 per row):
			// [blank C1]
			// [C2    C3]
			// [C4    C5]
			// After long edge flip (horizontal mirror each row):
			// [C1 blank]
			// [C3 C2]
			// [C5 C4]
			expect(backPage.cards.map((c) => c.name)).toEqual([
				'Card 1',
				'Collection Boundary',
				'Card 3',
				'Card 2',
				'Card 5',
				'Card 4'
			]);
		});

		test('should handle multiple pages correctly', () => {
			const cards = Array.from({ length: 10 }, (_, i) =>
				createCard(`OP01-${String(i + 1).padStart(3, '0')}`, `Card ${i + 1}`)
			);
			const separators = generateSeparatorPairs(cards); // 11 separators
			const pages = generatePrintPages(separators, 4, 'long', 2, true);

			// 11 separators / 4 per page = 3 pages (4, 4, 3)
			// Double-sided = 6 pages total (F, B, F, B, F, B)
			expect(pages).toHaveLength(6);

			// Check alternating pattern
			expect(pages[0].type).toBe('front');
			expect(pages[1].type).toBe('back');
			expect(pages[2].type).toBe('front');
			expect(pages[3].type).toBe('back');
			expect(pages[4].type).toBe('front');
			expect(pages[5].type).toBe('back');

			// Check first page has 4 cards
			expect(pages[0].cards).toHaveLength(4);
			expect(pages[1].cards).toHaveLength(4);

			// Check last page has 3 cards
			expect(pages[4].cards).toHaveLength(3);
			expect(pages[5].cards).toHaveLength(3);
		});
	});

	describe('Integration: Complete workflow', () => {
		test('should generate correct print layout for 5 cards', () => {
			// Create 5 cards (|1 1|2 2|3 3|4 4|5)
			const cards = Array.from({ length: 5 }, (_, i) =>
				createCard(`OP01-${String(i + 1).padStart(3, '0')}`, `Card ${i + 1}`)
			);

			// Generate 6 separators
			const separators = generateSeparatorPairs(cards);
			expect(separators).toHaveLength(6);

			// Generate pages (all on one page, 3x2 grid)
			const pages = generatePrintPages(separators, 6, 'long', 3, true);

			// Should have 2 pages (1 front, 1 back)
			expect(pages).toHaveLength(2);

			// Front page layout (3 per row):
			// [C1 C2 C3]
			// [C4 C5 blank]
			const frontCards = pages[0].cards.map((c) => c.name);
			expect(frontCards).toEqual([
				'Card 1',
				'Card 2',
				'Card 3',
				'Card 4',
				'Card 5',
				'Collection Boundary'
			]);

			// Back page before flip (3 per row):
			// [blank C1 C2]
			// [C3    C4 C5]
			// After long edge flip:
			// [C2 C1 blank]
			// [C5 C4 C3]
			const backCards = pages[1].cards.map((c) => c.name);
			expect(backCards).toEqual([
				'Card 2',
				'Card 1',
				'Collection Boundary',
				'Card 5',
				'Card 4',
				'Card 3'
			]);
		});

		test('should verify physical separator pairing after cutting', () => {
			const cards = Array.from({ length: 5 }, (_, i) =>
				createCard(`OP01-${String(i + 1).padStart(3, '0')}`, `Card ${i + 1}`)
			);
			const separators = generateSeparatorPairs(cards);

			// When you cut out the separators, each position should have:
			// Position 0: Front=C1, Back=blank
			expect(separators[0].front.name).toBe('Card 1');
			expect(separators[0].back.name).toBe('Collection Boundary');

			// Position 1: Front=C2, Back=C1 (separator between partition 1 and 2)
			expect(separators[1].front.name).toBe('Card 2');
			expect(separators[1].back.name).toBe('Card 1');

			// Position 2: Front=C3, Back=C2 (separator between partition 2 and 3)
			expect(separators[2].front.name).toBe('Card 3');
			expect(separators[2].back.name).toBe('Card 2');

			// Position 5: Front=blank, Back=C5
			expect(separators[5].front.name).toBe('Collection Boundary');
			expect(separators[5].back.name).toBe('Card 5');
		});
	});
});
