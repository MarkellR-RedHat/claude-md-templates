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
DIM='\033[2m'
NC='\033[0m' # No Color

# Template metadata: description, best-for, and category for each template
declare -A TEMPLATE_DESC
TEMPLATE_DESC=(
    ["python-project"]="Python applications and libraries. Covers ruff, mypy, pytest, Pydantic, dependency management."
    ["go-project"]="Go services, APIs, and tools. Covers golangci-lint, table-driven tests, concurrency, error handling."
    ["rust-project"]="Rust crates and binaries. Covers clippy, cargo-deny, thiserror/anyhow, tokio, unsafe policy."
    ["fastapi-project"]="FastAPI web services. Covers Pydantic v2, SQLAlchemy, Alembic, dependency injection, async patterns."
    ["ai-ml-project"]="AI/ML pipelines and model serving. Covers PyTorch, vLLM, GPU-aware testing, training, inference."
    ["kubernetes-project"]="Kubernetes and OpenShift deployments. Covers Helm, CRDs, RBAC, operators, networking, observability."
    ["operator-sdk"]="Kubernetes operators with Operator SDK. Covers controller-runtime, reconciliation, finalizers, OLM, webhooks."
    ["helm-chart"]="Helm chart development. Covers template patterns, values schema, testing, hooks, OCI registries."
    ["data-pipeline"]="Data engineering with Spark, Beam, or similar. Covers schema evolution, idempotency, backfill, data quality."
    ["cli-tool"]="CLI tools in Go, Python, or Rust. Covers argument parsing, config files, shell completion, output formatting."
    ["content-writing"]="Blog posts and technical articles. Covers Red Hat tone, SEO, editorial workflow, accessibility."
    ["proposals"]="Conference proposals and CFP submissions. Covers abstract structure, talk design, demo planning."
    ["documentation"]="Documentation sites (Antora, Hugo, MkDocs). Covers style guides, link checking, versioning, accessibility."
    ["general-devrel"]="Developer Relations projects. Covers code samples, workshops, demos, community management, metrics."
)

declare -A TEMPLATE_CATEGORY
TEMPLATE_CATEGORY=(
    ["python-project"]="code"
    ["go-project"]="code"
    ["rust-project"]="code"
    ["fastapi-project"]="code"
    ["ai-ml-project"]="code"
    ["kubernetes-project"]="infrastructure"
    ["operator-sdk"]="infrastructure"
    ["helm-chart"]="infrastructure"
    ["data-pipeline"]="code"
    ["cli-tool"]="code"
    ["content-writing"]="content"
    ["proposals"]="content"
    ["documentation"]="content"
    ["general-devrel"]="content"
)

# Parse flags
PREVIEW_MODE=false
LIST_MODE=false
SHOW_HELP=false
INTERACTIVE_MODE=false
TEMPLATE_ARG=""
TARGET_DIR_ARG=""

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
        -i|--interactive)
            INTERACTIVE_MODE=true
            shift
            ;;
        -t|--template)
            if [[ -n "${2:-}" ]]; then
                TEMPLATE_ARG="$2"
                shift 2
            else
                echo -e "${RED}Error: --template requires a template name.${NC}"
                exit 1
            fi
            ;;
        -d|--dir)
            if [[ -n "${2:-}" ]]; then
                TARGET_DIR_ARG="$2"
                shift 2
            else
                echo -e "${RED}Error: --dir requires a directory path.${NC}"
                exit 1
            fi
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
    echo "  -h, --help                  Show this help message and exit"
    echo "  -l, --list                  List available templates and exit"
    echo "  -p, --preview               Preview template contents before selecting"
    echo "  -i, --interactive           Walk through template selection with guided questions"
    echo "  -t, --template NAME         Install a specific template by name (skip selection)"
    echo "  -d, --dir PATH              Set the target directory (skip directory prompt)"
    echo ""
    echo "Modes:"
    echo "  Default                     Show templates, pick one, copy to target directory"
    echo "  Interactive (--interactive)  Answer questions about your project, get a recommendation"
    echo ""
    echo "Examples:"
    echo "  ./install.sh                          # Standard selection mode"
    echo "  ./install.sh --interactive             # Guided template selection"
    echo "  ./install.sh --template python-project # Install Python template directly"
    echo "  ./install.sh -t go-project -d ~/myapp  # Install Go template to ~/myapp"
    echo "  ./install.sh --preview                 # Preview templates before choosing"
    echo "  ./install.sh --list                    # List all available templates"
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

# Build template list
templates=()
template_names=()
for template in "${TEMPLATES_DIR}"/*.md; do
    if [ -f "${template}" ]; then
        templates+=("${template}")
        template_names+=("$(basename "${template}" .md)")
    fi
done

if [ ${#templates[@]} -eq 0 ]; then
    echo -e "${RED}Error: No template files found in ${TEMPLATES_DIR}${NC}"
    exit 1
fi

# Function to display template list
show_template_list() {
    local show_category="${1:-false}"
    local current_category=""
    local index=1

    if [ "${show_category}" = true ]; then
        # Sort by category
        echo -e "  ${DIM}--- Code Projects ---${NC}"
        for i in "${!template_names[@]}"; do
            local name="${template_names[$i]}"
            local cat="${TEMPLATE_CATEGORY[$name]:-unknown}"
            if [ "${cat}" = "code" ]; then
                local desc="${TEMPLATE_DESC[$name]:-No description}"
                echo -e "  ${BLUE}$((i + 1)))${NC} ${BOLD}${name}${NC}"
                echo -e "     ${DIM}${desc}${NC}"
                echo ""
            fi
        done

        echo -e "  ${DIM}--- Infrastructure Projects ---${NC}"
        for i in "${!template_names[@]}"; do
            local name="${template_names[$i]}"
            local cat="${TEMPLATE_CATEGORY[$name]:-unknown}"
            if [ "${cat}" = "infrastructure" ]; then
                local desc="${TEMPLATE_DESC[$name]:-No description}"
                echo -e "  ${BLUE}$((i + 1)))${NC} ${BOLD}${name}${NC}"
                echo -e "     ${DIM}${desc}${NC}"
                echo ""
            fi
        done

        echo -e "  ${DIM}--- Content Projects ---${NC}"
        for i in "${!template_names[@]}"; do
            local name="${template_names[$i]}"
            local cat="${TEMPLATE_CATEGORY[$name]:-unknown}"
            if [ "${cat}" = "content" ]; then
                local desc="${TEMPLATE_DESC[$name]:-No description}"
                echo -e "  ${BLUE}$((i + 1)))${NC} ${BOLD}${name}${NC}"
                echo -e "     ${DIM}${desc}${NC}"
                echo ""
            fi
        done
    else
        for i in "${!template_names[@]}"; do
            local name="${template_names[$i]}"
            local desc="${TEMPLATE_DESC[$name]:-No description}"
            echo -e "  ${BLUE}$((i + 1)))${NC} ${BOLD}${name}${NC}"
            echo -e "     ${DIM}${desc}${NC}"
            echo ""
        done
    fi
}

# Function to find template index by name
find_template_by_name() {
    local search="$1"
    for i in "${!template_names[@]}"; do
        if [ "${template_names[$i]}" = "${search}" ]; then
            echo "$i"
            return 0
        fi
    done
    return 1
}

# Function to install a template
install_template() {
    local template_path="$1"
    local target_dir="$2"
    local template_name
    template_name=$(basename "${template_path}" .md)

    # Expand ~ to home directory
    target_dir="${target_dir/#\~/$HOME}"

    # Resolve to absolute path
    target_dir="$(cd "${target_dir}" 2>/dev/null && pwd)" || {
        echo -e "${RED}Error: Directory '${target_dir}' does not exist.${NC}"
        exit 1
    }

    local target_file="${target_dir}/CLAUDE.md"

    # Check if CLAUDE.md already exists
    if [ -f "${target_file}" ]; then
        echo ""
        echo -e "${YELLOW}Warning: ${target_file} already exists.${NC}"
        echo -ne "${BOLD}Overwrite? (y/N):${NC} "
        read -r overwrite
        if [[ ! "${overwrite}" =~ ^[Yy]$ ]]; then
            echo "Aborted. No files were changed."
            exit 0
        fi
    fi

    # Copy the template
    cp "${template_path}" "${target_file}"

    echo ""
    echo -e "${GREEN}Done. CLAUDE.md has been created at:${NC}"
    echo "  ${target_file}"
    echo ""
    echo -e "${CYAN}Next steps:${NC}"
    echo "  1. Open ${target_file} in your editor"
    echo "  2. Search for TODO markers and fill in project-specific details"
    echo "  3. Update the Project Overview section"
    echo "  4. Remove or adjust sections that do not apply to your project"
    echo ""

    # Show TODO count
    local todo_count
    todo_count=$(grep -c "TODO" "${target_file}" 2>/dev/null || echo "0")
    if [ "${todo_count}" -gt 0 ]; then
        echo -e "  ${YELLOW}Found ${todo_count} TODO markers to customize.${NC}"
        echo ""
    fi
}

# ============================================================
# Interactive Mode
# ============================================================
if [ "${INTERACTIVE_MODE}" = true ]; then
    echo -e "${BOLD}Interactive template selection${NC}"
    echo "Answer a few questions and we will recommend the right template."
    echo ""

    # Question 1: What kind of project?
    echo -e "${BOLD}What kind of project are you working on?${NC}"
    echo ""
    echo "  1) A software application or library (writing code)"
    echo "  2) Infrastructure or platform engineering (Kubernetes, Helm, operators)"
    echo "  3) Content creation (blog posts, docs, proposals, DevRel)"
    echo ""
    echo -ne "${BOLD}Your choice (1-3):${NC} "
    read -r project_kind

    recommended=""

    case "${project_kind}" in
        1)
            # Software project: ask about language
            echo ""
            echo -e "${BOLD}What is the primary language?${NC}"
            echo ""
            echo "  1) Python"
            echo "  2) Go"
            echo "  3) Rust"
            echo "  4) Multiple or other"
            echo ""
            echo -ne "${BOLD}Your choice (1-4):${NC} "
            read -r language_choice

            case "${language_choice}" in
                1)
                    # Python: ask about framework
                    echo ""
                    echo -e "${BOLD}What type of Python project?${NC}"
                    echo ""
                    echo "  1) FastAPI web service"
                    echo "  2) AI/ML (model training, inference, data science)"
                    echo "  3) Data pipeline (ETL, Spark, Beam)"
                    echo "  4) CLI tool"
                    echo "  5) General Python application or library"
                    echo ""
                    echo -ne "${BOLD}Your choice (1-5):${NC} "
                    read -r python_type

                    case "${python_type}" in
                        1) recommended="fastapi-project" ;;
                        2) recommended="ai-ml-project" ;;
                        3) recommended="data-pipeline" ;;
                        4) recommended="cli-tool" ;;
                        *) recommended="python-project" ;;
                    esac
                    ;;
                2)
                    # Go: ask about type
                    echo ""
                    echo -e "${BOLD}What type of Go project?${NC}"
                    echo ""
                    echo "  1) Kubernetes operator"
                    echo "  2) CLI tool"
                    echo "  3) Web service or API"
                    echo "  4) General Go application"
                    echo ""
                    echo -ne "${BOLD}Your choice (1-4):${NC} "
                    read -r go_type

                    case "${go_type}" in
                        1) recommended="operator-sdk" ;;
                        2) recommended="cli-tool" ;;
                        *) recommended="go-project" ;;
                    esac
                    ;;
                3)
                    # Rust: ask about type
                    echo ""
                    echo -e "${BOLD}What type of Rust project?${NC}"
                    echo ""
                    echo "  1) CLI tool"
                    echo "  2) Web service"
                    echo "  3) Library or general application"
                    echo ""
                    echo -ne "${BOLD}Your choice (1-3):${NC} "
                    read -r rust_type

                    case "${rust_type}" in
                        1) recommended="cli-tool" ;;
                        *) recommended="rust-project" ;;
                    esac
                    ;;
                *)
                    recommended="python-project"
                    echo ""
                    echo -e "${YELLOW}Defaulting to python-project. You can browse all templates with ./install.sh --list${NC}"
                    ;;
            esac
            ;;
        2)
            # Infrastructure: ask about type
            echo ""
            echo -e "${BOLD}What type of infrastructure project?${NC}"
            echo ""
            echo "  1) Kubernetes operator (controller-runtime, Operator SDK)"
            echo "  2) Helm chart"
            echo "  3) Kubernetes/OpenShift deployment manifests and configuration"
            echo "  4) Data pipeline infrastructure"
            echo ""
            echo -ne "${BOLD}Your choice (1-4):${NC} "
            read -r infra_type

            case "${infra_type}" in
                1) recommended="operator-sdk" ;;
                2) recommended="helm-chart" ;;
                3) recommended="kubernetes-project" ;;
                4) recommended="data-pipeline" ;;
                *) recommended="kubernetes-project" ;;
            esac
            ;;
        3)
            # Content: ask about type
            echo ""
            echo -e "${BOLD}What type of content?${NC}"
            echo ""
            echo "  1) Blog posts and technical articles"
            echo "  2) Conference proposals and CFP submissions"
            echo "  3) Documentation site (Antora, Hugo, MkDocs)"
            echo "  4) Developer Relations (demos, workshops, code samples)"
            echo ""
            echo -ne "${BOLD}Your choice (1-4):${NC} "
            read -r content_type

            case "${content_type}" in
                1) recommended="content-writing" ;;
                2) recommended="proposals" ;;
                3) recommended="documentation" ;;
                4) recommended="general-devrel" ;;
                *) recommended="content-writing" ;;
            esac
            ;;
        *)
            echo -e "${RED}Invalid choice. Running standard selection mode instead.${NC}"
            echo ""
            INTERACTIVE_MODE=false
            ;;
    esac

    if [ -n "${recommended}" ]; then
        echo ""
        echo -e "${GREEN}Recommended template: ${BOLD}${recommended}${NC}"
        local desc="${TEMPLATE_DESC[$recommended]:-}"
        if [ -n "${desc}" ]; then
            echo -e "  ${DIM}${desc}${NC}"
        fi
        echo ""

        # Ask about secondary concerns
        echo -e "${BOLD}Does your project also involve any of these? (optional)${NC}"
        echo ""
        echo "  1) Kubernetes deployment"
        echo "  2) AI/ML model serving"
        echo "  3) Helm chart packaging"
        echo "  4) None of the above"
        echo ""
        echo -ne "${BOLD}Your choice (1-4, default 4):${NC} "
        read -r secondary_choice

        secondary=""
        case "${secondary_choice}" in
            1) secondary="kubernetes-project" ;;
            2) secondary="ai-ml-project" ;;
            3) secondary="helm-chart" ;;
            *) secondary="" ;;
        esac

        if [ -n "${secondary}" ] && [ "${secondary}" != "${recommended}" ]; then
            echo ""
            echo -e "${CYAN}Consider combining templates. After installing, you can use:${NC}"
            echo -e "  ${BOLD}/compose-template ${recommended} + ${secondary}${NC}"
            echo ""
        fi

        # Confirm and install
        echo -ne "${BOLD}Install ${recommended}? (Y/n):${NC} "
        read -r confirm
        if [[ "${confirm}" =~ ^[Nn]$ ]]; then
            echo ""
            echo "No template installed. Run again to select a different template."
            exit 0
        fi

        # Get target directory
        if [ -n "${TARGET_DIR_ARG}" ]; then
            target_dir="${TARGET_DIR_ARG}"
        else
            echo ""
            echo -e "${BOLD}Enter the target directory (where CLAUDE.md will be created):${NC}"
            echo -e "  ${CYAN}Press Enter to use the current directory ($(pwd))${NC}"
            read -r target_dir
            if [ -z "${target_dir}" ]; then
                target_dir="$(pwd)"
            fi
        fi

        template_idx=$(find_template_by_name "${recommended}") || {
            echo -e "${RED}Error: Template '${recommended}' not found.${NC}"
            exit 1
        }
        install_template "${templates[$template_idx]}" "${target_dir}"
        exit 0
    fi
fi

# ============================================================
# Direct template installation (--template flag)
# ============================================================
if [ -n "${TEMPLATE_ARG}" ]; then
    template_idx=$(find_template_by_name "${TEMPLATE_ARG}") || {
        echo -e "${RED}Error: Template '${TEMPLATE_ARG}' not found.${NC}"
        echo ""
        echo "Available templates:"
        for name in "${template_names[@]}"; do
            echo "  ${name}"
        done
        exit 1
    }

    if [ -n "${TARGET_DIR_ARG}" ]; then
        target_dir="${TARGET_DIR_ARG}"
    else
        echo -ne "${BOLD}Enter the target directory (Press Enter for current directory):${NC} "
        read -r target_dir
        if [ -z "${target_dir}" ]; then
            target_dir="$(pwd)"
        fi
    fi

    install_template "${templates[$template_idx]}" "${target_dir}"
    exit 0
fi

# ============================================================
# Standard Mode (default)
# ============================================================

# List available templates
echo -e "${BOLD}Available templates:${NC}"
echo ""
show_template_list false

# List mode: print templates and exit
if [ "${LIST_MODE}" = true ]; then
    echo -e "${CYAN}Tip: Run without --list to install a template interactively.${NC}"
    echo -e "${CYAN}     Run with --interactive for guided template selection.${NC}"
    exit 0
fi

# Preview mode: let the user preview templates before selecting
if [ "${PREVIEW_MODE}" = true ]; then
    while true; do
        echo -e "${CYAN}Preview mode: enter a template number to see its first 20 lines, or 'q' to continue to selection.${NC}"
        echo -ne "${BOLD}Preview which template? (1-${#templates[@]}, or q):${NC} "
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
        echo -e "${CYAN}--- Preview: ${preview_name} ---${NC}"
        head -20 "${preview_file}"
        echo -e "${DIM}... ($(wc -l < "${preview_file}" | tr -d ' ') lines total)${NC}"
        echo -e "${CYAN}--- end preview ---${NC}"
        echo ""
    done
fi

# Quick customize hint
echo -e "${CYAN}Tip: After installing, search for TODO markers in the template to customize it.${NC}"
echo -e "${CYAN}     Use --interactive for guided selection based on your project type.${NC}"
echo ""

# Prompt for selection
echo -ne "${BOLD}Select a template (1-${#templates[@]}):${NC} "
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
if [ -n "${TARGET_DIR_ARG}" ]; then
    target_dir="${TARGET_DIR_ARG}"
else
    echo -e "${BOLD}Enter the target directory (where CLAUDE.md will be created):${NC}"
    echo -e "  ${CYAN}Press Enter to use the current directory ($(pwd))${NC}"
    read -r target_dir
    if [ -z "${target_dir}" ]; then
        target_dir="$(pwd)"
    fi
fi

install_template "${selected_template}" "${target_dir}"
