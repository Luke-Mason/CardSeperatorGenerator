<script lang="ts">
	import Sidebar from '../lib/Sidebar.svelte';
	import CardEditor from '../lib/CardEditor.svelte';
	import { onMount } from 'svelte';
	import { getImageUrl, type ImageSize } from '../lib/api';
	import { loadConfig, saveConfig, type AppConfig } from '../lib/config';
	import type { Card } from '../lib/types';
	import { generateSeparatorPairs, generatePrintPages } from '../lib/separatorLogic';

	// Configuration
	let config = $state<AppConfig>(loadConfig());

	// Sidebar state
	let tabConfig = $state({
		fontSize: 12,
		fontFamily: 'Impact, sans-serif',
		offsetX: 0,
		offsetY: 0,
		content: '{name}',
		textColor: '#FFFFFF',
		strokeWidth: 0.6,
		strokeColor: '#000000'
	});

	let visualConfig = $state({
		borderColor: '#000000',
		borderWidth: 1,
		imageCenterSize: 80,
		imageFilter: 'none'
	});

	let showCutLines = $state(config.showCutLines);
	let doubleSided = $state(config.doubleSided);
	let flipEdge: 'long' | 'short' = $state(config.flipEdge);
	let setId = $state(config.setId);
	let imageQuality: ImageSize = $state(config.imageQuality);

	// API Card type
	type APICard = {
		card_name: string;
		card_set_id: string;
		card_cost: string;
		card_power: string;
		card_color: string;
		card_type: string;
		rarity: string;
		attribute: string;
		card_text: string;
		card_image: string;
		set_id: string;
		set_name: string;
		life: string;
		counter_amount: number;
	};

	// Internal card type for rendering
	type CardDetails = {
		width: number;
		height: number;
		setId: string;
		cardSetId: string;
		id: string;
		name: string;
		cost: string;
		image: string;
		rawData?: APICard;
	};

	let allCards: CardDetails[] = $state([]);
	let loading = $state(false);
	let error = $state('');
	let currentCardIndex = $state(0);
	let previewMode: 'single' | 'print' = $state('single');

	// Get current card for preview
	let currentCard = $derived.by((): Card | undefined => {
		if (allCards.length === 0) return undefined;
		const card = allCards[currentCardIndex];
		return {
			id: card.id,
			setId: card.setId,
			name: card.name,
			cost: parseInt(card.cost) || 0,
			type: card.rawData?.card_type || '',
			rarity: card.rawData?.rarity || '',
			images: {
				thumbnail: getImageUrl(card.image, 'thumbnail'),
				medium: getImageUrl(card.image, 'medium'),
				full: getImageUrl(card.image, 'full'),
				original: card.image
			}
		};
	});

	// Page dimensions
	let cardWidthMM = $derived(config.cardDimensions.width);
	let cardHeightMM = $derived(config.cardDimensions.height);
	let pageWidthMM = $derived(config.pageDimensions.width);
	let pageHeightMM = $derived(config.pageDimensions.height);

	// Calculate cards per page
	const cardsPerRow = $derived(Math.floor(pageWidthMM / cardWidthMM));
	const rowsPerPage = $derived(Math.floor(pageHeightMM / cardHeightMM));
	const cardsPerPage = $derived(cardsPerRow * rowsPerPage);

	// Fetch cards from API
	async function fetchCards() {
		loading = true;
		error = '';
		try {
			const response = await fetch(`https://optcgapi.com/api/sets/${setId}/`);
			if (!response.ok) throw new Error(`Failed to fetch: ${response.statusText}`);

			const data: APICard[] = await response.json();

			// Filter out duplicates (parallel cards) - keep only the first occurrence
			const uniqueCards = new Map<string, APICard>();
			data.forEach((card) => {
				if (!uniqueCards.has(card.card_set_id)) {
					uniqueCards.set(card.card_set_id, card);
				}
			});

			// Sort by card_set_id
			const sortedCards = Array.from(uniqueCards.values()).sort((a, b) =>
				a.card_set_id.localeCompare(b.card_set_id)
			);

			allCards = sortedCards.map((card) => {
				// Clean the card name - remove ID prefix if it exists
				let cleanName = card.card_name;
				const cardId = card.card_set_id.split('-')[1] || '';
				// Remove patterns like "OP01-001 " or "OP-01 " from the beginning
				cleanName = cleanName.replace(/^[A-Z]+[0-9]+-[0-9]+\s+/, '');
				cleanName = cleanName.replace(/^[A-Z]+-[0-9]+\s+/, '');

				return {
					width: cardWidthMM,
					height: cardHeightMM,
					setId: card.set_id,
					cardSetId: card.card_set_id,
					id: cardId,
					name: cleanName,
					cost: card.card_cost === 'NULL' || !card.card_cost ? '' : card.card_cost,
					image: card.card_image,
					rawData: card
				};
			});

			currentCardIndex = 0;
		} catch (e) {
			error = e instanceof Error ? e.message : 'Unknown error';
			console.error('Error fetching cards:', e);
		} finally {
			loading = false;
		}
	}

	// Navigate between cards
	function nextCard() {
		if (currentCardIndex < allCards.length - 1) {
			currentCardIndex++;
		}
	}

	function previousCard() {
		if (currentCardIndex > 0) {
			currentCardIndex--;
		}
	}

	// Print functionality - single run with proper duplex ordering
	function handlePrint() {
		// Generate all pages in correct order for duplex printing
		window.print();
	}

	// Generate pages for printing with proper duplex ordering
	// Uses the correct N+1 separator logic for N cards
	const printPages = $derived.by(() => {
		if (!allCards.length) return [];

		// Generate N+1 separators for N cards
		// Physical layout: |1 1|2 2|3 3|4 4|5
		// Separator 1: Front=Card1, Back=blank
		// Separator 2: Front=Card2, Back=Card1
		// ...
		// Separator N+1: Front=blank, Back=CardN
		const separators = generateSeparatorPairs(allCards);

		// Generate print pages with correct double-sided layout
		return generatePrintPages(separators, cardsPerPage, flipEdge, cardsPerRow, doubleSided);
	});

	// Save config when values change
	$effect(() => {
		config.showCutLines = showCutLines;
		config.doubleSided = doubleSided;
		config.flipEdge = flipEdge;
		config.setId = setId;
		config.imageQuality = imageQuality;
		saveConfig(config);
	});

	// Keyboard shortcuts
	onMount(() => {
		function handleKeyboard(e: KeyboardEvent) {
			// Ctrl+P already handled by browser
			if (e.key === 'ArrowLeft') {
				e.preventDefault();
				previousCard();
			} else if (e.key === 'ArrowRight') {
				e.preventDefault();
				nextCard();
			}
		}

		window.addEventListener('keydown', handleKeyboard);
		return () => window.removeEventListener('keydown', handleKeyboard);
	});
</script>

<svelte:head>
	<title>Card Separator Generator</title>
	<style>
		.print-preview-container {
			display: flex;
			flex-direction: column;
			align-items: center;
			padding: 2rem;
			background: #f3f4f6;
		}

		@media print {
			@page {
				margin: 0;
				size: {pageWidthMM}mm {pageHeightMM}mm;
			}
			body {
				margin: 0;
				padding: 0;
			}
		}
	</style>
</svelte:head>

<main class="flex h-screen overflow-hidden bg-gray-50">
	<!-- Sidebar -->
	<div class="print:hidden">
		<Sidebar
			bind:config
			bind:tabConfig
			bind:visualConfig
			bind:setId
			bind:showCutLines
			bind:doubleSided
			bind:flipEdge
			bind:imageQuality
			{loading}
			{error}
			{allCards}
			onLoadCards={fetchCards}
			onPrint={handlePrint}
		/>
	</div>

	<!-- Main Content Area -->
	<div class="flex-1 flex flex-col overflow-hidden print:hidden" style="transition: margin-left 0.3s ease;">
		<!-- Header -->
		<header class="bg-white border-b border-gray-200 px-6 py-4">
			<div class="flex items-center justify-between">
				<div>
					<h1 class="text-2xl font-bold text-gray-900">Card Separator Generator</h1>
					{#if allCards.length > 0}
						<p class="text-sm text-gray-600 mt-1">
							{#if previewMode === 'single'}
								Viewing card {currentCardIndex + 1} of {allCards.length}
							{:else}
								Print Preview - {printPages.length} pages
							{/if}
						</p>
					{/if}
				</div>

				{#if allCards.length > 0}
					<div class="flex items-center gap-4">
						<!-- Preview Mode Toggle -->
						<div class="flex items-center gap-2 bg-gray-100 rounded-lg p-1">
							<button
								onclick={() => (previewMode = 'single')}
								class="px-3 py-1.5 rounded text-sm font-medium transition-colors"
								class:bg-white={previewMode === 'single'}
								class:shadow={previewMode === 'single'}
								class:text-gray-900={previewMode === 'single'}
								class:text-gray-600={previewMode !== 'single'}
							>
								Single Card
							</button>
							<button
								onclick={() => (previewMode = 'print')}
								class="px-3 py-1.5 rounded text-sm font-medium transition-colors"
								class:bg-white={previewMode === 'print'}
								class:shadow={previewMode === 'print'}
								class:text-gray-900={previewMode === 'print'}
								class:text-gray-600={previewMode !== 'print'}
							>
								Print Preview
							</button>
						</div>
						<!-- Navigation -->
						<div class="flex items-center gap-2">
							<button
								onclick={previousCard}
								disabled={currentCardIndex === 0}
								class="px-3 py-2 bg-gray-200 hover:bg-gray-300 disabled:bg-gray-100 disabled:text-gray-400 rounded font-medium transition-colors"
								title="Previous card (←)"
							>
								<svg
									xmlns="http://www.w3.org/2000/svg"
									fill="none"
									viewBox="0 0 24 24"
									stroke-width="2"
									stroke="currentColor"
									class="w-5 h-5"
								>
									<path stroke-linecap="round" stroke-linejoin="round" d="M15.75 19.5L8.25 12l7.5-7.5" />
								</svg>
							</button>
							<span class="text-sm font-medium text-gray-700">
								{currentCardIndex + 1} / {allCards.length}
							</span>
							<button
								onclick={nextCard}
								disabled={currentCardIndex === allCards.length - 1}
								class="px-3 py-2 bg-gray-200 hover:bg-gray-300 disabled:bg-gray-100 disabled:text-gray-400 rounded font-medium transition-colors"
								title="Next card (→)"
							>
								<svg
									xmlns="http://www.w3.org/2000/svg"
									fill="none"
									viewBox="0 0 24 24"
									stroke-width="2"
									stroke="currentColor"
									class="w-5 h-5"
								>
									<path stroke-linecap="round" stroke-linejoin="round" d="M8.25 4.5l7.5 7.5-7.5 7.5" />
								</svg>
							</button>
						</div>
					</div>
				{/if}
			</div>
		</header>

		<!-- Card Preview Area -->
		<div class="flex-1 overflow-auto">
			{#if previewMode === 'single'}
				<CardEditor
					card={currentCard}
					{tabConfig}
					{visualConfig}
					cardDimensions={config.cardDimensions}
					{showCutLines}
					primaryColor={config.colors.primary}
					secondaryColor={config.colors.secondary}
				/>
			{:else}
				<!-- Print Preview -->
				<div class="print-preview-container p-8">
					{#each printPages as page, pageIdx}
						<div
							class="print-preview-page"
							style:width="{pageWidthMM}mm"
							style:height="{pageHeightMM}mm"
							style:margin-bottom="2rem"
							style:box-shadow="0 4px 6px -1px rgb(0 0 0 / 0.1)"
							style:background="white"
						>
							<div
								class="grid"
								style:grid-template-columns="repeat({cardsPerRow}, {cardWidthMM}mm)"
								style:grid-template-rows="repeat({rowsPerPage}, {cardHeightMM}mm)"
								style:width="100%"
								style:height="100%"
							>
								{#each page.cards as card}
									<div
										style:width="{cardWidthMM}mm"
										style:height="{cardHeightMM}mm"
										style:position="relative"
										style:border="{showCutLines ? '1px dashed #999' : visualConfig.borderWidth + 'px solid ' + visualConfig.borderColor}"
									>
										<!-- Tab section -->
										<div
											style:position="absolute"
											style:top="0"
											style:left="0"
											style:right="0"
											style:height="{config.cardDimensions.tabHeight}mm"
											style:background={config.colors.secondary}
											style:display="flex"
											style:align-items="center"
											style:justify-content="center"
											style:transform="translate({tabConfig.offsetX}px, {tabConfig.offsetY}px)"
											style:overflow="hidden"
											style:padding="0 4px"
										>
											<span
												style:color={tabConfig.textColor}
												style:font-family={tabConfig.fontFamily}
												style:font-weight="bold"
												style:-webkit-text-stroke="{tabConfig.strokeWidth}px {tabConfig.strokeColor}"
												style:paint-order="stroke fill"
												style:white-space="nowrap"
												style:font-size="clamp(6px, {tabConfig.fontSize}px, {tabConfig.fontSize}px)"
											>
												{card.name}
											</span>
										</div>

										<!-- Image -->
										{#if card.image}
											<div
												style:position="absolute"
												style:top="{config.cardDimensions.tabHeight}mm"
												style:left="0"
												style:right="0"
												style:bottom="0"
												style:display="flex"
												style:align-items="center"
												style:justify-content="center"
												style:background="#f3f4f6"
												style:overflow="hidden"
											>
												{#if card.image}
													<img
														src={getImageUrl(card.image, imageQuality)}
														alt={card.name}
														style:width="{visualConfig.imageCenterSize}%"
														style:height="{visualConfig.imageCenterSize}%"
														style:object-fit="contain"
														style:filter={visualConfig.imageFilter !== 'none'
															? visualConfig.imageFilter
															: undefined}
														loading="eager"
														onerror={(e) => {
															console.error('Image failed to load:', card.name, getImageUrl(card.image, imageQuality));
															e.currentTarget.style.display = 'none';
														}}
													/>
												{/if}
											</div>
										{/if}
									</div>
								{/each}
							</div>
						</div>
					{/each}
				</div>
			{/if}
		</div>
	</div>

	<!-- Print View (hidden on screen) -->
	<div class="hidden print:block">
		{#each printPages as page, pageIdx}
			<div
				class="page"
				style:width="{pageWidthMM}mm"
				style:height="{pageHeightMM}mm"
				style:page-break-after={pageIdx < printPages.length - 1 ? 'always' : 'auto'}
			>
				<div
					class="grid"
					style:grid-template-columns="repeat({cardsPerRow}, {cardWidthMM}mm)"
					style:grid-template-rows="repeat({rowsPerPage}, {cardHeightMM}mm)"
				>
					{#each page.cards as card}
						<div
							style:width="{cardWidthMM}mm"
							style:height="{cardHeightMM}mm"
							style:position="relative"
						>
							<!-- Card content here - simplified for printing -->
							<div
								style:width="100%"
								style:height="100%"
								style:border="{showCutLines ? '1px dashed #999' : visualConfig.borderWidth + 'px solid ' + visualConfig.borderColor}"
								style:background="white"
								style:position="relative"
							>
								<!-- Tab section -->
								<div
									style:position="absolute"
									style:top="0"
									style:left="0"
									style:right="0"
									style:height="{config.cardDimensions.tabHeight}mm"
									style:background={config.colors.secondary}
									style:display="flex"
									style:align-items="center"
									style:justify-content="center"
									style:z-index="2"
									style:transform="translate({tabConfig.offsetX}px, {tabConfig.offsetY}px)"
									style:padding="0 4px"
									style:overflow="hidden"
								>
									<span
										style:color={tabConfig.textColor}
										style:font-family={tabConfig.fontFamily}
										style:font-weight="bold"
										style:-webkit-text-stroke="{tabConfig.strokeWidth}px {tabConfig.strokeColor}"
										style:paint-order="stroke fill"
										style:white-space="nowrap"
										style:font-size="clamp(6px, {tabConfig.fontSize}px, {tabConfig.fontSize}px)"
									>
										{card.name}
									</span>
								</div>

								<!-- Image -->
								{#if card.image}
									<div
										style:position="absolute"
										style:top="{config.cardDimensions.tabHeight}mm"
										style:left="0"
										style:right="0"
										style:bottom="0"
										style:display="flex"
										style:align-items="center"
										style:justify-content="center"
										style:background="#f3f4f6"
									>
										<img
											src={getImageUrl(card.image, imageQuality)}
											alt={card.name}
											style:width="{visualConfig.imageCenterSize}%"
											style:height="{visualConfig.imageCenterSize}%"
											style:object-fit="contain"
											style:filter={visualConfig.imageFilter !== 'none'
												? visualConfig.imageFilter
												: undefined}
											loading="eager"
											crossorigin="anonymous"
										/>
									</div>
								{/if}
							</div>
						</div>
					{/each}
				</div>
			</div>
		{/each}
	</div>
</main>
