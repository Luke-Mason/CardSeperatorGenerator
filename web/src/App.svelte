<script lang="ts">
  import svelteLogo from './assets/svelte.svg'
  import viteLogo from '/vite.svg'
  import Card from './lib/Card.svelte'

  const doubleSided = true;
  const notched = false;
  const showCardName = false;
  const showSetId = true;
  const showCardId = true;
  
  const titleWidthMM = 25;
  const titleHeightMM = 5;

  const widthMM = 65;
  const heightMM = 95;

  const pageWidthMM = 210;
  const pageHeightMM = 297;
  
  const cardSetId = "OP-01"

  const cards = Array.from({ length: 122 }, (_, i) => ({ width: widthMM, height: heightMM, setId: cardSetId, id: String(i + 1).padStart(3, '0') }));


  const cardsPerRow = Math.floor(pageWidthMM / widthMM);
  const rowsPerPage = Math.floor(pageHeightMM / heightMM);
  const cardsPerPage = cardsPerRow * rowsPerPage;

  function chunkCards(array, size) {
    const chunks = [];
    for (let i = 0; i < array.length; i += size) {
      chunks.push(array.slice(i, i + size));
    }
    return chunks;
  }

  $: frontPages = chunkCards(cards, cardsPerPage - 1);
  $: backPages = doubleSided
    ? frontPages.map(page => [...page].reverse()) // mirror back
    : [];
</script>

<main>
  <div class="p-0 bg-gray-100 print:bg-white print:p-0 min-h-screen">
    {#each frontPages as page, i}
      <div
        class="grid gap-0 justify-start break-after-page print:gap-0 print:justify-start"
        style={`grid-template-columns: repeat(auto-fit, ${widthMM}mm);`}
      >
        {#each page as card}
          <Card card={card} titleHeightMM={titleHeightMM} titleWidthMM={titleWidthMM} />
        {/each}
      </div>
    {/each}
    {#if doubleSided}
      {#each backPages as page, i}
        <div
          class="grid gap-0 justify-start break-after-page print:gap-0 print:justify-start"
          style={`grid-template-columns: repeat(auto-fit, ${widthMM}mm);`}
        >
          {#each page as card}
            <Card card={card} titleHeightMM={titleHeightMM} titleWidthMM={titleWidthMM} />
          {/each}
        </div>
      {/each}
    {/if}
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
