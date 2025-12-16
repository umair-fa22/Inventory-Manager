import pytest


def test_imports():
    """Test that main module can be imported"""
    try:
        import main
        assert main is not None
    except ImportError:
        pytest.skip("main.py requires MongoDB connection")


def test_flask_app_exists():
    """Test that Flask app is created"""
    import main
    assert main.app is not None
    assert hasattr(main.app, 'route')


def test_serialize_item():
    """Test the serialize_item helper function"""
    import main
    from bson import ObjectId
    
    test_item = {
        '_id': ObjectId(),
        'name': 'TestItem',
        'unitPrice': 10.0,
        'quantity': 5
    }
    
    result = main.serialize_item(test_item.copy())
    
    assert 'id' in result
    assert '_id' not in result
    assert result['name'] == 'TestItem'
    assert result['unitPrice'] == 10.0
    assert result['quantity'] == 5
