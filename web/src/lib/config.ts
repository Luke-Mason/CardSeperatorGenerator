// Configuration types and defaults
export type FlipEdge = 'long' | 'short';
export type ImageQuality = 'thumbnail' | 'medium' | 'full' | 'original';
export type PageSize = 'a4' | 'letter' | 'legal' | 'custom';

export interface PageDimensions {
	width: number;
	height: number;
}

export interface CardDimensions {
	width: number;
	height: number;
	tabHeight: number;
}

export interface PrintConfig {
	doubleSided: boolean;
	flipEdge: FlipEdge;
	showImages: boolean;
	imageQuality: ImageQuality;
	showCutLines: boolean;
	pageSize: PageSize;
	customPageSize?: PageDimensions;
}

export interface AppConfig extends PrintConfig {
	setId: string;
	cardDimensions: CardDimensions;
	pageDimensions: PageDimensions;
	colors: {
		primary: string;
		secondary: string;
	};
}

// Default configurations
export const DEFAULT_CARD_DIMENSIONS: CardDimensions = {
	width: 65,
	height: 95,
	tabHeight: 10,
};

export const PAGE_SIZES: Record<PageSize, PageDimensions> = {
	a4: { width: 210, height: 297 },
	letter: { width: 216, height: 279 },
	legal: { width: 216, height: 356 },
	custom: { width: 210, height: 297 },
};

export const DEFAULT_CONFIG: AppConfig = {
	setId: 'OP-01',
	doubleSided: false,
	flipEdge: 'long',
	showImages: true,
	imageQuality: 'medium',
	showCutLines: false,
	pageSize: 'a4',
	cardDimensions: DEFAULT_CARD_DIMENSIONS,
	pageDimensions: PAGE_SIZES.a4,
	colors: {
		primary: '#DC2626',
		secondary: '#B91C1C',
	},
};

// Local storage helpers
const CONFIG_KEY = 'card-separator-config';

export function saveConfig(config: Partial<AppConfig>): void {
	try {
		const existing = loadConfig();
		const merged = { ...existing, ...config };
		localStorage.setItem(CONFIG_KEY, JSON.stringify(merged));
	} catch (e) {
		console.error('Failed to save config:', e);
	}
}

export function loadConfig(): AppConfig {
	try {
		const stored = localStorage.getItem(CONFIG_KEY);
		if (stored) {
			return { ...DEFAULT_CONFIG, ...JSON.parse(stored) };
		}
	} catch (e) {
		console.error('Failed to load config:', e);
	}
	return DEFAULT_CONFIG;
}

export function resetConfig(): void {
	try {
		localStorage.removeItem(CONFIG_KEY);
	} catch (e) {
		console.error('Failed to reset config:', e);
	}
}

// Computed helpers
export function calculateCardsPerPage(
	pageDimensions: PageDimensions,
	cardDimensions: CardDimensions
): { cardsPerRow: number; rowsPerPage: number; cardsPerPage: number } {
	const cardsPerRow = Math.floor(pageDimensions.width / cardDimensions.width);
	const rowsPerPage = Math.floor(pageDimensions.height / cardDimensions.height);
	const cardsPerPage = cardsPerRow * rowsPerPage;

	return { cardsPerRow, rowsPerPage, cardsPerPage };
}
