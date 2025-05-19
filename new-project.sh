#!/bin/bash
set -eo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

TEMPLATE_PATH="$HOME/.cookiecutters/poetry-template"
PROJECT_NAME=""
DESCRIPTION="A short description of the project"
PYTHON_VERSION="^3.10"
VERSION="0.1.0"
INSTALL_DEPS=true
INIT_GIT=true
CREATE_GITHUB=false
HELP=false

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h|--help)
            HELP=true
            shift
            ;;
        --no-install)
            INSTALL_DEPS=false
            shift
            ;;
        --no-git)
            INIT_GIT=false
            shift
            ;;
        --github)
            CREATE_GITHUB=true
            shift
            ;;
        --python=*)
            PYTHON_VERSION="${1#*=}"
            shift
            ;;
        --version=*)
            VERSION="${1#*=}"
            shift
            ;;
        --template=*)
            TEMPLATE_PATH="${1#*=}"
            shift
            ;;
         --description=*)
            DESCRIPTION="${1#*=}"
            shift
            ;;
        -*)
            echo -e "${RED}Error: Unknown option: $1${NC}"
            exit 1
            ;;
        *)
            if [ -z "$PROJECT_NAME" ]; then
                PROJECT_NAME="$1"
            else
                echo -e "${RED}Error: Too many arguments${NC}"
                exit 1
            fi
            shift
            ;;
    esac
done

# Show help
if [ "$HELP" = true ] || [ -z "$PROJECT_NAME" ]; then
    echo "Usage: poetry-new <project-name> [options]"
    echo ""
    echo "Options:"
    echo "  --python=VERSION            Python version (default: ^3.10)"
    echo "  --version=VERSION           Project initial version (default: 0.1.0)"
    echo "  --description=DESCRIPTION   Project short description"
    echo "  --no-install                Skip installing dependencies"
    echo "  --no-git                    Skip Git initialization"
    echo "  --github                    Create GitHub repository (requires gh CLI)"
    echo "  --template=PATH             Use a specific template path"
    echo "  -h, --help                  Show this help message"
    exit 0
fi

# Ensure the template exists
if [ ! -d "$TEMPLATE_PATH" ]; then
    echo -e "${RED}Error: Cookiecutter template not found at $TEMPLATE_PATH${NC}"
    exit 1
fi

# Generate project
echo -e "${YELLOW}Generating project structure...${NC}"
cookiecutter "$TEMPLATE_PATH" --no-input project_name="$PROJECT_NAME" python_version="$PYTHON_VERSION" version="$VERSION" description="$DESCRIPTION"|| {
    echo -e "${RED}Error: Failed to generate project${NC}"
    exit 1
}

# Ensure project was created
if [ ! -d "$PROJECT_NAME" ]; then
    echo -e "${RED}Error: Project '$PROJECT_NAME' was not created.${NC}"
    exit 1
fi

cd "$PROJECT_NAME" || exit 1

if [ "$INSTALL_DEPS" = true ]; then
    echo -e "${YELLOW}Installing dependencies...${NC}"
    poetry install || echo -e "${RED}Warning: Poetry install failed${NC}"
fi

if [ "$INIT_GIT" = true ]; then
    echo -e "${YELLOW}Initializing Git repository...${NC}"
    git init && git add . && git commit -m "Initial commit"

    if [ "$CREATE_GITHUB" = true ]; then
        echo -e "${YELLOW}Creating GitHub repository...${NC}"
        if command -v gh &> /dev/null; then
            gh repo create "$PROJECT_NAME" --private --source=. --remote=origin
            git push -u origin main || git push -u origin master
        else
            echo -e "${RED}GitHub CLI (gh) not installed. Skipping GitHub repository creation.${NC}"
        fi
    fi
fi

echo -e "${GREEN}Project '$PROJECT_NAME' has been successfully created!${NC}"
echo -e "To start working on your project:"
echo -e "  cd $PROJECT_NAME"
echo -e "  poetry shell"
