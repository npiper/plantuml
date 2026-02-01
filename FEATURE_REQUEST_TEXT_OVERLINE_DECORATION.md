# Feature Request: Text Overline Decoration Support

**Is your feature request related to a problem? Please describe.**

When rendering SVG text elements with `text-decoration="overline"` attribute, PlantUML currently ignores the overline decoration and renders the text without it. This is a limitation in PlantUML's `FontStyle` enumeration which only supports underline and strikethrough (line-through) decorations. As a result, SVG graphics that use overline for emphasis, mathematical notation, or styling purposes lose this formatting when rendered through PlantUML.

Current behavior in `SvgDomParser.java`:
```java
private static FontConfiguration applyTextDecoration(FontConfiguration fontConfig, String textDecoration) {
    // ...
    // Handle underline
    if (textDecoration.contains("underline")) {
        fontConfig = fontConfig.add(FontStyle.UNDERLINE);
    }
    
    // Handle line-through (strikethrough)
    if (textDecoration.contains("line-through")) {
        fontConfig = fontConfig.add(FontStyle.STRIKE);
    }
    
    // Note: overline not supported in PlantUML's FontStyle
    
    return fontConfig;
}
```

**Describe the solution you'd like**

Add full support for the CSS `overline` text decoration throughout PlantUML's text rendering system. The solution should:

1. **Add OVERLINE to FontStyle enum**:
   - New enum value: `FontStyle.OVERLINE`
   - Complement existing `UNDERLINE` and `STRIKE` values

2. **Parse overline from SVG**:
   - Recognize `text-decoration="overline"` in SVG `<text>` elements
   - Recognize `text-decoration="underline overline"` (multiple decorations)
   - Apply to `FontConfiguration` via `fontConfig.add(FontStyle.OVERLINE)`

3. **Render overline decoration**:
   - PNG/JPEG: Draw line above text baseline at appropriate height
   - SVG: Generate `text-decoration="overline"` in output
   - Other formats: Implement or document limitation

4. **PlantUML syntax support** (optional enhancement):
   - Extend PlantUML's native text formatting to support overline
   - Example: `<overline>text</overline>` or similar syntax

**Hypothesized Implementation:**

### Classes to Modify:

1. **`FontStyle.java`** (klimt.font package):
   - Add new enum constant: `OVERLINE`
   - Update any switch statements or enum iteration to handle new value
   ```java
   public enum FontStyle {
       PLAIN, ITALIC, BOLD, UNDERLINE, STRIKE, WAVE, BACKCOLOR, OVERLINE;
       // ...existing methods...
   }
   ```

2. **`SvgDomParser.java`** (emoji package):
   - Modify `applyTextDecoration()` method to handle overline:
   ```java
   // Handle overline
   if (textDecoration.contains("overline")) {
       fontConfig = fontConfig.add(FontStyle.OVERLINE);
   }
   ```

3. **`FontConfiguration.java`** (klimt.font package):
   - Verify `add(FontStyle)` method properly handles OVERLINE
   - Ensure immutability and proper style composition

4. **Text rendering classes** (klimt.drawing package):
   - **`UGraphicG2d.java`**: 
     * Modify text drawing to render overline when `FontStyle.OVERLINE` present
     * Calculate overline position: typically 1-2 pixels above cap height
     * Use same color and thickness as underline for consistency
   
   - **`UGraphicSvg.java`**:
     * Generate `text-decoration="overline"` attribute in SVG output
     * Handle combination: `text-decoration="underline overline line-through"`
   
   - **Other backends**: 
     * Update EPS, PDF, LaTeX generators to support overline if feasible
     * Document limitation if not supported in specific format

5. **`CreoleParser.java`** (creole package) - OPTIONAL:
   - Add native PlantUML syntax for overline (if desired)
   - Example: `<overline>text</overline>` or `<o>text</o>`
   - Consistent with existing `<u>underline</u>`, `<s>strike</s>` syntax

### Example SVG Input:
```xml
<text x="10" y="50" font-family="Arial" font-size="14" 
      text-decoration="overline" fill="black">
  Important Text
</text>

<text x="10" y="100" font-family="Arial" font-size="14" 
      text-decoration="underline overline" fill="blue">
  Heavily Emphasized
</text>
```

### Expected Result:
- First text: "Important Text" with line above
- Second text: "Heavily Emphasized" with lines both above and below

### Java2D Rendering Logic (Pseudocode):
```java
if (fontStyle.contains(FontStyle.OVERLINE)) {
    FontMetrics metrics = g2d.getFontMetrics();
    int overlineY = y - metrics.getAscent() - 2;  // Above cap height
    int overlineThickness = 1;
    g2d.fillRect(x, overlineY, textWidth, overlineThickness);
}
```

**Describe alternatives you've considered**

1. **Continue without overline support** (current approach):
   - ✅ No changes needed, simpler codebase
   - ❌ Incomplete SVG text decoration support
   - ❌ Users cannot achieve overline effect

2. **Use underline as substitute**:
   - ✅ Already supported
   - ❌ Visually incorrect, changes meaning
   - ❌ Confusing for mathematical notation

3. **Pre-process SVG externally**:
   - Convert overline to custom graphics elements before PlantUML
   - ❌ Extra tooling required, poor workflow
   - ❌ Loses semantic meaning of text decoration

4. **Use custom sprites with overline pre-rendered**:
   - Create raster images with overline already applied
   - ❌ Not scalable, loses text searchability
   - ❌ Cannot dynamically style or recolor text

**Additional context**

- **CSS Specification**: The `text-decoration` property supports: `none | underline | overline | line-through | blink` (CSS 2.1)
- **Common use cases**:
  - Mathematical notation: overline for repeating decimals (0.3̅), complex conjugates
  - East Asian typography: emphasis marks
  - Legal documents: specific emphasis styles
  - Design/branding: stylistic choices in logos and headers

- **PlantUML's existing text decorations**:
  - `<u>text</u>` → Underline (maps to `FontStyle.UNDERLINE`)
  - `<s>text</s>` → Strikethrough (maps to `FontStyle.STRIKE`)
  - `<w>text</w>` → Wave underline (maps to `FontStyle.WAVE`)
  - Missing: Overline equivalent

- **Java2D support**: Standard `Graphics2D` can easily draw lines above text using font metrics
- **SVG support**: Native `text-decoration="overline"` is part of SVG 1.1 spec

**Complexity Estimate:**
- **Low to Moderate** - Well-defined scope, follows existing pattern for UNDERLINE/STRIKE
- Estimated effort: 8-15 hours (enum addition, parser update, renderer modifications, cross-format testing)

**Priority Recommendation:**
- **Low to Medium** - Completes text decoration feature set, but not commonly used
- Higher priority if PlantUML targets mathematical diagrams or Asian language support
- Nice-to-have for SVG fidelity and CSS completeness

**Potential Risks:**
- Rendering position calculation may vary across fonts (need proper font metrics)
- Some output formats (e.g., ASCII art) cannot support overline
- Multi-line text may need special handling for overline positioning

---

> ⚠️ **AI-Generated Content Notice**: This feature request was generated with AI assistance based on code analysis of `SvgDomParser.java` and PlantUML's font rendering architecture. While the analysis references actual code patterns and follows PlantUML's existing text decoration implementation (UNDERLINE, STRIKE), some assertions about class names, rendering behavior, or implementation complexity may require verification through testing and deeper review of PlantUML's klimt graphics subsystem. The font metrics calculations and cross-format compatibility should be validated before implementation.
