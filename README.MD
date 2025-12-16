# Inventory Manager

A full-stack inventory management system with CRUD operations, MongoDB integration, and a modern web interface. Built with Python Flask.

## Features

- ✓ Add, view, update, and delete inventory items
- ✓ Real-time total value calculation
- ✓ Inline editing with live price updates
- ✓ RESTful API endpoints
- ✓ MongoDB backend with validation
- ✓ Responsive web UI
- ✓ Comprehensive test suite with pytest

## Quick Start

### Prerequisites

- Python 3.7+
- MongoDB (running locally or remote)
- pip

### Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/ud3v/Inventory-Manager.git
   cd Inventory-Manager
   ```

2. **Configure environment**
   
   Create a `.env` file in the root directory:
   ```env
   MONGODB_URI=mongodb://localhost:27017
   PORT=3000
   DATABASE=inventorydb
   COLLECTION=products
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Run the application**
   ```bash
   python main.py
   ```

5. **Access the application**
   
   Open your browser: http://localhost:3000

## Project Structure

```
Inventory-Manager/
├── main.py              # Flask server
├── mongomgr.py          # MongoDB utility manager
├── requirements.txt     # Python dependencies
├── pyproject.toml       # Python project config
├── pytest.ini           # Pytest configuration
├── .env                 # Environment variables
├── static/
│   ├── index.html       # Frontend UI
│   └── style.css        # Styling
└── tests/
    ├── __init__.py
    ├── conftest.py      # Test fixtures
    └── test_main.py     # Test suite
```

## API Endpoints

| Method | Endpoint | Description | Body |
|--------|----------|-------------|------|
| GET | `/api/items` | Get all items | - |
| GET | `/api/items/:id` | Get item by ID | - |
| POST | `/api/items` | Create new item | `{name, unitPrice, quantity}` |
| PUT | `/api/items/:id` | Update item | `{name, unitPrice, quantity}` |
| DELETE | `/api/items/:id` | Delete item | - |

### Example Request

```bash
curl -X POST http://localhost:3000/api/items \
  -H "Content-Type: application/json" \
  -d '{"name":"Laptop","unitPrice":899.99,"quantity":10}'
```

## MongoDB Manager

The `mongomgr.py` utility provides person/user management with duplicate validation:

```python
from mongomgr import MongoDBManager

manager = MongoDBManager()
if manager.connect():
    # Add person (validates email uniqueness)
    manager.add_person("John Doe", "john@example.com", age=30)
    
    # Check if exists
    if manager.person_exists("john@example.com"):
        print("Person found!")
    
    # Get person details
    person = manager.get_person("john@example.com")
    
    manager.close()
```

## Testing

Run the test suite with pytest:

```bash
# Run all tests
pytest

# Run with verbose output
pytest -v

# Run with coverage report
pytest --cov=. --cov-report=html

# View coverage report
open htmlcov/index.html
```

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `MONGODB_URI` | *required* | MongoDB connection string |
| `PORT` | `3000` | Server port |
| `DATABASE` | `inventorydb` | Database name |
| `COLLECTION` | `products` | Collection name |

## Development

```bash
# Install dependencies
pip install -r requirements.txt

# Run with auto-reload (debug mode)
python main.py

# Run tests
pytest -v

# Run tests with coverage
pytest --cov=. --cov-report=html
```

## Troubleshooting

**Connection Error**
- Verify MongoDB is running: `mongosh` or `mongo`
- Check `MONGODB_URI` in `.env` file
- Ensure network connectivity to MongoDB server

**Import Errors (Python)**
- Install dependencies: `pip install -r requirements.txt`
- Check Python version: `python --version` (requires 3.7+)

**Empty Items List**
- Check API endpoint: `curl http://localhost:3000/api/items`
- Verify MongoDB has data in the collection
- Check browser console for errors

**Port Already in Use**
- Change `PORT` in `.env` file
- Kill existing process: `lsof -ti:3000 | xargs kill`

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature-name`
3. Commit changes: `git commit -am 'Add feature'`
4. Push to branch: `git push origin feature-name`
5. Submit a pull request

## License

This project is open source and available under the MIT License.
