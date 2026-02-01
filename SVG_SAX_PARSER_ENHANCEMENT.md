# Enhancement: Zero-Dependency SAX-based SVG Parser

## Overview

Create `SvgSaxParser` as an alternative SVG parsing implementation using only Java SDK components (no external dependencies). This would complement the existing `SvgDomParser` which uses Apache Batik.

## Motivation

While the current `SvgDomParser` works well with Batik dependencies managed via Maven Central auto-download, a pure Java SDK implementation offers several advantages:

- **Zero external dependencies** - No Batik JARs required (eliminates 4.2MB download)
- **Memory efficiency** - Event-driven SAX streaming vs. in-memory DOM tree
- **Build simplicity** - Works on any Java 8+ system without network access
- **Faster parsing** - Lower overhead for large SVG files
- **Philosophy alignment** - Matches PlantUML's "lightweight, minimal dependencies" design principle

## Technical Approach

### Core Technology

Use Java SDK's built-in SAX parser (available since Java 1.4):
```java
import org.xml.sax.XMLReader;
import org.xml.sax.helpers.DefaultHandler;
import javax.xml.parsers.SAXParser;
import javax.xml.parsers.SAXParserFactory;
```

### Implementation Strategy

**Two-pass parsing architecture:**

1. **Pass 1 - Collect Definitions:** Parse `<defs>`, `<symbol>`, `<linearGradient>`, `<radialGradient>` and store by ID
2. **Pass 2 - Render Elements:** Process shape elements, resolve `<use>` references, apply transforms and styles

**State management:**
- Manual stack for nested `<g>` group states (transforms, styles)
- Accumulator for `<text>` element content
- Map for forward reference resolution (`<use href="#later">`)

### Code Reuse Opportunities

**~60% of existing SvgDomParser logic can be extracted and reused:**

✅ **Transform parsing** (~200 lines):
- `getTranslate()`, `getScale()`, `applyRotate()`, `applyMatrix()`
- Regex patterns: `P_TRANSLATE1`, `P_ROTATE`, `P_SCALE1`, `P_MATRIX`

✅ **Style parsing** (~150 lines):
- `parseStyle()`, `parseFontSize()`, `parseFontStyle()`, `applyTextDecoration()`
- Color and gradient utilities: `parseColor()`, `determineGradientPolicy()`

✅ **Path rendering** (delegate):
- Reuse existing `SvgPath` class for path data parsing

**~40% requires new implementation:**
- SAX event handlers (`startElement`, `endElement`, `characters`)
- Element buffering for definitions
- Attribute extraction from SAX `Attributes` object

### Architecture Sketch

```java
public class SvgSaxParser extends DefaultHandler implements ISvgParser, Sprite {
    
    // Pass 1: Definition collector
    private static class DefsCollector extends DefaultHandler {
        private final Map<String, BufferedElement> definitions = new HashMap<>();
        private boolean inDefs = false;
        // Collect <defs>, <symbol>, gradients by ID
    }
    
    // Pass 2: Rendering handler
    private static class RenderHandler extends DefaultHandler {
        private final UGraphicWithScale ugs;
        private final Map<String, BufferedElement> defs;
        private final Deque<GroupState> groupStack = new ArrayDeque<>();
        private StringBuilder textContent = new StringBuilder();
        
        @Override
        public void startElement(String uri, String localName, String qName, Attributes attrs) {
            switch (qName) {
                case "g": handleGroup(attrs); break;
                case "rect": handleRect(attrs); break;
                case "circle": handleCircle(attrs); break;
                case "path": handlePath(attrs); break;
                case "text": currentInText = true; break;
                case "use": handleUse(attrs); break;
                // ... other elements
            }
        }
        
        @Override
        public void characters(char[] ch, int start, int length) {
            if (currentInText) {
                textContent.append(ch, start, length);
            }
        }
        
        @Override
        public void endElement(String uri, String localName, String qName) {
            if ("g".equals(qName)) groupStack.pop();
            if ("text".equals(qName)) drawText(textContent.toString());
        }
    }
    
    @Override
    public void drawU(UGraphic ug, double scale, HColor fontColor, HColor forcedColor) {
        SAXParserFactory factory = SAXParserFactory.newInstance();
        SAXParser parser = factory.newSAXParser();
        
        // Pass 1: Collect definitions
        DefsCollector defsCollector = new DefsCollector();
        parser.parse(new InputSource(new StringReader(svg)), defsCollector);
        
        // Pass 2: Render
        RenderHandler renderer = new RenderHandler(ug, scale, defsCollector.definitions);
        parser.parse(new InputSource(new StringReader(svg)), renderer);
    }
}
```

## Implementation Estimate

### Effort Breakdown

| Task | Estimated Hours |
|------|----------------|
| Core SAX handler structure | 8 |
| Extract/refactor reusable utilities | 6 |
| Implement shape handlers (rect, circle, ellipse, line, etc.) | 10 |
| Text element handling with font attributes | 4 |
| Transform stack management | 4 |
| Definitions and `<use>` resolution | 6 |
| Gradient support | 3 |
| Testing (unit + integration) | 12 |
| Documentation | 2 |
| **Total** | **~55 hours** |

### Lines of Code

- Estimated 800-1200 LOC (similar to current SvgDomParser ~1000 LOC)
- Plus ~200 LOC for extracted utility class

## Feature Parity

**What SvgSaxParser would support:**

| Feature | SvgDomParser (Batik) | SvgSaxParser (SAX) |
|---------|---------------------|-------------------|
| Basic shapes (rect, circle, path, etc.) | ✅ | ✅ Planned |
| Text with font styling | ✅ | ✅ Planned |
| Transforms (translate, rotate, scale, matrix) | ✅ | ✅ Planned |
| Gradients (linear, radial) | ✅ | ✅ Planned |
| Groups with style inheritance | ✅ | ✅ Planned |
| Definitions and `<use>` | ✅ | ✅ Planned |
| Embedded images (PNG/JPEG) | ✅ | ✅ Planned |
| SVG in SVG (nested) | ❌ | ❌ Out of scope |
| Advanced features (clipPath, mask, filter) | ❌ | ❌ Out of scope |

## Benefits vs. Trade-offs

### Advantages

✅ **Zero dependencies** - No Batik, no xml-apis-ext (saves 4.2MB)  
✅ **Memory efficient** - No DOM tree in memory  
✅ **Faster parsing** - Event-driven streaming  
✅ **Offline builds** - No Maven Central downloads needed  
✅ **Simpler deployment** - Pure Java SDK solution  
✅ **Code reuse** - Extracts utilities beneficial to both parsers

### Trade-offs

⚠️ **Development time** - ~55 hours implementation  
⚠️ **Complexity** - Manual state management more complex than DOM navigation  
⚠️ **Debugging** - Event-driven flow harder to debug than DOM tree inspection  
⚠️ **Maintenance burden** - Two SVG parser implementations to maintain  
⚠️ **Spec brittleness** - Must manually track SVG specification changes (see below)  
⚠️ **Feature lag** - New SVG features require manual implementation vs. Batik auto-update  

## Recommendation

### When to Implement

Consider implementing SvgSaxParser if:
- Community requests zero-dependency option
- Performance issues arise with large SVG files (>1MB)
- Offline/airgapped build environments become priority
- Want to reduce dependency footprint for security/compliance

### When to Defer

Current SvgDomParser is sufficient if:
- ✅ Batik auto-download in Ant build works well
- ✅ DOM parsing performance meets needs
- ✅ 4.2MB dependency acceptable
- ✅ Limited development resources

## Maintenance & Brittleness Considerations

### SVG Specification Evolution Risk

One critical consideration: **SAX implementation is more brittle to maintain** when the SVG specification evolves.

#### SvgDomParser (Batik) - Specification Insulation

**How it handles spec changes:**
```
SVG Spec Update → Apache Batik Update → Bump version in libs.versions.toml → Done
```

**What Batik abstracts away:**
- ✅ XML namespace handling changes
- ✅ New SVG element definitions  
- ✅ Attribute validation and default values
- ✅ CSS parsing complexity and cascade rules
- ✅ Browser compatibility quirks
- ✅ Inheritance and style computation

**Example:** SVG 2.0 added `pathLength`, `paint-order`, `vector-effect` attributes. Batik handled these automatically with a version upgrade. **Zero code changes required.**

#### SvgSaxParser - Manual Specification Tracking

**How it handles spec changes:**
```
SVG Spec Update → Read changelog → Update SAX handlers → Write tests → Update docs
```

**What we must manually maintain:**
- ❌ Every supported element and attribute
- ❌ Validation rules (required vs. optional)
- ❌ Default values for missing attributes
- ❌ CSS selector specificity and cascade
- ❌ Namespace handling (xlink, SVG 2.0 changes)
- ❌ Style inheritance through element hierarchy

**Example impact of spec evolution:**

```java
// SVG 1.1: Simple text positioning
case "text":
    String x = attrs.getValue("x");
    String y = attrs.getValue("y");
    drawText(x, y, textContent);

// SVG 2.0: 7 new text attributes added!
case "text":
    String x = attrs.getValue("x");
    String y = attrs.getValue("y");
    String dx = attrs.getValue("dx");          // NEW: relative offset
    String dy = attrs.getValue("dy");          // NEW: relative offset  
    String textAnchor = attrs.getValue("text-anchor");  // NEW: alignment
    String textLength = attrs.getValue("textLength");   // NEW: constraint
    String lengthAdjust = attrs.getValue("lengthAdjust"); // NEW: spacing
    String rotate = attrs.getValue("rotate");   // NEW: glyph rotation
    String textPath = attrs.getValue("textPath"); // NEW: path following
    // Must implement all new complex logic ourselves!
```

### Real-World Maintenance Burden

**Annual maintenance estimates:**

| Task | SvgDomParser (Batik) | SvgSaxParser (Manual) |
|------|---------------------|----------------------|
| Dependency updates | ~30 min/year | N/A |
| Spec change tracking | 0 hours | ~2-3 hours/year |
| Feature additions | 0 hours | ~5-10 hours/year |
| Bug fixes (edge cases) | ~1 hour/year | ~3-5 hours/year |
| Breaking changes | ~1-2 hours every 2-3 years | ~8-15 hours every 2-3 years |
| **Annual average** | **~0.5-1 hour** | **~10-18 hours** |

**10-18x more maintenance effort** for SAX approach.

### SVG Specification Stability Assessment

**Good news - Core SVG is relatively stable:**

- **SVG 1.1** (2003-2011): Very stable foundation, widely implemented
- **SVG 2.0** (2016-present): Living standard, but **basic shapes unchanged**
- **Browser focus**: Primarily SVG 1.1 subset for compatibility
- **PlantUML use case**: Simple sprites and icons, not animations/filters

**Most spec changes are:**
- ✅ Additive (new features we can ignore)
- ✅ Clarifications (rare impact on implementations)
- ❌ Breaking changes to existing features (very rare)

**However**, even additive changes create maintenance debt if users expect new features to work.

### Brittleness Mitigation Strategies

If SAX implementation proceeds despite brittleness concerns:

1. **Explicit Feature Freeze Declaration:**
```java
/**
 * SVG 1.1 Core Subset Parser (Feature-Frozen)
 * 
 * Supports ONLY SVG 1.1 core features. Will NOT track SVG 2.0+ additions.
 * For full SVG 2.0 support, use SvgDomParser with Batik.
 */
public class SvgSaxParser { ... }
```

2. **Defensive Unknown Attribute Handling:**
```java
if (!KNOWN_SVG_1_1_ATTRIBUTES.contains(attrName)) {
    LOG.fine("Ignoring unknown/unsupported attribute: " + attrName);
    // Fail gracefully, don't break on new spec features
}
```

3. **W3C Test Suite Integration:**
```java
// Lock to official SVG 1.1 test suite
@ParameterizedTest
@ValueSource(strings = {"w3c-svg-1.1-testsuite/**/*.svg"})
void testW3CCompliance(String testFile) {
    // Prevents regression, defines exact supported subset
}
```

## Recommendation

### Strong Arguments for SvgDomParser (Current Implementation)

**The existing Batik-based implementation is a solid, maintainable choice because:**

1. ✅ **Dependency solved** - Ant auto-download from Maven Central works seamlessly
2. ✅ **Specification insulation** - Batik tracks SVG evolution, we don't
3. ✅ **Lower maintenance** - ~18x less annual effort than SAX approach
4. ✅ **Feature complete** - Full SVG 1.1 + SVG 2.0 support via Batik updates
5. ✅ **Battle-tested** - Batik used in Apache FOP, Eclipse BIRT, etc.
6. ✅ **4.2MB acceptable** - For the maintenance savings, the dependency is worth it
7. ✅ **Proven quality** - DOM parsing more reliable for complex SVG

**The original concern (Batik dependency) has been addressed:**
- Ant build auto-downloads from Maven Central
- Gradle already managed it perfectly
- Zero manual intervention required
- Works in CI/CD environments

### When to Consider SvgSaxParser

Implement SAX alternative **only if** there's a hard requirement:

❗ **Zero-dependency policy** - Compliance, security, or organizational mandate  
❗ **Extreme performance need** - Parsing >10MB SVG files routinely  
❗ **Airgapped environments** - Cannot access Maven Central (rare)  
❗ **Embedded systems** - 4.2MB Batik JAR too large for deployment  

**AND you accept these constraints:**
- ⚠️ Feature freeze at SVG 1.1 core subset
- ⚠️ 10-18 hours/year ongoing maintenance
- ⚠️ Willing to say "not supported" for advanced SVG features
- ⚠️ Dedicated developer time for spec tracking

### When to Defer (Recommended Default)

Stick with SvgDomParser if:

✅ Batik auto-download works (it does)  
✅ Performance acceptable for your use cases  
✅ 4.2MB dependency reasonable  
✅ Limited maintenance resources  
✅ Want automatic SVG spec evolution support  
✅ Prefer proven, battle-tested solution

**Current assessment: SvgDomParser is the right choice for 95% of use cases.**

## Implementation Plan

### Phase 1: Foundation (Week 1)
1. Extract reusable utilities to `SvgStyleParser` class
2. Create `SvgSaxParser` skeleton with basic SAX handlers
3. Implement Pass 1 (definition collection)

### Phase 2: Core Features (Week 2)
4. Implement basic shape handlers (rect, circle, ellipse, line)
5. Implement path handling (delegate to SvgPath)
6. Add transform stack management

### Phase 3: Advanced Features (Week 3)
7. Implement text handling with font attributes
8. Add gradient support
9. Implement `<use>` reference resolution

### Phase 4: Polish (Week 4)
10. Write comprehensive unit tests
11. Integration testing with existing SVG test suite
12. Performance benchmarking vs. SvgDomParser
13. Documentation and examples

## Testing Strategy

**Reuse existing test cases:**
- All current `SvgDomParser` test SVGs should work
- Same assertions for shape rendering
- Compare output between implementations

**Add SAX-specific tests:**
- Forward reference resolution (`<use>` before `<defs>`)
- Large file performance tests (>10MB SVG)
- Memory usage benchmarks
- Malformed XML handling

## Success Criteria

1. ✅ Parses all existing test SVGs correctly
2. ✅ Zero external dependencies beyond Java SDK
3. ✅ Performance within 20% of SvgDomParser
4. ✅ Memory usage <50% of SvgDomParser for large files
5. ✅ Code coverage >80%
6. ✅ Documentation complete

## Related Work

- **SvgDomParser** - Current Batik-based implementation (1000 LOC, full-featured)
- **SvgNanoParser** - Legacy string-based parser (deprecated, limited features)
- **SvgPath** - Existing path parser (reusable in SAX implementation)
- **Ant build.xml** - Auto-downloads Batik dependencies (solved deployment)

## Future Enhancements

After SvgSaxParser implementation:
- **Performance mode selection** - Auto-choose SAX vs. DOM based on file size
- **Hybrid approach** - Use SAX for defs collection, DOM for complex rendering
- **Streaming API** - Progressive rendering for very large SVG files
- **StAX consideration** - Investigate Streaming API for XML as alternative

## References

- [Java SAX Documentation](https://docs.oracle.com/javase/tutorial/jaxp/sax/index.html)
- [SVG 1.1 Specification](https://www.w3.org/TR/SVG11/)
- [PlantUML SVG Sprite Documentation](https://plantuml.com/sprite)
- Current implementation: `src/main/java/net/sourceforge/plantuml/emoji/SvgDomParser.java`

---

**Issue Type:** Enhancement  
**Priority:** Very Low (defer unless hard zero-dependency requirement)  
**Complexity:** Medium-High (well-defined scope, but ongoing maintenance burden)  
**Dependencies:** None (pure Java SDK)  
**Maintenance Impact:** High (10-18x more effort than Batik approach annually)  

**Note:** This is a theoretical enhancement exploration. The current `SvgDomParser` with Batik remains the recommended, solid implementation for most use cases. Only pursue if zero-dependency is a hard organizational requirement.
