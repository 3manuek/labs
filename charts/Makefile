.PHONY: all all-png clean setup export-mermaid export-mermaid-png help

# Directories
DOWNLOADS_DIR := downloads
TEMP_DIR := .mermaid_temp

# Find all markdown files
MD_FILES := $(wildcard *.md)

# Help target
help:
	@echo "Mermaid Export Makefile"
	@echo "======================="
	@echo ""
	@echo "Usage:"
	@echo "  make all            - Export all mermaid diagrams to SVG"
	@echo "  make all-png        - Export all mermaid diagrams to PNG"
	@echo "  make setup          - Install mermaid-cli if not present"
	@echo "  make clean          - Remove generated files and temp directory"
	@echo "  make help           - Show this help message"
	@echo ""
	@echo "Requirements:"
	@echo "  - Node.js and npm must be installed"
	@echo "  - mermaid-cli (mmdc) - run 'make setup' to install"
	@echo ""

# Default target
all: setup export-mermaid

# PNG export target
all-png: setup export-mermaid-png

# Setup mermaid-cli
setup:
	@echo "Checking for mermaid-cli..."
	@if ! command -v mmdc >/dev/null 2>&1; then \
		echo "mermaid-cli not found. Installing..."; \
		npm install -g @mermaid-js/mermaid-cli; \
	else \
		echo "mermaid-cli is already installed."; \
	fi

# Export all mermaid diagrams
export-mermaid: extract-mermaid-script
	@echo "Creating directories..."
	@mkdir -p $(DOWNLOADS_DIR)
	@mkdir -p $(TEMP_DIR)
	@echo "Extracting and converting mermaid diagrams..."
	@chmod +x extract-mermaid.sh
	@./extract-mermaid.sh
	@echo ""
	@echo "Done! SVG files are in $(DOWNLOADS_DIR)/"
	@ls -lh $(DOWNLOADS_DIR)/*.svg 2>/dev/null || echo "No SVG files were generated"

# Create the extraction script
extract-mermaid-script:
	@echo '#!/bin/bash' > extract-mermaid.sh
	@echo 'TEMP_DIR=".mermaid_temp"' >> extract-mermaid.sh
	@echo 'DOWNLOADS_DIR="downloads"' >> extract-mermaid.sh
	@echo 'count=0' >> extract-mermaid.sh
	@echo '' >> extract-mermaid.sh
	@echo 'for md_file in *.md; do' >> extract-mermaid.sh
	@echo '    [ -f "$$md_file" ] || continue' >> extract-mermaid.sh
	@echo '    base_name=$$(basename "$$md_file" .md)' >> extract-mermaid.sh
	@echo '    echo "Processing $$md_file..."' >> extract-mermaid.sh
	@echo '    diagram_num=0' >> extract-mermaid.sh
	@echo '    in_mermaid=0' >> extract-mermaid.sh
	@echo '    mmd_content=""' >> extract-mermaid.sh
	@echo '    ' >> extract-mermaid.sh
	@echo '    while IFS= read -r line; do' >> extract-mermaid.sh
	@echo '        if echo "$$line" | grep -q "^\`\`\`mermaid"; then' >> extract-mermaid.sh
	@echo '            in_mermaid=1' >> extract-mermaid.sh
	@echo '            mmd_content=""' >> extract-mermaid.sh
	@echo '            continue' >> extract-mermaid.sh
	@echo '        fi' >> extract-mermaid.sh
	@echo '        ' >> extract-mermaid.sh
	@echo '        if [ $$in_mermaid -eq 1 ]; then' >> extract-mermaid.sh
	@echo '            if echo "$$line" | grep -q "^\`\`\`"; then' >> extract-mermaid.sh
	@echo '                diagram_num=$$((diagram_num + 1))' >> extract-mermaid.sh
	@echo '                mmd_file="$$TEMP_DIR/$${base_name}-$$(printf "%02d" $$diagram_num).mmd"' >> extract-mermaid.sh
	@echo '                echo "$$mmd_content" > "$$mmd_file"' >> extract-mermaid.sh
	@echo '                svg_file="$$DOWNLOADS_DIR/$${base_name}-$$(printf "%02d" $$diagram_num).svg"' >> extract-mermaid.sh
	@echo '                echo "  Converting diagram $$diagram_num -> $$svg_file"' >> extract-mermaid.sh
	@echo '                if mmdc -i "$$mmd_file" -o "$$svg_file" -b transparent 2>/dev/null; then' >> extract-mermaid.sh
	@echo '                    count=$$((count + 1))' >> extract-mermaid.sh
	@echo '                else' >> extract-mermaid.sh
	@echo '                    echo "  Warning: Failed to convert $$mmd_file"' >> extract-mermaid.sh
	@echo '                fi' >> extract-mermaid.sh
	@echo '                in_mermaid=0' >> extract-mermaid.sh
	@echo '                mmd_content=""' >> extract-mermaid.sh
	@echo '            else' >> extract-mermaid.sh
	@echo '                mmd_content="$$mmd_content$$line"$$'"'"'\n'"'"'' >> extract-mermaid.sh
	@echo '            fi' >> extract-mermaid.sh
	@echo '        fi' >> extract-mermaid.sh
	@echo '    done < "$$md_file"' >> extract-mermaid.sh
	@echo '    ' >> extract-mermaid.sh
	@echo '    if [ $$diagram_num -eq 0 ]; then' >> extract-mermaid.sh
	@echo '        echo "  No mermaid diagrams found"' >> extract-mermaid.sh
	@echo '    fi' >> extract-mermaid.sh
	@echo 'done' >> extract-mermaid.sh
	@echo '' >> extract-mermaid.sh
	@echo 'rm -rf "$$TEMP_DIR"' >> extract-mermaid.sh
	@echo 'echo ""' >> extract-mermaid.sh
	@echo 'echo "Total diagrams converted: $$count"' >> extract-mermaid.sh

# Export all mermaid diagrams to PNG
export-mermaid-png: extract-mermaid-png-script
	@echo "Creating directories..."
	@mkdir -p $(DOWNLOADS_DIR)
	@mkdir -p $(TEMP_DIR)
	@echo "Extracting and converting mermaid diagrams to PNG..."
	@chmod +x extract-mermaid-png.sh
	@./extract-mermaid-png.sh
	@echo ""
	@echo "Done! PNG files are in $(DOWNLOADS_DIR)/"
	@ls -lh $(DOWNLOADS_DIR)/*.png 2>/dev/null || echo "No PNG files were generated"

# Create the extraction script for PNG
extract-mermaid-png-script:
	@echo '#!/bin/bash' > extract-mermaid-png.sh
	@echo 'TEMP_DIR=".mermaid_temp"' >> extract-mermaid-png.sh
	@echo 'DOWNLOADS_DIR="downloads"' >> extract-mermaid-png.sh
	@echo 'count=0' >> extract-mermaid-png.sh
	@echo '' >> extract-mermaid-png.sh
	@echo 'for md_file in *.md; do' >> extract-mermaid-png.sh
	@echo '    [ -f "$$md_file" ] || continue' >> extract-mermaid-png.sh
	@echo '    base_name=$$(basename "$$md_file" .md)' >> extract-mermaid-png.sh
	@echo '    echo "Processing $$md_file..."' >> extract-mermaid-png.sh
	@echo '    diagram_num=0' >> extract-mermaid-png.sh
	@echo '    in_mermaid=0' >> extract-mermaid-png.sh
	@echo '    mmd_content=""' >> extract-mermaid-png.sh
	@echo '    ' >> extract-mermaid-png.sh
	@echo '    while IFS= read -r line; do' >> extract-mermaid-png.sh
	@echo '        if echo "$$line" | grep -q "^\`\`\`mermaid"; then' >> extract-mermaid-png.sh
	@echo '            in_mermaid=1' >> extract-mermaid-png.sh
	@echo '            mmd_content=""' >> extract-mermaid-png.sh
	@echo '            continue' >> extract-mermaid-png.sh
	@echo '        fi' >> extract-mermaid-png.sh
	@echo '        ' >> extract-mermaid-png.sh
	@echo '        if [ $$in_mermaid -eq 1 ]; then' >> extract-mermaid-png.sh
	@echo '            if echo "$$line" | grep -q "^\`\`\`"; then' >> extract-mermaid-png.sh
	@echo '                diagram_num=$$((diagram_num + 1))' >> extract-mermaid-png.sh
	@echo '                mmd_file="$$TEMP_DIR/$${base_name}-$$(printf "%02d" $$diagram_num).mmd"' >> extract-mermaid-png.sh
	@echo '                echo "$$mmd_content" > "$$mmd_file"' >> extract-mermaid-png.sh
	@echo '                png_file="$$DOWNLOADS_DIR/$${base_name}-$$(printf "%02d" $$diagram_num).png"' >> extract-mermaid-png.sh
	@echo '                echo "  Converting diagram $$diagram_num -> $$png_file"' >> extract-mermaid-png.sh
	@echo '                if mmdc -i "$$mmd_file" -o "$$png_file" -b transparent 2>/dev/null; then' >> extract-mermaid-png.sh
	@echo '                    count=$$((count + 1))' >> extract-mermaid-png.sh
	@echo '                else' >> extract-mermaid-png.sh
	@echo '                    echo "  Warning: Failed to convert $$mmd_file"' >> extract-mermaid-png.sh
	@echo '                fi' >> extract-mermaid-png.sh
	@echo '                in_mermaid=0' >> extract-mermaid-png.sh
	@echo '                mmd_content=""' >> extract-mermaid-png.sh
	@echo '            else' >> extract-mermaid-png.sh
	@echo '                mmd_content="$$mmd_content$$line"$$'"'"'\n'"'"'' >> extract-mermaid-png.sh
	@echo '            fi' >> extract-mermaid-png.sh
	@echo '        fi' >> extract-mermaid-png.sh
	@echo '    done < "$$md_file"' >> extract-mermaid-png.sh
	@echo '    ' >> extract-mermaid-png.sh
	@echo '    if [ $$diagram_num -eq 0 ]; then' >> extract-mermaid-png.sh
	@echo '        echo "  No mermaid diagrams found"' >> extract-mermaid-png.sh
	@echo '    fi' >> extract-mermaid-png.sh
	@echo 'done' >> extract-mermaid-png.sh
	@echo '' >> extract-mermaid-png.sh
	@echo 'rm -rf "$$TEMP_DIR"' >> extract-mermaid-png.sh
	@echo 'echo ""' >> extract-mermaid-png.sh
	@echo 'echo "Total diagrams converted: $$count"' >> extract-mermaid-png.sh

# Clean generated files
clean:
	@echo "Cleaning up..."
	@rm -rf $(DOWNLOADS_DIR) $(TEMP_DIR) extract-mermaid.sh extract-mermaid-png.sh
	@echo "Done!"
