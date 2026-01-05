// API configuration
const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8080';

export type ImageSize = 'thumbnail' | 'medium' | 'full' | 'original';

/**
 * Get optimized image URL from backend
 */
export function getImageUrl(originalUrl: string, size: ImageSize = 'medium'): string {
	if (!originalUrl) return '';

	// Encode the URL to pass as query parameter
	const encodedUrl = encodeURIComponent(originalUrl);
	return `${API_URL}/api/images/${size}?url=${encodedUrl}`;
}

/**
 * Get responsive image URL based on viewport width
 */
export function getResponsiveImageUrl(originalUrl: string): string {
	if (!originalUrl) return '';

	const width = typeof window !== 'undefined' ? window.innerWidth : 1920;

	// Choose size based on viewport
	let size: ImageSize;
	if (width < 768) {
		size = 'thumbnail'; // Mobile
	} else if (width < 1440) {
		size = 'medium'; // Tablet/small desktop
	} else {
		size = 'full'; // Large desktop
	}

	return getImageUrl(originalUrl, size);
}

/**
 * Preload an image for better UX
 */
export function preloadImage(url: string): Promise<void> {
	return new Promise((resolve, reject) => {
		const img = new Image();
		img.onload = () => resolve();
		img.onerror = reject;
		img.src = url;
	});
}

/**
 * Check backend health
 */
export async function checkHealth(): Promise<boolean> {
	try {
		const response = await fetch(`${API_URL}/api/health`);
		return response.ok;
	} catch {
		return false;
	}
}

/**
 * Get cache statistics from backend
 */
export async function getCacheStats(): Promise<any> {
	const response = await fetch(`${API_URL}/api/cache/stats`);
	if (!response.ok) throw new Error('Failed to fetch cache stats');
	return response.json();
}
