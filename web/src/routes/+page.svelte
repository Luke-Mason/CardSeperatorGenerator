<script lang="ts">
  import Card from '../lib/Card.svelte'
  import ConfigPanel from '../lib/ConfigPanel.svelte';
  import Presets from '../lib/Presets.svelte';
  import { onMount } from 'svelte';
  import { getImageUrl, type ImageSize } from '../lib/api';
  import { loadConfig, saveConfig, type AppConfig } from '../lib/config';

  // Configuration
  let config = $state<AppConfig>(loadConfig());
  let showConfigPanel = $state(false);
  let showPresetsPanel = $state(false);
  let doubleSided = $state(config.doubleSided);
  let flipEdge: 'long' | 'short' = $state(config.flipEdge);
  let showImages = $state(config.showImages);
  let imageQuality: ImageSize = $state(config.imageQuality);
  let showCutLines = $state(config.showCutLines);
  let setId = $state(config.setId);

  // Filter/Sort
  let filterColor = $state('');
  let filterType = $state('');
  let sortBy: 'id' | 'name' | 'cost' | 'power' = $state('id');

  // Page dimensions
  const titleWidthMM = 25;
  let titleHeightMM = $derived(config.cardDimensions.tabHeight);
  let cardWidthMM = $derived(config.cardDimensions.width);
  let cardHeightMM = $derived(config.cardDimensions.height);
  let pageWidthMM = $derived(config.pageDimensions.width);
  let pageHeightMM = $derived(config.pageDimensions.height);

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
  let loadingProgress = $state(0);

  // Filtered and sorted cards
  let cards = $derived.by(() => {
    let filtered = allCards;

    // Apply filters
    if (filterColor) {
      filtered = filtered.filter(c => c.rawData?.card_color?.toLowerCase().includes(filterColor.toLowerCase()));
    }
    if (filterType) {
      filtered = filtered.filter(c => c.rawData?.card_type?.toLowerCase().includes(filterType.toLowerCase()));
    }

    // Apply sorting
    const sorted = [...filtered].sort((a, b) => {
      switch (sortBy) {
        case 'name':
          return a.name.localeCompare(b.name);
        case 'cost': {
          const costA = parseInt(a.cost) || 999;
          const costB = parseInt(b.cost) || 999;
          return costA - costB;
        }
        case 'power': {
          const powerA = parseInt(a.rawData?.card_power || '0');
          const powerB = parseInt(b.rawData?.card_power || '0');
          return powerB - powerA;
        }
        default: // 'id'
          return a.cardSetId.localeCompare(b.cardSetId);
      }
    });

    return sorted;
  });

  // Calculate cards per page
  const cardsPerRow = Math.floor(pageWidthMM / cardWidthMM);
  const rowsPerPage = Math.floor(pageHeightMM / cardHeightMM);
  const cardsPerPage = cardsPerRow * rowsPerPage;

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
      data.forEach(card => {
        if (!uniqueCards.has(card.card_set_id)) {
          uniqueCards.set(card.card_set_id, card);
        }
      });

      // Sort by card_set_id
      const sortedCards = Array.from(uniqueCards.values()).sort((a, b) =>
        a.card_set_id.localeCompare(b.card_set_id)
      );

      allCards = sortedCards.map(card => ({
        width: cardWidthMM,
        height: cardHeightMM,
        setId: card.set_id,
        cardSetId: card.card_set_id,
        id: card.card_set_id.split('-')[1] || '',
        name: card.card_name,
        cost: card.card_cost === 'NULL' || !card.card_cost ? '' : card.card_cost,
        image: card.card_image, // Original URL, will be proxied through backend
        rawData: card
      }));

    } catch (e) {
      error = e instanceof Error ? e.message : 'Unknown error';
      console.error('Error fetching cards:', e);
    } finally {
      loading = false;
    }
  }

  // Chunk cards into pages
  function chunkCards(array: CardDetails[], size: number) {
    const chunks = [];
    for (let i = 0; i < array.length; i += size) {
      chunks.push(array.slice(i, i + size));
    }
    return chunks;
  }

  // Generate back pages with proper alignment
  // CRITICAL: Each separator shows Card N on front, Card N-1 on back
  // So when you place it in your collection, it sits between N-1 and N
  function generateBackPages(frontPages: CardDetails[][]): CardDetails[][] {
    if (!doubleSided) return [];

    return frontPages.map((page, pageIndex) => {
      // Get the previous card for each position
      const backPageCards: CardDetails[] = [];

      for (let i = 0; i < page.length; i++) {
        const currentCard = page[i];
        const globalIndex = pageIndex * cardsPerPage + i;

        // Get the previous card (N-1)
        let previousCard: CardDetails;
        if (globalIndex === 0) {
          // First card has no previous, use itself or create a "START" separator
          previousCard = {
            ...currentCard,
            name: 'Collection Start',
            cardSetId: '---',
            id: '---',
            cost: '',
            image: ''
          };
        } else {
          previousCard = cards[globalIndex - 1];
        }

        backPageCards.push(previousCard);
      }

      // Now apply flip transformation
      if (flipEdge === 'long') {
        // Long edge flip: horizontal mirror each row
        const rows = [];
        for (let row = 0; row < rowsPerPage; row++) {
          const rowCards = backPageCards.slice(row * cardsPerRow, (row + 1) * cardsPerRow);
          rows.push([...rowCards].reverse());
        }
        return rows.flat();
      } else {
        // Short edge flip: 180° rotation
        return [...backPageCards].reverse();
      }
    });
  }

  let frontPages = $derived(chunkCards(cards, cardsPerPage));
  let backPages = $derived(generateBackPages(frontPages));

  // Multi-set loading
  async function loadMultipleSets(setIds: string[]) {
    loading = true;
    error = '';
    loadingProgress = 0;
    const allCardsData: CardDetails[] = [];

    try {
      for (let i = 0; i < setIds.length; i++) {
        const id = setIds[i];
        loadingProgress = Math.round(((i + 1) / setIds.length) * 100);

        const response = await fetch(`https://optcgapi.com/api/sets/${id}/`);
        if (!response.ok) continue;

        const data: APICard[] = await response.json();
        const uniqueCards = new Map<string, APICard>();
        data.forEach(card => {
          if (!uniqueCards.has(card.card_set_id)) {
            uniqueCards.set(card.card_set_id, card);
          }
        });

        const setCards = Array.from(uniqueCards.values()).map(card => ({
          width: cardWidthMM,
          height: cardHeightMM,
          setId: card.set_id,
          cardSetId: card.card_set_id,
          id: card.card_set_id.split('-')[1] || '',
          name: card.card_name,
          cost: card.card_cost === 'NULL' || !card.card_cost ? '' : card.card_cost,
          image: card.card_image,
          rawData: card
        }));

        allCardsData.push(...setCards);
      }

      allCards = allCardsData.sort((a, b) => a.cardSetId.localeCompare(b.cardSetId));
    } catch (e) {
      error = e instanceof Error ? e.message : 'Unknown error';
    } finally {
      loading = false;
      loadingProgress = 0;
    }
  }

  // Save config whenever it changes
  $effect(() => {
    saveConfig({
      ...config,
      doubleSided,
      flipEdge,
      showImages,
      imageQuality,
      showCutLines,
      setId
    });
  });

  // Keyboard shortcuts
  function handleKeyboard(e: KeyboardEvent) {
    // Ctrl/Cmd + P - Print
    if ((e.ctrlKey || e.metaKey) && e.key === 'p') {
      e.preventDefault();
      window.print();
    }
    // Ctrl/Cmd + K - Open config
    if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
      e.preventDefault();
      showConfigPanel = !showConfigPanel;
    }
    // Shift + P - Open presets
    if (e.shiftKey && e.key === 'P') {
      e.preventDefault();
      showPresetsPanel = !showPresetsPanel;
    }
    // Escape - Close modals
    if (e.key === 'Escape') {
      showConfigPanel = false;
      showPresetsPanel = false;
    }
  }

  onMount(() => {
    fetchCards();
    window.addEventListener('keydown', handleKeyboard);
    return () => window.removeEventListener('keydown', handleKeyboard);
  });
</script>

{#if showConfigPanel}
  <ConfigPanel bind:config onClose={() => {
    showConfigPanel = false;
    // Apply config changes
    doubleSided = config.doubleSided;
    flipEdge = config.flipEdge;
    showImages = config.showImages;
    imageQuality = config.imageQuality;
    showCutLines = config.showCutLines;
  }} />
{/if}

{#if showPresetsPanel}
  <Presets
    onApply={(newConfig) => {
      config = newConfig;
      doubleSided = config.doubleSided;
      flipEdge = config.flipEdge;
      showImages = config.showImages;
      imageQuality = config.imageQuality;
      showCutLines = config.showCutLines;
    }}
    onClose={() => showPresetsPanel = false}
  />
{/if}

<main class="min-h-screen">
  <!-- Configuration Panel (hidden when printing) -->
  <div class="print:hidden bg-gray-800 text-white p-6 sticky top-0 z-50 shadow-lg">
    <div class="flex items-center justify-between mb-4">
      <h1 class="text-2xl font-bold">Card Separator Generator</h1>
      <div class="flex gap-2">
        <button
          onclick={() => showPresetsPanel = true}
          class="px-4 py-2 bg-indigo-600 hover:bg-indigo-700 rounded font-medium transition-colors"
          title="Save/Load Presets (Shift+P)"
        >
          <svg class="w-5 h-5 inline mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 8h14M5 8a2 2 0 110-4h14a2 2 0 110 4M5 8v10a2 2 0 002 2h10a2 2 0 002-2V8m-9 4h4" />
          </svg>
          Presets
        </button>
        <button
          onclick={() => showConfigPanel = true}
          class="px-4 py-2 bg-purple-600 hover:bg-purple-700 rounded font-medium transition-colors"
          title="Configuration (Ctrl+K)"
        >
          <svg class="w-5 h-5 inline mr-1" fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
          </svg>
          Config
        </button>
        <button
          onclick={() => window.print()}
          disabled={cards.length === 0}
          class="px-4 py-2 bg-green-600 hover:bg-green-700 disabled:bg-gray-600 rounded font-medium transition-colors"
          title="Print (Ctrl+P)"
        >
          Print
        </button>
      </div>
    </div>

    <!-- Filter/Sort Bar -->
    <div class="grid grid-cols-2 md:grid-cols-6 gap-3 mb-4">
      <div>
        <label class="block text-xs font-medium text-gray-300 mb-1">Set ID(s)</label>
        <input
          type="text"
          bind:value={setId}
          class="w-full px-3 py-2 bg-gray-700 rounded border border-gray-600 focus:border-blue-500 focus:outline-none text-sm"
          placeholder="OP-01 or OP-01,OP-02"
          title="Comma-separated for multiple sets"
        />
      </div>
      <div>
        <label class="block text-xs font-medium text-gray-300 mb-1">Filter Color</label>
        <input
          type="text"
          bind:value={filterColor}
          class="w-full px-3 py-2 bg-gray-700 rounded border border-gray-600 focus:border-blue-500 focus:outline-none text-sm"
          placeholder="Red, Blue..."
        />
      </div>
      <div>
        <label class="block text-xs font-medium text-gray-300 mb-1">Filter Type</label>
        <input
          type="text"
          bind:value={filterType}
          class="w-full px-3 py-2 bg-gray-700 rounded border border-gray-600 focus:border-blue-500 focus:outline-none text-sm"
          placeholder="Leader, Character..."
        />
      </div>
      <div>
        <label class="block text-xs font-medium text-gray-300 mb-1">Sort By</label>
        <select bind:value={sortBy} class="w-full px-3 py-2 bg-gray-700 rounded text-sm border border-gray-600">
          <option value="id">Card ID</option>
          <option value="name">Name</option>
          <option value="cost">Cost</option>
          <option value="power">Power</option>
        </select>
      </div>
      <div class="col-span-2 flex items-end gap-2">
        <button
          onclick={() => {
            const sets = setId.split(',').map(s => s.trim()).filter(Boolean);
            if (sets.length > 1) {
              loadMultipleSets(sets);
            } else {
              fetchCards();
            }
          }}
          disabled={loading}
          class="flex-1 px-4 py-2 bg-blue-600 hover:bg-blue-700 disabled:bg-gray-600 rounded font-medium transition-colors text-sm"
        >
          {loading ? `Loading ${loadingProgress}%...` : 'Load Cards'}
        </button>
        {#if allCards.length > 0}
          <button
            onclick={() => { filterColor = ''; filterType = ''; sortBy = 'id'; }}
            class="px-3 py-2 bg-gray-700 hover:bg-gray-600 rounded text-sm"
            title="Clear filters"
          >
            ✕
          </button>
        {/if}
      </div>
    </div>

    <!-- Quick Controls -->
    <div class="grid grid-cols-1 md:grid-cols-4 gap-4 mb-4">

      <div>
        <label class="flex items-center gap-2">
          <input type="checkbox" bind:checked={doubleSided} class="w-4 h-4" />
          <span class="text-sm font-medium">Double-Sided</span>
        </label>
        {#if doubleSided}
          <div class="mt-2">
            <label class="block text-xs text-gray-300 mb-1">Flip Edge</label>
            <select bind:value={flipEdge} class="w-full px-2 py-1 bg-gray-700 rounded text-sm border border-gray-600">
              <option value="long">Long (Book)</option>
              <option value="short">Short (Calendar)</option>
            </select>
          </div>
        {/if}
      </div>

      <div class="space-y-2">
        <label class="flex items-center gap-2">
          <input type="checkbox" bind:checked={showImages} class="w-4 h-4" />
          <span class="text-sm font-medium">Show Images</span>
        </label>
        {#if showImages}
          <div>
            <label class="block text-xs text-gray-300 mb-1">Image Quality</label>
            <select bind:value={imageQuality} class="w-full px-2 py-1 bg-gray-700 rounded text-sm border border-gray-600">
              <option value="thumbnail">Low (Fast)</option>
              <option value="medium">Medium (Balanced)</option>
              <option value="full">High (Slow)</option>
              <option value="original">Original (Very Slow)</option>
            </select>
          </div>
        {/if}
        <label class="flex items-center gap-2">
          <input type="checkbox" bind:checked={showCutLines} class="w-4 h-4" />
          <span class="text-sm font-medium">Cut Lines</span>
        </label>
      </div>

    </div>

    {#if error}
      <div class="bg-red-900/50 border border-red-500 rounded p-3 text-sm">
        Error: {error}
      </div>
    {/if}

    {#if allCards.length > 0}
      <div class="text-sm text-gray-300 space-y-1">
        <div class="flex items-center justify-between">
          <div>
            {cards.length} cards {allCards.length !== cards.length ? `(${allCards.length} total, ${allCards.length - cards.length} filtered)` : ''} |
            {frontPages.length} pages {doubleSided ? `(${frontPages.length * 2} total with backs)` : ''}
            | {cardsPerRow} cards per row, {rowsPerPage} rows per page
          </div>
          <div class="text-xs text-gray-400">
            Shortcuts: Ctrl+P (Print) · Ctrl+K (Config) · Shift+P (Presets) · Esc (Close)
          </div>
        </div>
        {#if doubleSided}
          <div class="text-yellow-300">
            Print Instructions: Print all {frontPages.length} front pages first, then reload paper and print {backPages.length} back pages.
            {flipEdge === 'long' ? 'Set your printer to flip on LONG edge (like a book).' : 'Set your printer to flip on SHORT edge (like a calendar).'}
          </div>
        {/if}
      </div>
    {/if}

    <!-- Instructions Accordion -->
    <details class="mt-4 bg-gray-700 rounded p-3">
      <summary class="cursor-pointer font-medium">How to Use</summary>
      <div class="mt-3 text-sm text-gray-300 space-y-2">
        <p><strong>1. Load Cards:</strong> Enter a set ID (e.g., OP-01, OP-02) and click "Load Cards"</p>
        <p><strong>2. Configure:</strong> Choose single or double-sided printing. If double-sided, test with a sample sheet to determine your printer's flip edge</p>
        <p><strong>3. Print:</strong> Click the "Print" button. For double-sided, print front pages first, then reload the paper and print back pages</p>
        <p><strong>4. Cut:</strong> Cut along the card boundaries to create individual separators</p>
        <p><strong>5. Organize:</strong> Place separators in your collection between sequential cards</p>
      </div>
    </details>
  </div>

  <!-- Print Area -->
  <div class="p-0 bg-gray-100 print:bg-white print:p-0">
    {#if loading}
      <div class="flex items-center justify-center h-96">
        <div class="text-2xl text-gray-600">Loading cards...</div>
      </div>
    {:else if cards.length === 0}
      <div class="flex items-center justify-center h-96">
        <div class="text-xl text-gray-600">Enter a Set ID and click "Load Cards"</div>
      </div>
    {:else}
      <!-- Front Pages -->
      {#each frontPages as page, pageIdx}
        <div
          class="grid gap-0 justify-start break-after-page print:gap-0 print:justify-start page-break"
          style={`grid-template-columns: repeat(${cardsPerRow}, ${cardWidthMM}mm);`}
        >
          {#each page as card}
            <Card
              {card}
              {titleHeightMM}
              {titleWidthMM}
              showImage={showImages}
              imageUrl={card.image ? getImageUrl(card.image, imageQuality) : ''}
              {showCutLines}
            />
          {/each}
        </div>
      {/each}

      <!-- Back Pages -->
      {#if doubleSided}
        {#each backPages as page, pageIdx}
          <div
            class="grid gap-0 justify-start break-after-page print:gap-0 print:justify-start page-break"
            style={`grid-template-columns: repeat(${cardsPerRow}, ${cardWidthMM}mm);`}
          >
            {#each page as card}
              <Card
                {card}
                {titleHeightMM}
                {titleWidthMM}
                showImage={showImages}
                imageUrl={card.image ? getImageUrl(card.image, imageQuality) : ''}
                {showCutLines}
              />
            {/each}
          </div>
        {/each}
      {/if}
    {/if}
  </div>
</main>

<style>
  .page-break {
    page-break-after: always;
    break-after: page;
  }

  @media print {
    .page-break:last-child {
      page-break-after: auto;
      break-after: auto;
    }

    @page {
      size: A4;
      margin: 0;
    }

    body {
      margin: 0;
      padding: 0;
    }
  }
</style>
