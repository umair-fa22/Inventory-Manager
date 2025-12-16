import pytest


def test_python_version():
    """Test that Python version is 3.7+"""
    import sys
    assert sys.version_info.major == 3
    assert sys.version_info.minor >= 7


def test_basic_math():
    """Basic test to verify pytest is working"""
    assert 1 + 1 == 2
    assert 10 * 2 == 20


def test_string_operations():
    """Test string operations"""
    text = "Inventory Manager"
    assert "Inventory" in text
    assert text.lower() == "inventory manager"
    assert len(text) > 0
