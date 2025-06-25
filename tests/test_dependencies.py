"""Test Poetry dependencies in the template."""

import subprocess
import toml
import pytest
import os

# Import inside_dir from conftest
from conftest import inside_dir


def test_pyproject_toml_valid(default_project):
    """Test that pyproject.toml is valid TOML."""
    # Use the project directory path
    pyproject_path = os.path.join(default_project.project_path, "pyproject.toml")

    try:
        with open(pyproject_path) as f:
            pyproject = toml.load(f)
    except Exception as e:
        pytest.fail(f"pyproject.toml is not valid TOML: {e}")

    # Check required sections
    assert "tool" in pyproject
    assert "poetry" in pyproject["tool"]
    assert "dependencies" in pyproject["tool"]["poetry"]

    # Check dependency groups
    assert "group" in pyproject["tool"]["poetry"]
    expected_groups = ["dev", "test", "lint", "typing", "docs"]
    for group in expected_groups:
        assert group in pyproject["tool"]["poetry"]["group"]


def test_poetry_check(default_project):
    """Test that Poetry can validate the pyproject.toml file."""
    with inside_dir(default_project.project_path):
        try:
            subprocess.run(["poetry", "check"], check=True, capture_output=True, text=True)
        except subprocess.CalledProcessError as e:
            pytest.fail(f"Poetry check failed: {e.stderr}")


def test_poetry_lock_generation(default_project):
    """Test that Poetry can generate a lock file."""
    with inside_dir(default_project.project_path):
        try:
            # Remove any existing lock file
            if os.path.exists("poetry.lock"):
                os.remove("poetry.lock")

            # Run lock command without the --no-update flag that doesn't exist in newer Poetry
            subprocess.run(["poetry", "lock"], check=True, capture_output=True)
            assert os.path.exists("poetry.lock")
        except subprocess.CalledProcessError as e:
            pytest.fail(f"Failed to generate poetry.lock: {e.stderr}")
