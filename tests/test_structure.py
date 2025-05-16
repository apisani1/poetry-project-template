"""Test the project structure is as expected."""
import os
import re


def path_in_output(result, *paths):
    """Join paths with the output directory."""
    return os.path.join(result.project_path, *paths)


def test_project_structure(default_project):
    """Test that all required files and directories exist."""
    # Basic project files
    expected_files = [
        'pyproject.toml',
        'README.md',
        'LICENSE',
        'Makefile',
        '.gitignore',
        '.readthedocs.yaml',
        'tests/__init__.py',
        'docs/conf.py',
        'docs/index.md',
        'docs/api/index.md',
        'docs/guides/index.md',
        '.github/workflows/docs.yml',
        '.github/workflows/release.yml',
    ]
    
    for file_path in expected_files:
        assert os.path.exists(path_in_output(default_project, file_path)), f"Missing file: {file_path}"

    # Package-specific file with dynamic package name
    package_name = os.path.basename(default_project.project_path).replace('-', '_').lower()
    assert os.path.exists(path_in_output(default_project, f'src/{package_name}/__init__.py')), \
        f"Missing package init file: src/{package_name}/__init__.py"


def test_src_structure(default_project):
    """Test that src directory has the correct structure."""
    # Get package name from project directory
    package_name = os.path.basename(default_project.project_path).replace('-', '_').lower()
    
    # Check src directory structure
    assert os.path.isdir(path_in_output(default_project, 'src')), "Missing src directory"
    assert os.path.isdir(path_in_output(default_project, f'src/{package_name}')), f"Missing package directory: src/{package_name}"
    assert os.path.exists(path_in_output(default_project, f'src/{package_name}/__init__.py')), \
        f"Missing __init__.py in package directory"
    
    # Check __init__.py content
    init_path = path_in_output(default_project, f'src/{package_name}/__init__.py')
    with open(init_path) as f:
        init_content = f.read()
    
    assert "__version__" in init_content, "Missing __version__ in __init__.py"


def test_documentation_structure(default_project):
    """Test that documentation directory has the correct structure."""
    # Check docs directory structure
    assert os.path.isdir(path_in_output(default_project, 'docs')), "Missing docs directory"
    assert os.path.isdir(path_in_output(default_project, 'docs/api')), "Missing docs/api directory"
    assert os.path.isdir(path_in_output(default_project, 'docs/guides')), "Missing docs/guides directory"
    assert os.path.exists(path_in_output(default_project, 'docs/conf.py')), "Missing docs/conf.py"
    assert os.path.exists(path_in_output(default_project, 'docs/index.md')), "Missing docs/index.md"
    assert os.path.exists(path_in_output(default_project, 'docs/Makefile')), "Missing docs/Makefile"
    
    # Check docs content
    with open(path_in_output(default_project, 'docs/index.md')) as f:
        index_content = f.read()
    
    assert "# my-project" in index_content or "# my_project" in index_content, "Project name not found in index.md"
    
    with open(path_in_output(default_project, 'docs/conf.py')) as f:
        conf_content = f.read()
    
    assert "sphinx" in conf_content, "Sphinx configuration missing in conf.py"
    assert "extensions" in conf_content, "Extensions configuration missing in conf.py"


def test_github_workflows(default_project):
    """Test that GitHub workflow files exist and have expected content."""
    # Check GitHub workflow files
    assert os.path.isdir(path_in_output(default_project, '.github/workflows')), "Missing .github/workflows directory"
    assert os.path.exists(path_in_output(default_project, '.github/workflows/docs.yml')), "Missing docs.yml workflow"
    assert os.path.exists(path_in_output(default_project, '.github/workflows/release.yml')), "Missing release.yml workflow"
    
    # Check workflow content
    with open(path_in_output(default_project, '.github/workflows/docs.yml')) as f:
        docs_workflow = f.read()
    
    assert "Documentation" in docs_workflow, "Missing workflow name in docs.yml"
    assert "actions/checkout" in docs_workflow, "Missing checkout action in docs.yml"
    
    with open(path_in_output(default_project, '.github/workflows/release.yml')) as f:
        release_workflow = f.read()
    
    assert "Release" in release_workflow, "Missing workflow name in release.yml"
    assert "tags: ['v*']" in release_workflow, "Missing tag trigger in release.yml"


def test_pyproject_toml_content(default_project):
    """Test that pyproject.toml contains expected content."""
    # Check pyproject.toml content
    with open(path_in_output(default_project, 'pyproject.toml')) as f:
        pyproject_content = f.read()
    
    # Basic checks
    assert "poetry-core" in pyproject_content, "Missing poetry-core in pyproject.toml"
    assert "tool.poetry" in pyproject_content, "Missing tool.poetry section in pyproject.toml"
    assert 'name = "my-project"' in pyproject_content, f"Project name not found in pyproject.toml"
    
    # Check tool configuration sections
    assert "tool.black" in pyproject_content, "Missing tool.black in pyproject.toml"
    assert "tool.flake8" in pyproject_content, "Missing tool.flake8 in pyproject.toml"
    assert "tool.mypy" in pyproject_content, "Missing tool.mypy in pyproject.toml"
    assert "tool.isort" in pyproject_content, "Missing tool.isort in pyproject.toml"


def test_makefile_content(default_project):
    """Test that Makefile contains expected targets."""
    with open(path_in_output(default_project, 'Makefile')) as f:
        makefile_content = f.read()
    
    # Check for common make targets
    expected_targets = [
        "install", 
        "format", 
        "lint", 
        "test", 
        "docs", 
        "build", 
        "publish"
    ]
    
    for target in expected_targets:
        assert re.search(rf"{target}\s*:", makefile_content), f"Missing '{target}' target in Makefile"


def test_custom_project_parameters(custom_project):
    """Test that custom project parameters are properly applied."""
    # Check custom project name in pyproject.toml
    with open(path_in_output(custom_project, 'pyproject.toml')) as f:
        pyproject_content = f.read()
    
    assert "test-project" in pyproject_content or "test_project" in pyproject_content, \
        "Custom project name not found in pyproject.toml"
    assert "Test User" in pyproject_content, "Custom author name not found in pyproject.toml"
    assert "test@example.com" in pyproject_content, "Custom email not found in pyproject.toml"
    assert "0.2.0" in pyproject_content, "Custom version not found in pyproject.toml"
    
    # Check custom project description in README
    with open(path_in_output(custom_project, 'README.md')) as f:
        readme_content = f.read()
    
    assert "A test project created for testing purposes" in readme_content, \
        "Custom description not found in README.md"
    
    # Check that package directory is created with correct name
    package_name = "test_project"  # Based on custom project name
    assert os.path.isdir(path_in_output(custom_project, f'src/{package_name}')), \
        f"Custom package directory not found: src/{package_name}"
