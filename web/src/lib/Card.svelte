<script>
  let { card, titleHeightMM, titleWidthMM } = $props();

  // Define some dynamic sizes based on titleHeightMM for responsiveness within the banner
  // These are multipliers, adjust them to your liking
  const costCircleDiameter = titleHeightMM * 1.2; // e.g., 120% of title height
  const costCircleBorder = titleHeightMM * 0.05; // e.g. 0.5mm if titleHeight is 10mm
  const nameTextStroke = 0.6
  const setIdTextStroke = 0.6;

  // Clip path points (percentages or mm values)
  // These define the shape of the main red banner
  // Format: polygon(topLeftX topLeftY, topRightX topRightY, bottomRightX bottomRightY, bottomLeftX bottomLeftY)
  // We want the left side to be 'cut' to accommodate the cost circle and have an angle
  // And the right side to have an angle.
  const clipPathPoints = `polygon(
    ${costCircleDiameter * 0.35}mm 0%,      /* Top-left point, after cost circle */
    calc(100% - ${titleHeightMM * 0.4}mm) 0%,  /* Top-right, before angle */
    100% 100%,                            /* Bottom-right */
    ${titleHeightMM * 0.15}mm 100%         /* Bottom-left, before angle */
  )`;

  // Padding for the banner content to not overlap with the cost circle visual
  const bannerPaddingLeft = 2;
  const bannerPaddingRight = 2;

</script>
<div
  class="bg-white outline flex"
  style={`width: ${card.width}mm; height: ${card.height}mm;`}
>
<div
  class="card-title-wrapper"
  style={`
    width: 50mm;
    height: ${titleHeightMM}mm;
  `}
>
  <!-- Cost Circle -->
  <div
    class="cost-display"
    style={`
      width: ${costCircleDiameter}mm;
      height: ${costCircleDiameter}mm;
      background-color: #B91C1C; /* Slightly darker red (Tailwind red-700) */
      box-shadow: 0 0 0 ${costCircleBorder}mm white; /* White outline */
    `}
  >
    {card.cost}
  </div>

  <!-- Main Tite Banner -->
  <div
    class="title-banner"
    style={`
      clip-path: ${clipPathPoints};
      background-color: #DC2626; /* Red (Tailwind red-600) */
      padding-left: ${bannerPaddingLeft}mm;
      padding-right: ${bannerPaddingRight}mm;
    `}
  >
    <div
      class="name"
      style={`
        -webkit-text-stroke: ${nameTextStroke}mm black;
        // text-shadow: ${nameTextStroke}mm ${nameTextStroke}mm 0 black, -${nameTextStroke}mm -${nameTextStroke}mm 0 black, ${nameTextStroke}mm -${nameTextStroke}mm 0 black, -${nameTextStroke}mm ${nameTextStroke}mm 0 black;
      `}
    >
      {card.name}
    </div>
    <div
      class="set-id"
      style={`
        -webkit-text-stroke: ${setIdTextStroke}mm black;
        // text-shadow: ${setIdTextStroke}mm ${setIdTextStroke}mm 0 black, -${setIdTextStroke}mm -${setIdTextStroke}mm 0 black, ${setIdTextStroke}mm -${setIdTextStroke}mm 0 black, -${setIdTextStroke}mm ${setIdTextStroke}mm 0 black;
      `}
    >
      {card.setId}
    </div>
  </div>
  <div>
    {card.id}
  </div>
</div>
</div>
<style>
  .card-title-wrapper {
    position: relative; /* Crucial for absolute positioning of children */
    font-family: Impact, Haettenschweiler, 'Arial Narrow Bold', sans-serif; /* Example TCG-like font */
    color: white;
    line-height: 1; /* Important for precise text height control */
  }

  .cost-display {
    position: absolute;
    top: 50%;
    transform: translateY(-50%);
    border-radius: 50%;
    display: flex;
    align-items: center;
    justify-content: center;
    font-weight: 900; /* Extra bold */
    z-index: 10; /* Ensure it's on top */
    color: white;
  }

  .title-banner {
    position: absolute;
    top: 0;
    left: 0;
    width: 100%;
    height: 100%;
    display: flex;
    align-items: center;
    justify-content: space-between; /* Pushes name and set-id apart */
    box-sizing: border-box;
  }

  .name {
    font-weight: 900; /* Extra bold */
    text-align: center;
    flex-grow: 1; /* Allows name to take available space */
    margin-right: 1mm; /* Space before set-id */
     /* Fallback for text stroke for browsers not supporting -webkit-text-stroke well for small strokes */
    paint-order: stroke fill; /* Makes -webkit-text-stroke cleaner */
  }

  .set-id {
    font-weight: bold;
    text-align: right;
    white-space: nowrap; /* Prevent wrapping */
    paint-order: stroke fill;
  }
</style>