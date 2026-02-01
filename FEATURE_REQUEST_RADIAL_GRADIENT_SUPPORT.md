# Feature Request: Full Radial Gradient Support in SVG Rendering

**Is your feature request related to a problem? Please describe.**

When rendering SVG graphics that contain radial gradients (e.g., `<radialGradient>` elements), PlantUML currently only extracts and uses the first stop color as a solid fill. This means that radial gradients are rendered as flat colors, losing the visual depth and shading effects intended by the SVG author. This limitation affects emoji sprites, icons, and other SVG graphics that rely on radial gradients for realistic rendering (e.g., shading on spherical objects, spotlight effects, vignettes).

Current behavior in `SvgDomParser.java`:
```java
// Handle radialGradient - just use first stop color
if ("radialGradient".equals(tagName)) {
    final NodeList stops = gradientElement.getElementsByTagName("stop");
    if (stops.getLength() > 0) {
        final Element firstStop = (Element) stops.item(0);
        final String stopColor = firstStop.getAttribute("stop-color");
        if (stopColor != null && !stopColor.isEmpty()) {
            return parseColor(stopColor);  // Returns solid color, not gradient
        }
    }
}
```

**Describe the solution you'd like**

Implement full radial gradient support in PlantUML's rendering system, similar to how linear gradients are currently handled. The solution should:

1. **Parse radial gradient parameters** from SVG:
   - Center point (`cx`, `cy`)
   - Radius (`r`)
   - Focal point (`fx`, `fy`) for offset gradients
   - Gradient stops with colors and opacity

2. **Extend PlantUML's gradient system**:
   - Add radial gradient type to complement existing linear gradients
   - Create `HColorRadialGradient` class (analogous to existing gradient classes)
   - Support gradient transformations (if specified in SVG)

3. **Extend PlantUML DSL syntax** for radial gradients:
   - Use **`*`** (star/asterisk) or **`@`** (at symbol) as the gradient policy character for radial gradients
   - Follow existing linear gradient syntax pattern: `#color1*color2` or `#color1@color2`
   - Examples:
     - `#FFFFFF*#4A90E2` - White center to blue edge (radial)
     - `participant Bob #red*yellow` - Red center to yellow edge
     - `rectangle "Item" #lightblue@darkblue` - Light center to dark edge
   - This complements existing linear gradient syntax:
     - `#color1|color2` - Horizontal gradient (left to right)
     - `#color1-color2` - Vertical gradient (top to bottom)
     - `#color1\color2` - Diagonal gradient (top-left to bottom-right)
     - `#color1/color2` - Diagonal gradient (bottom-left to top-right)

4. **Render radial gradients** in output formats:
   - PNG/JPEG: Use Java2D's `RadialGradientPaint` for accurate rendering
   - SVG: Preserve original `<radialGradient>` definitions in output
   - Other formats: Degrade gracefully (use center color as fallback)

**Hypothesized Implementation:**

### Classes to Modify:
1. **`SvgDomParser.java`** (emoji package):
   - Modify `extractGradientColor()` method to create radial gradient objects
   - Parse `cx`, `cy`, `r`, `fx`, `fy` attributes from `<radialGradient>` elements
   - Parse multiple gradient stops (not just first)
   - Return `HColorRadialGradient` instead of solid color

2. **`HColors.java`** (klimt.color package):
   - Add new method: `HColorRadialGradient radial(HColor center, HColor edge, double cx, double cy, double radius)`
   - Factory method for creating radial gradient instances

3. **`HColorRadialGradient.java`** (NEW - klimt.color package):
   - New class implementing radial gradient color representation
   - Store center point, radius, focal point, and color stops
   - Implement `HColor` interface for compatibility

4. **Graphics output classes** (klimt.drawing package):
   - **`UGraphicG2d.java`**: Use Java2D `RadialGradientPaint` for PNG rendering
   - **`UGraphicSvg.java`**: Generate proper `<radialGradient>` SVG elements
   - Other output backends: Implement or fallback to solid color

### Example SVG Input:
```xml
<defs>
  <radialGradient id="sphere" cx="50%" cy="50%" r="50%" fx="30%" fy="30%">
    <stop offset="0%" stop-color="#FFFFFF" stop-opacity="0.8"/>
    <stop offset="50%" stop-color="#4A90E2" stop-opacity="1"/>
    <stop offset="100%" stop-color="#1A3A6E" stop-opacity="1"/>
  </radialGradient>
</defs>
<circle cx="100" cy="100" r="50" fill="url(#sphere)"/>
```

### Expected Result:
Circle rendered with realistic spherical shading from white highlight (at 30%, 30%) through blue to dark blue at edges.

**Describe alternatives you've considered**

1. **Continue using first stop color** (current approach):
   - ✅ Simple, no code changes needed
   - ❌ Loses visual fidelity, gradients look flat

2. **Average all stop colors**:
   - ✅ Better than first-only, considers all colors
   - ❌ Still produces flat color, loses gradient effect

3. **Convert radial to linear gradient** (approximate):
   - ✅ Reuses existing linear gradient code
   - ❌ Visual approximation is poor for radial patterns
   - ❌ Confusing for users (circles wouldn't look round)

4. **External preprocessing**:
   - Convert SVG radial gradients to raster images before PlantUML
   - ❌ Extra tooling required, loses vector benefits
   - ❌ Poor workflow integration

**Additional context**

- Linear gradients are already supported via `HColors.gradient(color1, color2, policy)` with policies: `|` (horizontal), `-` (vertical), `\` and `/` (diagonal)
- Java2D provides `RadialGradientPaint` class since Java 6, so rendering infrastructure exists
- SVG specification defines radial gradients in detail: https://www.w3.org/TR/SVG11/psSvgDOM.html#RadialGradients
- Common use cases: Material design icons, 3D-looking buttons, realistic emoji shading, vignette effects

**Complexity Estimate:**
- **Moderate** - Requires new gradient type but can follow existing linear gradient patterns
- Estimated effort: 15-25 hours (parser updates, new classes, renderer modifications, testing)

**Priority Recommendation:**
- **Medium** - Improves visual quality but not blocking functionality
- Most users can work around with solid colors or pre-rendered images
- High value for design-focused diagrams and modern icon sets

---

> ⚠️ **AI-Generated Content Notice**: This feature request was generated with AI assistance based on code analysis of `SvgDomParser.java`. While the analysis is based on actual code patterns and PlantUML architecture, some assertions about implementation details, class names, or rendering behavior may require further verification through testing and review of PlantUML's internal architecture. Please validate technical details before implementation.
