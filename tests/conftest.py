"""Pytest configuration for template tests."""
import os
import shutil
import tempfile
from contextlib import contextmanager

import pytest
from cookiecutter.main import cookiecutter


@contextmanager
def inside_dir(dirpath):
    """Execute code from inside the given directory."""
    old_path = os.getcwd()
    try:
        os.chdir(dirpath)
        yield
    finally:
        os.chdir(old_path)


@contextmanager
def bake_in_temp_dir(cookies, **kwargs):
    """Create a temporary directory and bake a cookiecutter template."""
    try:
        result = cookies.bake(
            extra_context=kwargs.get('extra_context', {})
        )
        
        if result.exception:
            raise result.exception
        
        yield result
    
    except Exception as e:
        # Log any exceptions for debugging
        print(f"Error baking template: {e}")
        raise

@pytest.fixture
def default_project(cookies):
    """Create a default project using the template."""
    with bake_in_temp_dir(cookies) as result:
        yield result


@pytest.fixture
def custom_project(cookies):
    """Create a customized project using the template."""
    context = {
        'project_name': 'test-project',
        'author_name': 'Test User',
        'email': 'test@example.com',
        'github_username': 'testuser',
        'version': '0.2.0',
        'description': 'A test project created for testing purposes',
        'python_version': '3.11',
    }
    with bake_in_temp_dir(cookies, extra_context=context) as result:
        yield result
