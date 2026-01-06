<script lang="ts">
  import type { AppConfig } from './config';
  import type { ImageSize } from './api';

  interface TabConfig {
    fontSize: number;
    fontFamily: string;
    offsetX: number;
    offsetY: number;
    content: string;
    textColor: string;
    strokeWidth: number;
    strokeColor: string;
  }

  interface VisualConfig {
    borderColor: string;
    borderWidth: number;
    imageCenterSize: number;
    imageFilter: string;
  }

  let {
    config = $bindable(),
    tabConfig = $bindable(),
    visualConfig = $bindable(),
    setId = $bindable(),
    showCutLines = $bindable(),
    doubleSided = $bindable(),
    flipEdge = $bindable(),
    imageQuality = $bindable(),
    loading = false,
    error = '',
    allCards = [],
    onLoadCards,
    onPrint,
    isCollapsed = $bindable(false)
  }: {
    config: AppConfig;
    tabConfig: TabConfig;
    visualConfig: VisualConfig;
    setId: string;
    showCutLines: boolean;
    doubleSided: boolean;
    flipEdge: 'long' | 'short';
    imageQuality: ImageSize;
    loading?: boolean;
    error?: string;
    allCards?: any[];
    onLoadCards: () => void;
    onPrint: () => void;
    isCollapsed?: boolean;
  } = $props();

  // Filter presets
  const filterPresets = [
    { label: 'None', value: 'none', css: '' },
    { label: 'Grayscale', value: 'grayscale', css: 'grayscale(100%)' },
    { label: 'Sepia', value: 'sepia', css: 'sepia(100%)' },
    { label: 'Vintage', value: 'vintage', css: 'sepia(50%) contrast(120%)' },
    { label: 'Blur', value: 'blur', css: 'blur(2px)' },
    { label: 'High Contrast', value: 'contrast', css: 'contrast(150%)' }
  ];

  // Font families
  const fontFamilies = [
    'Impact, sans-serif',
    'Arial, sans-serif',
    'Times New Roman, serif',
    'Courier New, monospace',
    'Georgia, serif',
    'Verdana, sans-serif',
    'Comic Sans MS, cursive'
  ];

  // Section expansion states
  let expandedSections = $state({
    basic: true,
    tab: true,
    visual: true,
    print: false,
    advanced: false
  });

  function toggleSection(section: keyof typeof expandedSections) {
    expandedSections[section] = !expandedSections[section];
  }
</script>

<!-- Sidebar -->
<aside
  class="sidebar-container"
  class:collapsed={isCollapsed}
>
  {#if !isCollapsed}
    <div class="sidebar-content">
      <!-- Header -->
      <div class="sidebar-header">
        <h2 class="text-xl font-bold">Card Separator Editor</h2>
        {#if allCards.length > 0}
          <p class="text-sm text-gray-400 mt-1">
            {allCards.length} cards loaded
          </p>
        {/if}
      </div>

      <!-- Basic Settings -->
      <section class="sidebar-section">
        <button
          class="section-header"
          onclick={() => toggleSection('basic')}
        >
          <span class="font-semibold">Basic Settings</span>
          <svg
            class="w-5 h-5 transition-transform"
            class:rotate-180={expandedSections.basic}
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
          </svg>
        </button>

        {#if expandedSections.basic}
          <div class="section-content">
            <div class="form-group">
              <label>Set ID(s)</label>
              <input
                type="text"
                bind:value={setId}
                placeholder="OP-01 or OP-01,OP-02"
                class="form-input"
              />
              <p class="form-hint">Comma-separated for multiple sets</p>
            </div>

            <button
              onclick={onLoadCards}
              class="btn btn-primary w-full"
              disabled={loading}
            >
              {loading ? 'Loading...' : 'Load Cards'}
            </button>

            {#if error}
              <p class="text-red-400 text-sm mt-2">{error}</p>
            {/if}

            {#if allCards.length > 0}
              <p class="text-green-400 text-sm mt-2">{allCards.length} cards loaded</p>
            {/if}

            <div class="form-group">
              <label class="checkbox-label">
                <input type="checkbox" bind:checked={showCutLines} />
                <span>Show Cutting Lines</span>
              </label>
            </div>
          </div>
        {/if}
      </section>

      <!-- Tab Editing -->
      <section class="sidebar-section">
        <button
          class="section-header"
          onclick={() => toggleSection('tab')}
        >
          <span class="font-semibold">Tab Settings</span>
          <svg
            class="w-5 h-5 transition-transform"
            class:rotate-180={expandedSections.tab}
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
          </svg>
        </button>

        {#if expandedSections.tab}
          <div class="section-content">
            <div class="form-group">
              <label>Tab Content</label>
              <input
                type="text"
                bind:value={tabConfig.content}
                placeholder="{'{name}'} - {'{id}'}"
                class="form-input"
              />
              <p class="form-hint">Use: {'{name}'}, {'{id}'}, {'{cost}'}</p>
            </div>

            <div class="form-group">
              <label>Font Family</label>
              <select bind:value={tabConfig.fontFamily} class="form-select">
                {#each fontFamilies as font}
                  <option value={font}>{font.split(',')[0]}</option>
                {/each}
              </select>
            </div>

            <div class="grid grid-cols-2 gap-3">
              <div class="form-group">
                <label>Font Size</label>
                <input
                  type="number"
                  bind:value={tabConfig.fontSize}
                  min="8"
                  max="24"
                  step="1"
                  class="form-input"
                />
              </div>

              <div class="form-group">
                <label>Tab Height (mm)</label>
                <input
                  type="number"
                  bind:value={config.cardDimensions.tabHeight}
                  min="5"
                  max="30"
                  step="1"
                  class="form-input"
                />
              </div>
            </div>

            <div class="grid grid-cols-2 gap-3">
              <div class="form-group">
                <label>Offset X (mm)</label>
                <input
                  type="number"
                  bind:value={tabConfig.offsetX}
                  min="-10"
                  max="10"
                  step="0.5"
                  class="form-input"
                />
              </div>

              <div class="form-group">
                <label>Offset Y (mm)</label>
                <input
                  type="number"
                  bind:value={tabConfig.offsetY}
                  min="-10"
                  max="10"
                  step="0.5"
                  class="form-input"
                />
              </div>
            </div>

            <div class="form-group">
              <label>Text Color</label>
              <div class="flex gap-2">
                <input
                  type="color"
                  bind:value={tabConfig.textColor}
                  class="color-input"
                />
                <input
                  type="text"
                  bind:value={tabConfig.textColor}
                  class="form-input flex-1 font-mono"
                />
              </div>
            </div>

            <div class="grid grid-cols-2 gap-3">
              <div class="form-group">
                <label>Stroke Width</label>
                <input
                  type="number"
                  bind:value={tabConfig.strokeWidth}
                  min="0"
                  max="3"
                  step="0.1"
                  class="form-input"
                />
              </div>

              <div class="form-group">
                <label>Stroke Color</label>
                <input
                  type="color"
                  bind:value={tabConfig.strokeColor}
                  class="color-input w-full"
                />
              </div>
            </div>
          </div>
        {/if}
      </section>

      <!-- Visual Settings -->
      <section class="sidebar-section">
        <button
          class="section-header"
          onclick={() => toggleSection('visual')}
        >
          <span class="font-semibold">Visual Settings</span>
          <svg
            class="w-5 h-5 transition-transform"
            class:rotate-180={expandedSections.visual}
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
          </svg>
        </button>

        {#if expandedSections.visual}
          <div class="section-content">
            <div class="form-group">
              <label>Border Color</label>
              <div class="flex gap-2">
                <input
                  type="color"
                  bind:value={visualConfig.borderColor}
                  class="color-input"
                />
                <input
                  type="text"
                  bind:value={visualConfig.borderColor}
                  class="form-input flex-1 font-mono"
                />
              </div>
            </div>

            <div class="form-group">
              <label>Border Width (px)</label>
              <input
                type="range"
                bind:value={visualConfig.borderWidth}
                min="0"
                max="5"
                step="0.5"
                class="w-full"
              />
              <span class="text-sm text-gray-400">{visualConfig.borderWidth}px</span>
            </div>

            <div class="form-group">
              <label class="checkbox-label">
                <input type="checkbox" bind:checked={config.showImages} />
                <span>Show Card Images</span>
              </label>
            </div>

            {#if config.showImages}
              <div class="form-group">
                <label>Image Size (%)</label>
                <input
                  type="range"
                  bind:value={visualConfig.imageCenterSize}
                  min="50"
                  max="100"
                  step="5"
                  class="w-full"
                />
                <span class="text-sm text-gray-400">{visualConfig.imageCenterSize}%</span>
              </div>

              <div class="form-group">
                <label>Image Quality</label>
                <select bind:value={imageQuality} class="form-select">
                  <option value="thumbnail">Low (Fast)</option>
                  <option value="medium">Medium</option>
                  <option value="full">High</option>
                  <option value="original">Original</option>
                </select>
              </div>

              <div class="form-group">
                <label>Image Filter</label>
                <div class="grid grid-cols-2 gap-2">
                  {#each filterPresets as preset}
                    <button
                      onclick={() => visualConfig.imageFilter = preset.value}
                      class="filter-preset"
                      class:active={visualConfig.imageFilter === preset.value}
                    >
                      {preset.label}
                    </button>
                  {/each}
                </div>
              </div>
            {/if}

            <div class="form-group">
              <label>Primary Color</label>
              <div class="flex gap-2">
                <input
                  type="color"
                  bind:value={config.colors.primary}
                  class="color-input"
                />
                <input
                  type="text"
                  bind:value={config.colors.primary}
                  class="form-input flex-1 font-mono"
                />
              </div>
            </div>

            <div class="form-group">
              <label>Secondary Color</label>
              <div class="flex gap-2">
                <input
                  type="color"
                  bind:value={config.colors.secondary}
                  class="color-input"
                />
                <input
                  type="text"
                  bind:value={config.colors.secondary}
                  class="form-input flex-1 font-mono"
                />
              </div>
            </div>
          </div>
        {/if}
      </section>

      <!-- Print Settings -->
      <section class="sidebar-section">
        <button
          class="section-header"
          onclick={() => toggleSection('print')}
        >
          <span class="font-semibold">Print Settings</span>
          <svg
            class="w-5 h-5 transition-transform"
            class:rotate-180={expandedSections.print}
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
          </svg>
        </button>

        {#if expandedSections.print}
          <div class="section-content">
            <div class="form-group">
              <label class="checkbox-label">
                <input type="checkbox" bind:checked={doubleSided} />
                <span>Double-Sided Printing</span>
              </label>
              <p class="form-hint">Single print run with automatic duplex</p>
            </div>

            {#if doubleSided}
              <div class="form-group">
                <label>Flip Edge</label>
                <select bind:value={flipEdge} class="form-select">
                  <option value="long">Long Edge (Book)</option>
                  <option value="short">Short Edge (Calendar)</option>
                </select>
              </div>
            {/if}

            <button
              onclick={onPrint}
              class="btn btn-success w-full"
              disabled={allCards.length === 0}
            >
              <svg class="w-5 h-5 inline mr-2" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 17h2a2 2 0 002-2v-4a2 2 0 00-2-2H5a2 2 0 00-2 2v4a2 2 0 002 2h2m2 4h6a2 2 0 002-2v-4a2 2 0 00-2-2H9a2 2 0 00-2 2v4a2 2 0 002 2zm8-12V5a2 2 0 00-2-2H9a2 2 0 00-2 2v4h10z" />
              </svg>
              Print Cards (Ctrl+P)
            </button>
          </div>
        {/if}
      </section>

      <!-- Advanced Settings -->
      <section class="sidebar-section">
        <button
          class="section-header"
          onclick={() => toggleSection('advanced')}
        >
          <span class="font-semibold">Advanced</span>
          <svg
            class="w-5 h-5 transition-transform"
            class:rotate-180={expandedSections.advanced}
            fill="none"
            stroke="currentColor"
            viewBox="0 0 24 24"
          >
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
          </svg>
        </button>

        {#if expandedSections.advanced}
          <div class="section-content">
            <div class="grid grid-cols-2 gap-3">
              <div class="form-group">
                <label>Card Width (mm)</label>
                <input
                  type="number"
                  bind:value={config.cardDimensions.width}
                  min="40"
                  max="100"
                  class="form-input"
                />
              </div>

              <div class="form-group">
                <label>Card Height (mm)</label>
                <input
                  type="number"
                  bind:value={config.cardDimensions.height}
                  min="60"
                  max="150"
                  class="form-input"
                />
              </div>
            </div>

            <div class="form-group">
              <label>Page Size</label>
              <select
                bind:value={config.pageSize}
                onchange={(e) => {
                  const size = e.currentTarget.value as any;
                  if (size !== 'custom') {
                    const PAGE_SIZES = {
                      a4: { width: 210, height: 297 },
                      letter: { width: 216, height: 279 },
                      legal: { width: 216, height: 356 }
                    };
                    config.pageDimensions = PAGE_SIZES[size];
                  }
                }}
                class="form-select"
              >
                <option value="a4">A4 (210×297mm)</option>
                <option value="letter">Letter (216×279mm)</option>
                <option value="legal">Legal (216×356mm)</option>
                <option value="custom">Custom</option>
              </select>
            </div>

            {#if config.pageSize === 'custom'}
              <div class="grid grid-cols-2 gap-3">
                <div class="form-group">
                  <label>Width (mm)</label>
                  <input
                    type="number"
                    bind:value={config.pageDimensions.width}
                    class="form-input"
                  />
                </div>

                <div class="form-group">
                  <label>Height (mm)</label>
                  <input
                    type="number"
                    bind:value={config.pageDimensions.height}
                    class="form-input"
                  />
                </div>
              </div>
            {/if}
          </div>
        {/if}
      </section>
    </div>
  {/if}

  <!-- Toggle Button (Always visible, outside scroll area) -->
  <button
    class="sidebar-toggle print:hidden"
    onclick={() => isCollapsed = !isCollapsed}
    title={isCollapsed ? 'Expand Sidebar' : 'Collapse Sidebar'}
  >
    {#if isCollapsed}
      <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
      </svg>
    {:else}
      <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
      </svg>
    {/if}
  </button>
</aside>

<style>
  .sidebar-container {
    position: relative;
    width: 320px;
    height: 100vh;
    background: #1f2937;
    color: white;
    transition: width 0.3s ease, margin-left 0.3s ease;
    overflow: hidden; /* Hide overflow on container */
    box-shadow: 2px 0 8px rgba(0,0,0,0.3);
    flex-shrink: 0;
  }

  .sidebar-container.collapsed {
    width: 40px;
    margin-left: 0;
  }

  .sidebar-content {
    padding: 1.5rem;
    padding-right: 1rem; /* Less padding on right to make room for scrollbar */
    padding-bottom: 4rem;
    height: 100%;
    overflow-y: auto; /* Scrolling happens here */
    overflow-x: hidden;
  }

  /* Custom scrollbar styling */
  .sidebar-content::-webkit-scrollbar {
    width: 8px;
  }

  .sidebar-content::-webkit-scrollbar-track {
    background: #1f2937;
    border-radius: 4px;
  }

  .sidebar-content::-webkit-scrollbar-thumb {
    background: #4b5563;
    border-radius: 4px;
    border: 2px solid #1f2937;
  }

  .sidebar-content::-webkit-scrollbar-thumb:hover {
    background: #6b7280;
  }

  .sidebar-toggle {
    position: absolute; /* Absolute positioning within sidebar container */
    right: -40px; /* Moved further right to sit cleanly on edge */
    top: 50%;
    transform: translateY(-50%);
    background: #1f2937;
    border: 2px solid #374151;
    border-radius: 0 8px 8px 0;
    padding: 12px 4px;
    cursor: pointer;
    transition: all 0.2s;
    z-index: 1000; /* High z-index to stay on top */
  }

  .sidebar-container.collapsed .sidebar-toggle {
    right: -40px; /* Consistent positioning when collapsed */
  }

  .sidebar-toggle:hover {
    background: #374151;
  }

  .sidebar-header {
    margin-bottom: 1.5rem;
    padding-bottom: 1rem;
    border-bottom: 1px solid #374151;
  }

  .sidebar-section {
    margin-bottom: 1rem;
    background: #374151;
    border-radius: 8px;
    overflow: hidden;
  }

  .section-header {
    width: 100%;
    display: flex;
    justify-content: space-between;
    align-items: center;
    padding: 0.75rem 1rem;
    background: #374151;
    border: none;
    color: white;
    cursor: pointer;
    transition: background 0.2s;
  }

  .section-header:hover {
    background: #4b5563;
  }

  .section-content {
    padding: 1rem;
    background: #1f2937;
  }

  .form-group {
    margin-bottom: 1rem;
  }

  .form-group label {
    display: block;
    font-size: 0.875rem;
    font-weight: 500;
    color: #d1d5db;
    margin-bottom: 0.375rem;
  }

  .form-input, .form-select {
    width: 100%;
    padding: 0.5rem 0.75rem;
    background: #374151;
    border: 1px solid #4b5563;
    border-radius: 6px;
    color: white;
    font-size: 0.875rem;
    outline: none;
    transition: border-color 0.2s;
  }

  .form-input:focus, .form-select:focus {
    border-color: #3b82f6;
  }

  .form-hint {
    font-size: 0.75rem;
    color: #9ca3af;
    margin-top: 0.25rem;
  }

  .checkbox-label {
    display: flex;
    align-items: center;
    gap: 0.5rem;
    cursor: pointer;
  }

  .checkbox-label input[type="checkbox"] {
    width: 1.125rem;
    height: 1.125rem;
    cursor: pointer;
  }

  .color-input {
    width: 48px;
    height: 40px;
    padding: 4px;
    background: #374151;
    border: 1px solid #4b5563;
    border-radius: 6px;
    cursor: pointer;
  }

  .btn {
    padding: 0.625rem 1.25rem;
    border-radius: 6px;
    font-weight: 600;
    font-size: 0.875rem;
    cursor: pointer;
    border: none;
    transition: all 0.2s;
    display: inline-flex;
    align-items: center;
    justify-content: center;
  }

  .btn-primary {
    background: #3b82f6;
    color: white;
  }

  .btn-primary:hover {
    background: #2563eb;
  }

  .btn-success {
    background: #10b981;
    color: white;
  }

  .btn-success:hover {
    background: #059669;
  }

  .filter-preset {
    padding: 0.5rem;
    background: #374151;
    border: 2px solid #4b5563;
    border-radius: 4px;
    font-size: 0.75rem;
    cursor: pointer;
    transition: all 0.2s;
  }

  .filter-preset:hover {
    background: #4b5563;
  }

  .filter-preset.active {
    background: #3b82f6;
    border-color: #3b82f6;
  }

  /* Hide in print */
  @media print {
    .sidebar-container {
      display: none !important;
    }
  }
</style>
