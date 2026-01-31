/**
 * Provides classes for managing 
 * <a href="https://plantuml.com/en/creole#68305e25f5788db0" target="_top">
 * PlantUML Emoji</a> icon set and SVG parsing.
 * 
 * <h2>Overview</h2>
 * <p>This package handles SVG content parsing and conversion to PlantUML graphics primitives,
 * supporting both emoji sprites and general SVG rendering in diagrams.
 * 
 * <h2>Key Classes</h2>
 * <ul>
 *   <li>{@link net.sourceforge.plantuml.emoji.SvgDomParser} - Full-featured DOM-based 
 *       SVG parser using Apache Batik. Supports shapes, text with styling, images, 
 *       gradients, transforms, and nested groups.</li>
 *   <li>{@link net.sourceforge.plantuml.emoji.BatikSvgHelper} - Helper class providing 
 *       shared Batik SVG parsing functionality and GraphicsNode rendering.</li>
 *   <li>{@link net.sourceforge.plantuml.emoji.SvgNanoParser} - Lightweight string-based 
 *       SVG parser for simple use cases.</li>
 * </ul>
 * 
 * <h2>SVG Support</h2>
 * <p>The DOM-based parser (SvgDomParser) supports:
 * <ul>
 *   <li><b>Basic shapes:</b> rect, circle, ellipse, line, polyline, polygon, path</li>
 *   <li><b>Text:</b> font-family, font-size, font-weight, font-style, text-decoration, 
 *       fill attributes</li>
 *   <li><b>Images:</b> embedded PNG/JPEG via data URIs (base64)</li>
 *   <li><b>Gradients:</b> linearGradient (all directions), radialGradient (first stop color)</li>
 *   <li><b>Transforms:</b> translate, rotate, scale, matrix on groups and elements</li>
 *   <li><b>Definitions:</b> defs, symbol, use elements with href/xlink:href references</li>
 *   <li><b>Groups:</b> g elements with style inheritance and nested transforms</li>
 * </ul>
 * 
 * <h2>Dependencies</h2>
 * <p>Requires Apache Batik for DOM-based SVG parsing:
 * <ul>
 *   <li>batik-all-1.19.jar - Apache Batik SVG toolkit</li>
 *   <li>xml-apis-ext-1.3.04.jar - W3C SVG DOM interfaces</li>
 * </ul>
 * 
 * <p>Dependencies are managed by Gradle and automatically downloaded by Ant from Maven Central.
 * 
 * <h2>Limitations</h2>
 * <ul>
 *   <li>Embedded raster images work in PNG output but may not render in SVG output</li>
 *   <li>Radial gradients use only first stop color (not full gradient)</li>
 *   <li>Text overline decoration not supported (PlantUML limitation)</li>
 *   <li>Complex features not supported: clipPath, mask, filter, pattern, marker</li>
 * </ul>
 * 
 * <h2>Usage Example</h2>
 * <pre>{@code
 * String svgContent = "<svg>...</svg>";
 * SvgDomParser parser = new SvgDomParser(svgContent);
 * 
 * // Use as sprite in diagrams
 * TextBlock sprite = parser.asTextBlock(HColors.BLACK, null, 1.0, null);
 * sprite.drawU(ug);
 * }</pre>
 * 
 * @see net.sourceforge.plantuml.openiconic
 * @see net.sourceforge.plantuml.klimt.sprite.Sprite
 */
package net.sourceforge.plantuml.emoji;
