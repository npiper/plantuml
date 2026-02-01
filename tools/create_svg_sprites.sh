#!/usr/bin/env bash

# 
# (C) Copyright 2026, Neil Piper
# 
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
# 


#
# Batch creates PlantUML sprite files directly from SVG files
#
# Given a directory of SVG files (e.g., Font Awesome, Google Material Icons),
# validates each SVG using Batik/SvgDomParser and generates PlantUML sprite files.
#
# Unlike the PNG-based workflow, this preserves vector graphics and uses the
# SvgDomParser for native SVG rendering in PlantUML.
#
# This script assumes PlantUML jar is available and Java is in PATH.
#


# Help usage message
usage="Batch creates SVG sprite files for PlantUML.

$(basename "$0") [options] prefix

options:
    -p  directory path to process              Default: ./
    -j  path to plantuml.jar                   Default: ./plantuml.jar
    -o  output directory for sprite files      Default: same as input directory
    -v  verbose mode (show processing details) Default: off
    
    prefix: a prefix that is added to the sprite name
    
Example:
    $(basename "$0") -p ./fontawesome-svgs -o ./sprites -j /path/to/plantuml.jar fontawesome
    $(basename "$0") -p ./material-icons -v material

Notes:
    - Only processes *.svg files
    - Uses SvgDomParser/Batik for SVG validation
    - Continues processing even if individual SVGs fail
    - Failed SVGs are reported to stderr with details
"



# Default arguments values
         dir="./"             # Directory path to process     Default: ./
  plantumljar="./plantuml.jar"# Path to PlantUML jar          Default: ./plantuml.jar
   outputdir=""               # Output directory              Default: same as input
     verbose=0                # Verbose mode                  Default: off

      prefix=""               # Prefix for sprites names
 prefixupper=""               # Prefix in uppercase



########################################
#
#    Main function
#
########################################
main () {
    # Get arguments
    while getopts p:j:o:v option
    do
        case "$option" in
            p)         dir="$OPTARG";;
            j)  plantumljar="$OPTARG";;
            o)   outputdir="$OPTARG";;
            v)     verbose=1;;
            :) echo "$usage"
               exit 1
               ;;
           \?) echo "$usage"
               exit 1
               ;;
        esac
    done

    # Get mandatory argument
    shift $(($OPTIND-1))
    prefix=$(     echo $1 | tr '[:upper:]' '[:lower:]')
    prefixupper=$(echo $1 | tr '[:lower:]' '[:upper:]')

    # Check mandatory argument
    if [ -z "$prefix" ]
    then
        echo "Please specify a prefix!"
        echo "$usage"
        exit 1
    fi

    # Check input directory exists
    if [ ! -d "${dir}" ]
    then
        echo "ERROR: Input directory does not exist: ${dir}"
        echo "$usage"
        exit 1
    fi

    # Check PlantUML jar exists
    if [ ! -f "${plantumljar}" ]
    then
        echo "ERROR: PlantUML jar not found: ${plantumljar}"
        echo "Please specify the correct path with -j option"
        exit 1
    fi

    # Set output directory (default to input directory)
    if [ -z "$outputdir" ]
    then
        outputdir="$dir"
    fi

    # Create output directory if it doesn't exist
    mkdir -p "$outputdir"

    echo "========================================="
    echo "PlantUML SVG Sprite Generator"
    echo "========================================="
    echo "Input directory:  $dir"
    echo "Output directory: $outputdir"
    echo "Prefix:           $prefix"
    echo "PlantUML jar:     $plantumljar"
    echo "========================================="
    echo ""

    # Process all SVG files
    process_svg_files
    
    echo ""
    echo "========================================="
    echo "Processing complete!"
    echo "Processed: $total_processed files"
    echo "Succeeded: $total_success files"
    echo "Failed:    $total_failed files"
    echo "========================================="
}


# Counters for summary
total_processed=0
total_success=0
total_failed=0


########################################
#
#    Process all SVG files in directory
#
########################################
process_svg_files () {
    # Find all SVG files (case-insensitive)
    shopt -s nullglob nocaseglob
    
    for svgfile in "${dir}"/*.svg
    do
        [ -f "$svgfile" ] || continue
        
        total_processed=$((total_processed + 1))
        
        # Extract filename without path and extension
        filename=$(basename "$svgfile" .svg)
        
        if [ "$verbose" -eq 1 ]
        then
            echo "Processing: $filename.svg"
        fi
        
        # Validate and process the SVG file
        if validate_and_create_sprite "$svgfile" "$filename"
        then
            total_success=$((total_success + 1))
            if [ "$verbose" -eq 1 ]
            then
                echo "  ✓ Success: $filename.puml"
            fi
        else
            total_failed=$((total_failed + 1))
            echo "  ✗ FAILED: $filename.svg (see error above)" >&2
        fi
    done
    
    shopt -u nullglob nocaseglob
}


########################################
#
#    Validate SVG and create sprite file
#
########################################
validate_and_create_sprite () {
    local svgfile="$1"
    local filename="$2"
    
    # Sanitize filename for sprite name (replace non-alphanumeric with underscore)
    local cleanname=$(echo "$filename" | sed 's/[^a-zA-Z0-9._]/_/g')
    
    # Create sprite names
    local filenameupper=$(echo "$cleanname" | tr '[:lower:]' '[:upper:]')
    local spritename="${prefix}_${cleanname}"
    local spritenameupper="${prefixupper}_${filenameupper}"
    local spritestereo="$prefixupper $filenameupper"
    local stereowhites=$(echo "$spritestereo" | sed -e 's/./ /g')
    
    # Output file path
    local outfile="${outputdir}/${cleanname}.puml"
    
    # Validate SVG using Java and SvgDomParser
    # We'll create a small Java validator that uses Batik to parse the SVG
    if ! validate_svg_syntax "$svgfile"
    then
        echo "ERROR: SVG validation failed for: $svgfile" >&2
        echo "       Invalid SVG syntax or unsupported features" >&2
        return 1
    fi
    
    # Read SVG content and escape for sprite definition
    local svg_content=$(cat "$svgfile")
    
    # Create the sprite file
    create_sprite_file "$outfile" "$spritename" "$spritenameupper" "$spritestereo" "$stereowhites" "$svg_content"
    
    return 0
}


########################################
#
#    Validate SVG syntax using Batik
#
########################################
validate_svg_syntax () {
    local svgfile="$1"
    
    # Use the built-in SvgValidator class from PlantUML jar
    # No need to compile - it's already in the jar
    local validation_output
    validation_output=$(java -cp "$plantumljar" net.sourceforge.plantuml.svg.SvgValidator "$svgfile" 2>&1)
    local result=$?
    
    # Show validation output only if verbose or on error
    if [ $result -ne 0 ] || [ "$verbose" -eq 1 ]
    then
        echo "$validation_output" >&2
    fi
    
    return $result
}


########################################
#
#    Create PlantUML sprite file
#
########################################
create_sprite_file () {
    local outfile="$1"
    local spritename="$2"
    local spritenameupper="$3"
    local spritestereo="$4"
    local stereowhites="$5"
    local svg_content="$6"
    
    # Create the sprite file
    cat > "$outfile" <<EOF
@startuml
sprite \$${spritename} [svg] {
${svg_content}
}

!define ${spritenameupper}(_color)                                 SPRITE_PUT(          ${stereowhites}          ${spritename}, _color)
!define ${spritenameupper}(_color, _scale)                         SPRITE_PUT(          ${stereowhites}          ${spritename}, _color, _scale)

!define ${spritenameupper}(_color, _scale, _alias)                 SPRITE_ENT(  _alias, ${spritestereo},         ${spritename}, _color, _scale)
!define ${spritenameupper}(_color, _scale, _alias, _shape)         SPRITE_ENT(  _alias, ${spritestereo},         ${spritename}, _color, _scale, _shape)
!define ${spritenameupper}(_color, _scale, _alias, _shape, _label) SPRITE_ENT_L(_alias, ${spritestereo}, _label, ${spritename}, _color, _scale, _shape)

skinparam folderBackgroundColor<<${prefixupper} ${filenameupper}>> White
@enduml
EOF
    
    return 0
}


# Run main function
main "$@"
