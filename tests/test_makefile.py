"""Test Makefile targets in the generated project."""
import os
import subprocess
from contextlib import contextmanager


@contextmanager
def inside_project(project_result):
    """Change to the project directory."""
    old_dir = os.getcwd()
    try:
        os.chdir(project_result.project_path)
        yield
    finally:
        os.chdir(old_dir)


def test_makefile_exists(default_project):
    """Test that the Makefile exists."""
    assert os.path.exists(os.path.join(default_project.project_path, 'Makefile'))


def test_makefile_help(default_project):
    """Test that 'make help' runs successfully."""
    with inside_project(default_project):
        result = subprocess.run(
            ['make', 'help'],
            capture_output=True,
            text=True
        )
        assert result.returncode == 0
        
        # Check that common targets are listed in help
        help_text = result.stdout
        expected_targets = [
            'install', 'format', 'lint', 'test',
            'docs', 'build', 'publish'
        ]
        for target in expected_targets:
            assert target in help_text, f"Target '{target}' not found in make help"


def test_makefile_clean(default_project):
    """Test that 'make clean' runs successfully."""
    with inside_project(default_project):
        # Create some files/dirs that should be cleaned
        os.makedirs('dist', exist_ok=True)
        os.makedirs('.pytest_cache', exist_ok=True)
        
        result = subprocess.run(
            ['make', 'clean'],
            capture_output=True,
            text=True
        )
        assert result.returncode == 0
        
        assert not os.path.exists('dist')
        assert not os.path.exists('.pytest_cache')
