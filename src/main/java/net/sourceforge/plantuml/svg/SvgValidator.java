package net.sourceforge.plantuml.svg;

import net.sourceforge.plantuml.emoji.BatikSvgHelper;
import net.sourceforge.plantuml.emoji.BatikSvgHelper.ParsedSvg;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;

/**
 * Command-line utility to validate SVG files using Batik/SvgDomParser.
 * 
 * <p>This tool is used by sprite generation scripts to verify SVG syntax
 * before creating PlantUML sprite definitions.
 * 
 * <p>Usage: java -cp plantuml.jar net.sourceforge.plantuml.svg.SvgValidator &lt;svg-file&gt;
 * 
 * <p>Exit codes:
 * <ul>
 *   <li>0 - SVG is valid</li>
 *   <li>1 - SVG validation failed or file read error</li>
 * </ul>
 * 
 * @since 1.2025.12
 */
public class SvgValidator {
    
    public static void main(String[] args) {
        if (args.length != 1) {
            System.err.println("Usage: java -cp plantuml.jar net.sourceforge.plantuml.svg.SvgValidator <svg-file>");
            System.err.println();
            System.err.println("Validates an SVG file using Batik/SvgDomParser.");
            System.err.println("Exit code 0 = valid, 1 = invalid or error");
            System.exit(1);
        }
        
        String svgFile = args[0];
        
        try {
            // Read SVG content
            String svgContent = new String(Files.readAllBytes(Paths.get(svgFile)));
            
            // Validate using BatikSvgHelper (same validation as SvgDomParser)
            ParsedSvg parsed = BatikSvgHelper.parseSvg(svgContent, false);
            
            if (parsed == null || parsed.document == null) {
                System.err.println("ERROR: Failed to parse SVG - null document returned");
                System.err.println("File: " + svgFile);
                System.exit(1);
            }
            
            // Check for root element
            if (parsed.document.getDocumentElement() == null) {
                System.err.println("ERROR: SVG has no root element");
                System.err.println("File: " + svgFile);
                System.exit(1);
            }
            
            // Validation successful - silent success for script usage
            System.exit(0);
            
        } catch (IOException e) {
            System.err.println("ERROR: Failed to read SVG file: " + e.getMessage());
            System.err.println("File: " + svgFile);
            System.exit(1);
        } catch (Exception e) {
            System.err.println("ERROR: SVG validation failed");
            System.err.println("File: " + svgFile);
            System.err.println("Error: " + e.getClass().getName() + ": " + e.getMessage());
            if (e.getCause() != null) {
                System.err.println("Caused by: " + e.getCause().getMessage());
            }
            System.exit(1);
        }
    }
}
