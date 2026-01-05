<script lang="ts">
  import { saveConfig, type AppConfig, PAGE_SIZES } from './config';

  let { config = $bindable(), onClose } = $props<{
    config: AppConfig;
    onClose: () => void;
  }>();

  function handleSave() {
    saveConfig(config);
    onClose();
  }

  function handleCancel() {
    onClose();
  }
</script>

<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm" onclick={handleCancel}>
  <div class="bg-gray-800 rounded-lg shadow-2xl max-w-4xl w-full max-h-[90vh] overflow-y-auto m-4" onclick={(e) => e.stopPropagation()}>
    <!-- Header -->
    <div class="sticky top-0 bg-gray-800 border-b border-gray-700 p-6 flex items-center justify-between">
      <h2 class="text-2xl font-bold text-white">Configuration</h2>
      <button onclick={handleCancel} class="text-gray-400 hover:text-white">
        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
    </div>

    <div class="p-6 space-y-6">
      <!-- Card Dimensions -->
      <section>
        <h3 class="text-lg font-semibold text-white mb-4">Card Dimensions</h3>
        <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
          <div>
            <label class="block text-sm font-medium text-gray-300 mb-2">Width (mm)</label>
            <input
              type="number"
              bind:value={config.cardDimensions.width}
              class="w-full px-3 py-2 bg-gray-700 text-white rounded border border-gray-600 focus:border-blue-500 focus:outline-none"
              min="10"
              max="200"
            />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-300 mb-2">Height (mm)</label>
            <input
              type="number"
              bind:value={config.cardDimensions.height}
              class="w-full px-3 py-2 bg-gray-700 text-white rounded border border-gray-600 focus:border-blue-500 focus:outline-none"
              min="10"
              max="300"
            />
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-300 mb-2">Tab Height (mm)</label>
            <input
              type="number"
              bind:value={config.cardDimensions.tabHeight}
              class="w-full px-3 py-2 bg-gray-700 text-white rounded border border-gray-600 focus:border-blue-500 focus:outline-none"
              min="5"
              max="50"
            />
          </div>
        </div>
      </section>

      <!-- Page Size -->
      <section>
        <h3 class="text-lg font-semibold text-white mb-4">Page Size</h3>
        <div class="grid grid-cols-2 md:grid-cols-4 gap-4">
          {#each Object.entries(PAGE_SIZES) as [key, size]}
            <button
              onclick={() => {
                config.pageSize = key as any;
                config.pageDimensions = size;
              }}
              class={`px-4 py-3 rounded font-medium transition-colors ${
                config.pageSize === key
                  ? 'bg-blue-600 text-white'
                  : 'bg-gray-700 text-gray-300 hover:bg-gray-600'
              }`}
            >
              {key.toUpperCase()}
              <div class="text-xs opacity-75">{size.width}×{size.height}mm</div>
            </button>
          {/each}
        </div>

        {#if config.pageSize === 'custom'}
          <div class="grid grid-cols-2 gap-4 mt-4">
            <div>
              <label class="block text-sm font-medium text-gray-300 mb-2">Width (mm)</label>
              <input
                type="number"
                bind:value={config.pageDimensions.width}
                class="w-full px-3 py-2 bg-gray-700 text-white rounded border border-gray-600 focus:border-blue-500 focus:outline-none"
              />
            </div>
            <div>
              <label class="block text-sm font-medium text-gray-300 mb-2">Height (mm)</label>
              <input
                type="number"
                bind:value={config.pageDimensions.height}
                class="w-full px-3 py-2 bg-gray-700 text-white rounded border border-gray-600 focus:border-blue-500 focus:outline-none"
              />
            </div>
          </div>
        {/if}
      </section>

      <!-- Colors -->
      <section>
        <h3 class="text-lg font-semibold text-white mb-4">Colors</h3>
        <div class="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div>
            <label class="block text-sm font-medium text-gray-300 mb-2">Primary Color</label>
            <div class="flex gap-2">
              <input
                type="color"
                bind:value={config.colors.primary}
                class="w-12 h-10 bg-gray-700 rounded border border-gray-600 cursor-pointer"
              />
              <input
                type="text"
                bind:value={config.colors.primary}
                class="flex-1 px-3 py-2 bg-gray-700 text-white rounded border border-gray-600 focus:border-blue-500 focus:outline-none font-mono"
                placeholder="#DC2626"
              />
            </div>
          </div>
          <div>
            <label class="block text-sm font-medium text-gray-300 mb-2">Secondary Color</label>
            <div class="flex gap-2">
              <input
                type="color"
                bind:value={config.colors.secondary}
                class="w-12 h-10 bg-gray-700 rounded border border-gray-600 cursor-pointer"
              />
              <input
                type="text"
                bind:value={config.colors.secondary}
                class="flex-1 px-3 py-2 bg-gray-700 text-white rounded border border-gray-600 focus:border-blue-500 focus:outline-none font-mono"
                placeholder="#B91C1C"
              />
            </div>
          </div>
        </div>
      </section>

      <!-- Print Options -->
      <section>
        <h3 class="text-lg font-semibold text-white mb-4">Print Options</h3>
        <div class="space-y-3">
          <label class="flex items-center gap-3">
            <input type="checkbox" bind:checked={config.doubleSided} class="w-5 h-5" />
            <div>
              <div class="text-sm font-medium text-white">Double-Sided Printing</div>
              <div class="text-xs text-gray-400">Print separators on both sides</div>
            </div>
          </label>

          {#if config.doubleSided}
            <div class="ml-8">
              <label class="block text-sm font-medium text-gray-300 mb-2">Flip Edge</label>
              <select bind:value={config.flipEdge} class="px-3 py-2 bg-gray-700 text-white rounded border border-gray-600">
                <option value="long">Long Edge (Book-style)</option>
                <option value="short">Short Edge (Calendar-style)</option>
              </select>
            </div>
          {/if}

          <label class="flex items-center gap-3">
            <input type="checkbox" bind:checked={config.showImages} class="w-5 h-5" />
            <div>
              <div class="text-sm font-medium text-white">Show Card Images</div>
              <div class="text-xs text-gray-400">Display card artwork on separators</div>
            </div>
          </label>

          {#if config.showImages}
            <div class="ml-8">
              <label class="block text-sm font-medium text-gray-300 mb-2">Image Quality</label>
              <select bind:value={config.imageQuality} class="px-3 py-2 bg-gray-700 text-white rounded border border-gray-600">
                <option value="thumbnail">Thumbnail (300px - Fastest)</option>
                <option value="medium">Medium (600px - Balanced)</option>
                <option value="full">Full (1200px - High Quality)</option>
                <option value="original">Original (Slowest)</option>
              </select>
            </div>
          {/if}

          <label class="flex items-center gap-3">
            <input type="checkbox" bind:checked={config.showCutLines} class="w-5 h-5" />
            <div>
              <div class="text-sm font-medium text-white">Show Cut Lines</div>
              <div class="text-xs text-gray-400">Display cutting guides and crop marks (print only)</div>
            </div>
          </label>
        </div>
      </section>
    </div>

    <!-- Footer -->
    <div class="sticky bottom-0 bg-gray-800 border-t border-gray-700 p-6 flex items-center justify-end gap-3">
      <button
        onclick={handleCancel}
        class="px-6 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded font-medium transition-colors"
      >
        Cancel
      </button>
      <button
        onclick={handleSave}
        class="px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded font-medium transition-colors"
      >
        Save & Apply
      </button>
    </div>
  </div>
</div>
