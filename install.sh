#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEMPLATES_DIR="${SCRIPT_DIR}/templates"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Parse flags
PREVIEW_MODE=false
LIST_MODE=false
SHOW_HELP=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        -p|--preview)
            PREVIEW_MODE=true
            shift
            ;;
        -l|--list)
            LIST_MODE=true
            shift
            ;;
        -h|--help)
            SHOW_HELP=true
            shift
            ;;
        *)
            echo -e "${RED}Error: Unknown option '${1}'${NC}"
            echo "Run with --help for usage information."
            exit 1
            ;;
    esac
done

# Help output
if [ "${SHOW_HELP}" = true ]; then
    echo ""
    echo -e "${BOLD}CLAUDE.md Template Installer${NC}"
    echo ""
    echo "Usage: ./install.sh [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help       Show this help message and exit"
    echo "  -l, --list       List available templates and exit"
    echo "  -p, --preview    Preview the first 10 lines of a template before selecting"
    echo ""
    echo "When run with no options, the script shows available templates,"
    echo "prompts you to pick one, and copies it to a directory of your choice."
    echo ""
    exit 0
fi

echo ""
echo -e "${BOLD}CLAUDE.md Template Installer${NC}"
echo "============================================"
echo ""

# Check that templates directory exists
if [ ! -d "${TEMPLATES_DIR}" ]; then
    echo -e "${RED}Error: templates directory not found at ${TEMPLATES_DIR}${NC}"
    exit 1
fi

# List available templates
echo -e "${BOLD}Available templates:${NC}"
echo ""

templates=()
index=1

for template in "${TEMPLATES_DIR}"/*.md; do
    if [ -f "${template}" ]; then
        filename=$(basename "${template}" .md)
        # Extract the first heading as a description
        description=$(head -1 "${template}" | sed 's/^# CLAUDE.md - //')
        templates+=("${template}")
        echo -e "  ${BLUE}${index})${NC} ${BOLD}${filename}${NC}"
        echo "     ${description}"
        echo ""
        index=$((index + 1))
    fi
done

if [ ${#templates[@]} -eq 0 ]; then
    echo -e "${RED}Error: No template files found in ${TEMPLATES_DIR}${NC}"
    exit 1
fi

# List mode: print templates and exit
if [ "${LIST_MODE}" = true ]; then
    echo -e "${CYAN}Tip: Run without --list to install a template interactively.${NC}"
    exit 0
fi

# Preview mode: let the user preview templates before selecting
if [ "${PREVIEW_MODE}" = true ]; then
    while true; do
        echo -e "${CYAN}Preview mode: enter a template number to see its first 10 lines, or 'q' to continue to selection.${NC}"
        echo -e "${BOLD}Preview which template? (1-${#templates[@]}, or q):${NC} "
        read -r preview_choice

        if [[ "${preview_choice}" =~ ^[Qq]$ ]]; then
            echo ""
            break
        fi

        if ! [[ "${preview_choice}" =~ ^[0-9]+$ ]] || [ "${preview_choice}" -lt 1 ] || [ "${preview_choice}" -gt ${#templates[@]} ]; then
            echo -e "${YELLOW}Warning: Invalid choice. Enter a number between 1 and ${#templates[@]}, or 'q' to continue.${NC}"
            echo ""
            continue
        fi

        preview_file="${templates[$((preview_choice - 1))]}"
        preview_name=$(basename "${preview_file}" .md)
        echo ""
        echo -e "${CYAN}--- Preview: ${preview_name} (first 10 lines) ---${NC}"
        head -10 "${preview_file}"
        echo -e "${CYAN}--- end preview ---${NC}"
        echo ""
    done
fi

# Quick customize hint
echo -e "${CYAN}Tip: After installing, search for TODO markers in the template to find sections that need customization.${NC}"
echo ""

# Prompt for selection
echo -e "${BOLD}Select a template (1-${#templates[@]}):${NC} "
read -r selection

# Validate selection
if ! [[ "${selection}" =~ ^[0-9]+$ ]] || [ "${selection}" -lt 1 ] || [ "${selection}" -gt ${#templates[@]} ]; then
    echo -e "${RED}Error: Invalid selection. Please enter a number between 1 and ${#templates[@]}.${NC}"
    exit 1
fi

selected_template="${templates[$((selection - 1))]}"
selected_name=$(basename "${selected_template}" .md)

echo ""
echo -e "${GREEN}Selected: ${selected_name}${NC}"
echo ""

# Prompt for target directory
echo -e "${BOLD}Enter the target directory (where CLAUDE.md will be created):${NC}"
echo -e "  ${CYAN}Press Enter to use the current directory ($(pwd))${NC}"
read -r target_dir

if [ -z "${target_dir}" ]; then
    target_dir="$(pwd)"
fi

# Expand ~ to home directory
target_dir="${target_dir/#\~/$HOME}"

# Resolve to absolute path
target_dir="$(cd "${target_dir}" 2>/dev/null && pwd)" || {
    echo -e "${RED}Error: Directory '${target_dir}' does not exist.${NC}"
    exit 1
}

target_file="${target_dir}/CLAUDE.md"

# Check if CLAUDE.md already exists
if [ -f "${target_file}" ]; then
    echo ""
    echo -e "${YELLOW}Warning: ${target_file} already exists.${NC}"
    echo -e "${BOLD}Overwrite? (y/N):${NC} "
    read -r overwrite
    if [[ ! "${overwrite}" =~ ^[Yy]$ ]]; then
        echo "Aborted. No files were changed."
        exit 0
    fi
fi

# Copy the template
cp "${selected_template}" "${target_file}"

echo ""
echo -e "${GREEN}Done. CLAUDE.md has been created at:${NC}"
echo "  ${target_file}"
echo ""
echo -e "${CYAN}Next steps:${NC}"
echo "  1. Open ${target_file} in your editor"
echo "  2. Search for TODO markers and fill in project-specific details"
echo "  3. Update the Project Overview section"
echo "  4. Customize the template for your specific project"
echo ""
