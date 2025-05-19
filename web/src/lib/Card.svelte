<script>
 let { card, titleHeightMM, titleWidthMM } = $props() 
</script>


<div
  class="bg-white"
  style={`width: ${card.width}mm; height: ${card.height}mm;`}
>
  <div
    class="outline-text flex place-content-between"
    style={`line-height: ${titleHeightMM - 1}mm;width: ${titleWidthMM}mm; height: ${titleHeightMM}mm;`}
  >
    <div>{card.setId}</div>
    <div>{card.id}</div>
  </div>
</div>
