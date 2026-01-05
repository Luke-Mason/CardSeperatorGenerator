<script lang="ts">
  import type { AppConfig } from './config';
  import { loadConfig, saveConfig } from './config';

  type Preset = {
    name: string;
    config: AppConfig;
    createdAt: string;
  };

  let { onApply, onClose } = $props<{
    onApply: (config: AppConfig) => void;
    onClose: () => void;
  }>();

  const PRESETS_KEY = 'card-separator-presets';

  let presets = $state<Preset[]>([]);
  let presetName = $state('');
  let selectedPreset = $state<Preset | null>(null);

  function loadPresets() {
    try {
      const stored = localStorage.getItem(PRESETS_KEY);
      if (stored) {
        presets = JSON.parse(stored);
      }
    } catch (e) {
      console.error('Failed to load presets:', e);
    }
  }

  function savePresets() {
    try {
      localStorage.setItem(PRESETS_KEY, JSON.stringify(presets));
    } catch (e) {
      console.error('Failed to save presets:', e);
    }
  }

  function saveCurrentAsPreset() {
    if (!presetName.trim()) return;

    const currentConfig = loadConfig();
    const preset: Preset = {
      name: presetName.trim(),
      config: currentConfig,
      createdAt: new Date().toISOString()
    };

    presets = [...presets, preset];
    savePresets();
    presetName = '';
  }

  function applyPreset(preset: Preset) {
    saveConfig(preset.config);
    onApply(preset.config);
    onClose();
  }

  function deletePreset(index: number) {
    presets = presets.filter((_, i) => i !== index);
    savePresets();
  }

  function exportPreset(preset: Preset) {
    const json = JSON.stringify(preset, null, 2);
    const blob = new Blob([json], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `${preset.name.replace(/\s+/g, '-').toLowerCase()}.json`;
    a.click();
    URL.revokeObjectURL(url);
  }

  function importPreset(e: Event) {
    const input = e.target as HTMLInputElement;
    const file = input.files?.[0];
    if (!file) return;

    const reader = new FileReader();
    reader.onload = (e) => {
      try {
        const preset = JSON.parse(e.target?.result as string) as Preset;
        presets = [...presets, preset];
        savePresets();
      } catch (error) {
        alert('Invalid preset file');
      }
    };
    reader.readAsText(file);
  }

  loadPresets();
</script>

<div class="fixed inset-0 z-50 flex items-center justify-center bg-black/50 backdrop-blur-sm" onclick={onClose}>
  <div class="bg-gray-800 rounded-lg shadow-2xl max-w-2xl w-full max-h-[90vh] overflow-y-auto m-4" onclick={(e) => e.stopPropagation()}>
    <!-- Header -->
    <div class="sticky top-0 bg-gray-800 border-b border-gray-700 p-6 flex items-center justify-between">
      <h2 class="text-2xl font-bold text-white">Configuration Presets</h2>
      <button onclick={onClose} class="text-gray-400 hover:text-white">
        <svg class="w-6 h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
        </svg>
      </button>
    </div>

    <div class="p-6 space-y-6">
      <!-- Save Current Config -->
      <section class="bg-gray-700 rounded-lg p-4">
        <h3 class="text-lg font-semibold text-white mb-3">Save Current Configuration</h3>
        <div class="flex gap-3">
          <input
            type="text"
            bind:value={presetName}
            placeholder="Preset name (e.g., 'Standard OP-01')"
            class="flex-1 px-3 py-2 bg-gray-600 text-white rounded border border-gray-500 focus:border-blue-500 focus:outline-none"
            onkeydown={(e) => e.key === 'Enter' && saveCurrentAsPreset()}
          />
          <button
            onclick={saveCurrentAsPreset}
            disabled={!presetName.trim()}
            class="px-4 py-2 bg-blue-600 hover:bg-blue-700 disabled:bg-gray-600 text-white rounded font-medium transition-colors"
          >
            Save
          </button>
        </div>
      </section>

      <!-- Import/Export -->
      <section class="flex gap-3">
        <label class="flex-1 px-4 py-2 bg-gray-700 hover:bg-gray-600 text-white rounded font-medium text-center cursor-pointer transition-colors">
          Import Preset
          <input type="file" accept=".json" class="hidden" onchange={importPreset} />
        </label>
      </section>

      <!-- Saved Presets -->
      <section>
        <h3 class="text-lg font-semibold text-white mb-3">Saved Presets ({presets.length})</h3>

        {#if presets.length === 0}
          <div class="text-center py-8 text-gray-400">
            <p>No presets saved yet.</p>
            <p class="text-sm mt-2">Save your current configuration above to get started.</p>
          </div>
        {:else}
          <div class="space-y-3">
            {#each presets as preset, i}
              <div class="bg-gray-700 rounded-lg p-4">
                <div class="flex items-start justify-between mb-2">
                  <div>
                    <h4 class="font-semibold text-white">{preset.name}</h4>
                    <p class="text-xs text-gray-400 mt-1">
                      Created: {new Date(preset.createdAt).toLocaleDateString()}
                    </p>
                  </div>
                  <div class="flex gap-2">
                    <button
                      onclick={() => exportPreset(preset)}
                      class="px-3 py-1 bg-gray-600 hover:bg-gray-500 text-white rounded text-sm transition-colors"
                      title="Export"
                    >
                      ↓
                    </button>
                    <button
                      onclick={() => deletePreset(i)}
                      class="px-3 py-1 bg-red-600 hover:bg-red-700 text-white rounded text-sm transition-colors"
                      title="Delete"
                    >
                      ✕
                    </button>
                  </div>
                </div>

                <div class="text-sm text-gray-300 space-y-1">
                  <div class="flex gap-4">
                    <span>Card: {preset.config.cardDimensions.width}×{preset.config.cardDimensions.height}mm</span>
                    <span>Page: {preset.config.pageSize.toUpperCase()}</span>
                    <span>{preset.config.doubleSided ? 'Double-Sided' : 'Single-Sided'}</span>
                  </div>
                </div>

                <button
                  onclick={() => applyPreset(preset)}
                  class="mt-3 w-full px-4 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded font-medium transition-colors"
                >
                  Apply Preset
                </button>
              </div>
            {/each}
          </div>
        {/if}
      </section>
    </div>
  </div>
</div>
