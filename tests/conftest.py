# Test fixtures and utilities for the test suite
import pytest
import os


@pytest.fixture(scope="session", autouse=True)
def setup_test_env():
    """Set up test environment variables"""
    os.environ['MONGODB_URI'] = 'mongodb://localhost:27017'
    os.environ['PORT'] = '5000'
    os.environ['DATABASE'] = 'test_db'
    os.environ['COLLECTION'] = 'test_collection'
