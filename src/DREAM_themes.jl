using Makie

DREAM = RGBf((245, 82, 82) ./ 255...) # Red (DREAM)
MAKRO = RGBf((20, 175, 166) ./ 255...) # Pretrolium (MAKRO)
SMILE = RGBf((255, 155, 75) ./ 255...) # Orange (SMILE)
GREEN = RGBf((92, 210, 114) ./ 255...) # Green (Grøn REFORM)
BLUE = RGBf((66, 180, 224) ./ 255...) # Blue (REFORM)
PLUM = RGBf((188, 173, 221) ./ 255...) # Plum
DARK_BLUE = RGBf((0, 95, 151) ./ 255...) # Dark blue
MAROON = RGBf((137, 48, 112) ./ 255...) # Maroon
DARK_GRAY = RGBf((70, 70, 76) ./ 255...) # Dark gray
LIGHT_GRAY = RGBf((230, 230, 232) ./ 255...) # Light gray
DREAM_COLORS = [DREAM, MAKRO, SMILE, GREEN, BLUE, PLUM, DARK_BLUE, MAROON, DARK_GRAY, LIGHT_GRAY]

set_theme!(palette = (color=DREAM_COLORS,))