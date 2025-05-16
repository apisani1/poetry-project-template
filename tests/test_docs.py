"""Test documentation generation in the project."""
import os
import subprocess
import pytest
from contextlib import contextmanager


@contextmanager
def in_project_dir(project_result):
    """Execute code from inside the generated project directory."""
    old_dir = os.getcwd()
    try:
        os.chdir(project_result.project_path)
        yield
    finally:
        os.chdir(old_dir)


def test_docs_generation(default_project):
    """Test that documentation can be generated with Sphinx."""
    # This test might be slow, so we'll make it explicit
    if os.environ.get('SKIP_SLOW_TESTS'):
        pytest.skip("Skipping slow documentation test")
    
    with in_project_dir(default_project):
        try:
            subprocess.run(
                ['poetry', 'install', '--with', 'docs'],
                check=True,
                capture_output=True
            )
            
            result = subprocess.run(
                ['make', 'docs'],
                capture_output=True,
                text=True
            )
            assert result.returncode == 0
            
            # Check that html was generated
            assert os.path.exists('docs/_build/html/index.html')
        except subprocess.CalledProcessError as e:
            pytest.fail(f"Documentation generation failed: {e.stderr}")


def test_docs_api_command(default_project):
    """Test that 'make docs-api' command exists."""
    with in_project_dir(default_project):
        with open('Makefile') as f:
            makefile_content = f.read()
        
        assert 'docs-api' in makefile_content
