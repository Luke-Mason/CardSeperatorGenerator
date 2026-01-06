<script lang="ts">
	import type { Card as CardType } from './types';

	interface Props {
		card?: CardType;
		tabConfig: {
			fontSize: number;
			fontFamily: string;
			offsetX: number;
			offsetY: number;
			content: string;
			textColor: string;
			strokeWidth: number;
			strokeColor: string;
		};
		visualConfig: {
			borderColor: string;
			borderWidth: number;
			imageCenterSize: number;
			imageFilter: string;
		};
		cardDimensions: {
			width: number;
			height: number;
			tabHeight: number;
		};
		showCutLines: boolean;
		primaryColor: string;
		secondaryColor: string;
	}

	let {
		card = $bindable(),
		tabConfig = $bindable(),
		visualConfig = $bindable(),
		cardDimensions = $bindable(),
		showCutLines = $bindable(),
		primaryColor = $bindable(),
		secondaryColor = $bindable()
	}: Props = $props();

	// Parse template string and replace placeholders
	function parseTemplate(template: string, cardData?: CardType): string {
		if (!cardData) return template;

		return template
			.replace(/{name}/g, cardData.name || '')
			.replace(/{id}/g, cardData.id || '')
			.replace(/{cost}/g, cardData.cost?.toString() || '')
			.replace(/{setId}/g, cardData.setId || '')
			.replace(/{type}/g, cardData.type || '')
			.replace(/{rarity}/g, cardData.rarity || '');
	}

	// Get parsed tab content
	let tabContent = $derived(parseTemplate(tabConfig.content, card));

	// Tab element reference for dynamic sizing
	let tabTextElement: HTMLSpanElement | undefined = $state();

	// Dynamic font size calculation
	$effect(() => {
		if (tabTextElement && card) {
			const availableWidth = tabTextElement.parentElement?.offsetWidth || 0;
			const textWidth = tabTextElement.scrollWidth;

			if (textWidth > availableWidth && availableWidth > 0) {
				const scale = availableWidth / textWidth;
				const newSize = Math.max(6, Math.floor(tabConfig.fontSize * scale));
				tabTextElement.style.fontSize = `${newSize}px`;
			} else {
				tabTextElement.style.fontSize = `${tabConfig.fontSize}px`;
			}
		}
	});

	// Get image URL with sizing
	function getImageUrl(card?: CardType): string {
		if (!card?.images?.medium) return '';
		return card.images.medium;
	}

	// Get filter CSS
	const filterStyle = $derived(() => {
		switch (visualConfig.imageFilter) {
			case 'grayscale':
				return 'grayscale(100%)';
			case 'sepia':
				return 'sepia(100%)';
			case 'vintage':
				return 'sepia(50%) contrast(0.9) brightness(1.1)';
			case 'blur':
				return 'blur(2px)';
			case 'contrast':
				return 'contrast(1.3) saturate(1.2)';
			default:
				return 'none';
		}
	});
</script>

<div class="card-editor-container">
	{#if card}
		<div
			class="card-preview"
			style:width="{cardDimensions.width}mm"
			style:height="{cardDimensions.height}mm"
			style:border="{showCutLines ? '1px dashed #999' : visualConfig.borderWidth + 'px solid ' + visualConfig.borderColor}"
		>
			<!-- Tab Section -->
			<div
				class="tab-section"
				style:height="{cardDimensions.tabHeight}mm"
				style:background={secondaryColor}
				style:transform="translate({tabConfig.offsetX}px, {tabConfig.offsetY}px)"
			>
				<div class="tab-content">
					<span
						bind:this={tabTextElement}
						class="tab-text"
						style:color={tabConfig.textColor}
						style:font-family={tabConfig.fontFamily}
						style:-webkit-text-stroke="{tabConfig.strokeWidth}px {tabConfig.strokeColor}"
					>
						{tabContent}
					</span>
				</div>
			</div>

			<!-- Card Image -->
			<div
				class="card-image-container"
				style:top="{cardDimensions.tabHeight}mm"
				style:height="calc({cardDimensions.height}mm - {cardDimensions.tabHeight}mm)"
			>
				<div
					class="card-image"
					style:width="{visualConfig.imageCenterSize}%"
					style:height="{visualConfig.imageCenterSize}%"
					style:filter={filterStyle}
				>
					<img src={getImageUrl(card)} alt={card.name} />
				</div>
			</div>
		</div>

		<!-- Card Info -->
		<div class="card-info">
			<h3>{card.name}</h3>
			<p class="card-meta">
				<span class="badge">{card.setId}</span>
				<span class="badge">{card.id}</span>
				{#if card.rarity}
					<span class="badge rarity">{card.rarity}</span>
				{/if}
			</p>
		</div>
	{:else}
		<div class="no-card-placeholder">
			<div
				class="placeholder-card"
				style:width="{cardDimensions.width}mm"
				style:height="{cardDimensions.height}mm"
				style:border="{showCutLines ? '1px dashed #999' : visualConfig.borderWidth + 'px dashed ' + visualConfig.borderColor}"
			>
				<div class="placeholder-content">
					<svg
						xmlns="http://www.w3.org/2000/svg"
						fill="none"
						viewBox="0 0 24 24"
						stroke-width="1.5"
						stroke="currentColor"
						class="placeholder-icon"
					>
						<path
							stroke-linecap="round"
							stroke-linejoin="round"
							d="M2.25 15.75l5.159-5.159a2.25 2.25 0 013.182 0l5.159 5.159m-1.5-1.5l1.409-1.409a2.25 2.25 0 013.182 0l2.909 2.909m-18 3.75h16.5a1.5 1.5 0 001.5-1.5V6a1.5 1.5 0 00-1.5-1.5H3.75A1.5 1.5 0 002.25 6v12a1.5 1.5 0 001.5 1.5zm10.5-11.25h.008v.008h-.008V8.25zm.375 0a.375.375 0 11-.75 0 .375.375 0 01.75 0z"
						/>
					</svg>
					<p class="placeholder-text">Load cards to see preview</p>
					<p class="placeholder-hint">Enter a set ID and click Load Cards</p>
				</div>
			</div>
		</div>
	{/if}
</div>

<style>
	.card-editor-container {
		display: flex;
		flex-direction: column;
		align-items: center;
		justify-content: center;
		gap: 2rem;
		padding: 2rem;
		min-height: 100%;
	}

	.card-preview {
		position: relative;
		background: white;
		box-shadow:
			0 4px 6px -1px rgb(0 0 0 / 0.1),
			0 2px 4px -2px rgb(0 0 0 / 0.1);
		border-radius: 4px;
		overflow: hidden;
	}

	/* Tab Section */
	.tab-section {
		position: absolute;
		top: 0;
		left: 0;
		right: 0;
		z-index: 2;
	}

	.tab-content {
		display: flex;
		align-items: center;
		justify-content: center;
		height: 100%;
		padding: 0 1rem;
	}

	.tab-text {
		font-weight: bold;
		text-align: center;
		white-space: nowrap;
		overflow: hidden;
		text-overflow: ellipsis;
		paint-order: stroke fill;
	}

	/* Card Image */
	.card-image-container {
		position: absolute;
		left: 0;
		right: 0;
		display: flex;
		align-items: center;
		justify-content: center;
		background: #f3f4f6;
		overflow: hidden;
	}

	.card-image {
		display: flex;
		align-items: center;
		justify-content: center;
		transition: all 0.3s ease;
	}

	.card-image img {
		width: 100%;
		height: 100%;
		object-fit: contain;
	}

	/* Card Info */
	.card-info {
		text-align: center;
		max-width: 400px;
	}

	.card-info h3 {
		font-size: 1.5rem;
		font-weight: 600;
		margin: 0 0 0.5rem 0;
		color: #111827;
	}

	.card-meta {
		display: flex;
		gap: 0.5rem;
		justify-content: center;
		align-items: center;
		flex-wrap: wrap;
		margin: 0;
	}

	.badge {
		display: inline-block;
		padding: 0.25rem 0.75rem;
		background: #e5e7eb;
		color: #374151;
		font-size: 0.875rem;
		font-weight: 500;
		border-radius: 9999px;
	}

	.badge.rarity {
		background: #fef3c7;
		color: #92400e;
	}

	/* Placeholder */
	.no-card-placeholder {
		display: flex;
		align-items: center;
		justify-content: center;
		width: 100%;
		height: 100%;
	}

	.placeholder-card {
		background: #f9fafb;
		border-radius: 4px;
		display: flex;
		align-items: center;
		justify-content: center;
	}

	.placeholder-content {
		display: flex;
		flex-direction: column;
		align-items: center;
		gap: 1rem;
		padding: 2rem;
		text-align: center;
	}

	.placeholder-icon {
		width: 4rem;
		height: 4rem;
		color: #9ca3af;
	}

	.placeholder-text {
		margin: 0;
		font-size: 1.125rem;
		font-weight: 500;
		color: #6b7280;
	}

	.placeholder-hint {
		margin: 0;
		font-size: 0.875rem;
		color: #9ca3af;
	}
</style>
