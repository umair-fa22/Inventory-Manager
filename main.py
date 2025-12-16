from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS
from pymongo import MongoClient
from bson import ObjectId
from dotenv import load_dotenv
import os

# Load environment variables from .env file
load_dotenv()

# Get configuration from environment variables
MONGODB_URI = os.getenv('MONGODB_URI')
PORT = int(os.getenv('PORT', '3000'))
DATABASE = os.getenv('DATABASE', 'inventorydb')
COLLECTION = os.getenv('COLLECTION', 'products')

if not MONGODB_URI:
    raise ValueError("MONGODB_URI is required (set in .env or environment)")

print(f"MONGODB: {MONGODB_URI} (length: {len(MONGODB_URI)})")
print(f"Using port: {PORT}")
print(f"Using database: {DATABASE}")
print(f"Using collection: {COLLECTION}")

# Initialize Flask app
app = Flask(__name__, static_folder='static')
CORS(app)

# Connect to MongoDB
try:
    client = MongoClient(MONGODB_URI, serverSelectionTimeoutMS=10000)
    # Verify connection
    client.admin.command('ping')
    print(f"Connected to MongoDB → {MONGODB_URI}")
    
    db = client[DATABASE]
    collection = db[COLLECTION]
except Exception as e:
    print(f"MongoDB connection error: {e}")
    raise

# Helper function to serialize MongoDB documents
def serialize_item(item):
    if item:
        item['id'] = str(item['_id'])
        del item['_id']
    return item

# Routes
@app.route('/')
def index():
    return send_from_directory('static', 'index.html')

@app.route('/static/<path:path>')
def serve_static(path):
    return send_from_directory('static', path)

# API Routes
@app.route('/api/items', methods=['GET'])
def get_items():
    try:
        items = list(collection.find({}))
        items = [serialize_item(item) for item in items]
        return jsonify(items), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/items/<id>', methods=['GET'])
def get_item(id):
    try:
        if not ObjectId.is_valid(id):
            return jsonify({'error': 'Invalid ID'}), 400
        
        item = collection.find_one({'_id': ObjectId(id)})
        if not item:
            return jsonify({'error': 'Item not found'}), 404
        
        return jsonify(serialize_item(item)), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/items', methods=['POST'])
def create_item():
    try:
        data = request.get_json()
        
        # Validation
        if not data.get('name') or data.get('unitPrice', -1) < 0 or data.get('quantity', -1) < 0:
            return jsonify({'error': 'Invalid data'}), 400
        
        item = {
            'name': data['name'],
            'unitPrice': data['unitPrice'],
            'quantity': data['quantity']
        }
        
        result = collection.insert_one(item)
        item['id'] = str(result.inserted_id)
        
        return jsonify(item), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/items/<id>', methods=['PUT'])
def update_item(id):
    try:
        if not ObjectId.is_valid(id):
            return jsonify({'error': 'Invalid ID'}), 400
        
        data = request.get_json()
        
        # Validation
        if not data.get('name') or data.get('unitPrice', -1) < 0 or data.get('quantity', -1) < 0:
            return jsonify({'error': 'Invalid data'}), 400
        
        update_data = {
            'name': data['name'],
            'unitPrice': data['unitPrice'],
            'quantity': data['quantity']
        }
        
        result = collection.update_one(
            {'_id': ObjectId(id)},
            {'$set': update_data}
        )
        
        if result.matched_count == 0:
            return jsonify({'error': 'Item not found'}), 404
        
        update_data['id'] = id
        return jsonify(update_data), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/items/<id>', methods=['DELETE'])
def delete_item(id):
    try:
        if not ObjectId.is_valid(id):
            return jsonify({'error': 'Invalid ID'}), 400
        
        result = collection.delete_one({'_id': ObjectId(id)})
        
        if result.deleted_count == 0:
            return jsonify({'error': 'Item not found'}), 404
        
        return jsonify({'message': 'Item deleted'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    print(f"Server starting on port {PORT}")
    print(f"Click on the link to open in your browser: http://localhost:{PORT}")
    app.run(host='0.0.0.0', port=PORT, debug=True)
