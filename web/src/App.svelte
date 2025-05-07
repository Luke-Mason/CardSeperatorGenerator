<script lang="ts">
  import svelteLogo from './assets/svelte.svg'
  import viteLogo from '/vite.svg'
  
  const doubleSided = false;
  const notched = false;
  const showCardName = false;
  const showSetId = true;
  const showCardId = true;
  
  const titleWidthMM = 25;
  const titleHeightMM = 5;

  const widthMM = 65;
  const heightMM = 95;
  
  const cardSetId = "OP-01"

  const cards = Array.from({ length: 122 }, (_, i) => ({ setId: cardSetId, id: String(i + 1).padStart(3, '0') }));
</script>

<main>
<div class="p-4 bg-gray-100 print:bg-white print:p-0 min-h-screen">
  <div class="grid gap-4 justify-center print:gap-0 print:justify-start"
       style={`grid-template-columns: repeat(auto-fit, minmax(${widthMM}mm, 1fr));`}>
      {#each cards as card}
        <div class="bg-white shadow-md" style={`width: ${widthMM}mm; height: ${heightMM}mm;`}>
          <div class="outline-text flex place-content-between" style={`width: ${titleWidthMM}mm; height: ${titleHeightMM}mm;`}>
            <div>{card.setId}</div>
            <div>{card.id}</div>
          </div>
        </div>
      {/each}
    </div>
  </div>
</main>
 
<style>
  .outline-text {
    color: white;
    font-weight: 900;
    -webkit-text-stroke: 1px black; /* for supported browsers */
    text-shadow:
      -1px -1px 0 black,
      1px -1px 0 black,
      -1px  1px 0 black,
      1px  1px 0 black; /* fallback for others */
  }
</style>
