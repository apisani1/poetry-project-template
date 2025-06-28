#!/bin/bash
set -eo pipefail

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

TEMPLATE_PATH="$HOME/.cookiecutters/poetry-template"
PROJECT_NAME=""
DESCRIPTION="A short description of the project"
PYTHON_VERSION="^3.10"
VERSION="0.1.0"
INSTALL_DEPS=true
INIT_GIT=true
CREATE_GITHUB=false
CREATE_SECRETS=false
ENV_FILE=".env"
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
        --secrets)
            CREATE_SECRETS=true
            shift
            ;;
        --env=*)
            ENV_FILE="${1#*=}"
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
    echo "  --secrets                   Create GitHub repository secrets from .env"
    echo "  --env=FILE                  Use specific .env file (default: .env)"
    echo "  --template=PATH             Use a specific template path"
    echo "  -h, --help                  Show this help message"
    echo ""
    echo "GitHub Secrets:"
    echo "  The script can automatically create these repository secrets:"
    echo "  - TEST_PYPI_TOKEN           Token for TestPyPI publishing"
    echo "  - PYPI_TOKEN                Token for PyPI publishing"
    echo "  - RTD_TOKEN                 Token for ReadTheDocs integration"
    echo ""
    echo "  These should be defined in your .env file as:"
    echo "  TEST_PYPI_TOKEN=pypi-..."
    echo "  PYPI_TOKEN=pypi-..."
    echo "  RTD_TOKEN=rtd_..."
    exit 0
fi

# Function to load environment variables from .env file
load_env_file() {
    local env_file="$1"

    if [ ! -f "$env_file" ]; then
        echo -e "${YELLOW}Warning: Environment file '$env_file' not found${NC}"
        return 1
    fi

    echo -e "${BLUE}Loading environment variables from $env_file...${NC}"

    # Export variables from .env file
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip empty lines and comments
        if [[ -z "$line" ]] || [[ "$line" =~ ^[[:space:]]*# ]]; then
            continue
        fi

        # Export the variable
        export "$line"
    done < "$env_file"

    return 0
}

# Function to create GitHub repository secrets
create_github_secrets() {
    local project_name="$1"

    echo -e "${YELLOW}Creating GitHub repository secrets...${NC}"

    # Required secrets for the poetry template
    local secrets=(
        "TEST_PYPI_TOKEN"
        "PYPI_TOKEN"
        "RTD_TOKEN"
    )

    local created_count=0
    local skipped_count=0

    for secret_name in "${secrets[@]}"; do
        # Get the value from environment variable
        local secret_value="${!secret_name}"

        if [ -z "$secret_value" ]; then
            echo -e "${YELLOW}  ⚠️  Skipping $secret_name (not defined in environment)${NC}"
            ((skipped_count++))
            continue
        fi

        # Create the secret in GitHub repository
        if echo "$secret_value" | gh secret set "$secret_name" --repo "$project_name"; then
            echo -e "${GREEN}  ✅ Created secret: $secret_name${NC}"
            ((created_count++))
        else
            echo -e "${RED}  ❌ Failed to create secret: $secret_name${NC}"
        fi
    done

    echo -e "${BLUE}Secrets summary: $created_count created, $skipped_count skipped${NC}"

    if [ $created_count -gt 0 ]; then
        echo -e "${GREEN}Repository secrets created successfully!${NC}"
        echo -e "${BLUE}You can view them at: https://github.com/$project_name/settings/secrets/actions${NC}"
    fi
}

# Function to check if gh CLI is available and authenticated
check_github_cli() {
    if ! command -v gh &> /dev/null; then
        echo -e "${RED}Error: GitHub CLI (gh) not installed.${NC}"
        echo -e "${YELLOW}Install it from: https://cli.github.com/${NC}"
        return 1
    fi

    if ! gh auth status &> /dev/null; then
        echo -e "${RED}Error: GitHub CLI not authenticated.${NC}"
        echo -e "${YELLOW}Run: gh auth login${NC}"
        return 1
    fi

    return 0
}

# Ensure the template exists
if [ ! -d "$TEMPLATE_PATH" ]; then
    echo -e "${RED}Error: Cookiecutter template not found at $TEMPLATE_PATH${NC}"
    exit 1
fi

# Load environment file if creating secrets
if [ "$CREATE_SECRETS" = true ]; then
    if ! load_env_file "$ENV_FILE"; then
        echo -e "${RED}Error: Cannot create secrets without environment file${NC}"
        exit 1
    fi
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

        if check_github_cli; then
            # Get the current GitHub username for the full repository name
            GITHUB_USERNAME=$(gh api user --jq .login)
            FULL_REPO_NAME="$GITHUB_USERNAME/$PROJECT_NAME"

            # Create the repository
            gh repo create "$PROJECT_NAME" --private --source=. --remote=origin
            git push -u origin main || git push -u origin master

            echo -e "${GREEN}GitHub repository created: https://github.com/$FULL_REPO_NAME${NC}"

            # Create secrets if requested
            if [ "$CREATE_SECRETS" = true ]; then
                create_github_secrets "$FULL_REPO_NAME"
            fi
        else
            echo -e "${RED}GitHub repository creation failed due to CLI issues.${NC}"
        fi
    elif [ "$CREATE_SECRETS" = true ]; then
        echo -e "${YELLOW}Warning: --secrets requires --github flag${NC}"
    fi
fi

echo -e "${GREEN}Project '$PROJECT_NAME' has been successfully created!${NC}"
echo -e "To start working on your project:"
echo -e "  cd $PROJECT_NAME"
echo -e "  poetry shell"

if [ "$CREATE_GITHUB" = true ] && [ "$CREATE_SECRETS" = false ]; then
    echo -e ""
    echo -e "${BLUE}💡 Tip: Add --secrets flag next time to automatically create repository secrets${NC}"
fi
