#!.venv/bin/python3


from flask import Flask, jsonify, request, send_from_directory
from flask_cors import CORS
from pymongo import MongoClient
from bson import ObjectId
from dotenv import load_dotenv
import os
import redis
import json

# Load environment variables from .env file
load_dotenv()

# Get configuration from environment variables
# mongodb+srv://fa22bse137_db_user:<db_password>@cluster0.yyny9nm.mongodb.net/
# MONGODB_URI = os.getenv('MONGODB_URI')

MONGOUSR = os.getenv('MONGOUSR')
MONGOPASS = os.getenv('MONGOPASS')
# MONGODB_URI = f"mongodb+srv://{MONGOUSR}:{MONGOPASS}@cluster0.yyny9nm.mongodb.net/"
MONGODB_URI = os.getenv('MONGODB_URI')
REDIS_HOST = os.getenv('REDIS_HOST', 'localhost')
REDIS_PORT = int(os.getenv('REDIS_PORT', 6379))
REDIS_PASSWORD = os.getenv('REDIS_PASSWORD', None)
CACHE_TTL = int(os.getenv('CACHE_TTL', 300))  # 5 minutes default

DATABASE = os.getenv('DATABASE')
COLLECTION = os.getenv('COLLECTION')

if not MONGODB_URI:
    raise ValueError("MONGODB_URI is required (set in .env or environment)")

print(f"MONGODB: {MONGODB_URI} (length: {len(MONGODB_URI)})")
# print(f"Using port: {PORT}")
print(f"Using database: {DATABASE}")
print(f"Using collection: {COLLECTION}")
print(f"Redis host: {REDIS_HOST}:{REDIS_PORT}")

# Initialize Flask app
app = Flask(__name__, static_folder='static')
CORS(app)

# Connect to Redis
try:
    redis_client = redis.Redis(
        host=REDIS_HOST,
        port=REDIS_PORT,
        password=REDIS_PASSWORD,
        decode_responses=True,
        socket_connect_timeout=5
    )
    redis_client.ping()
    print(f"Connected to Redis → {REDIS_HOST}:{REDIS_PORT}")
except Exception as e:
    print(f"Redis connection error: {e}. Continuing without cache.")
    redis_client = None

# Connect to MongoDB
try:
    client = MongoClient(MONGODB_URI, serverSelectionTimeoutMS=10000)
    # Verify connection
    # client.admin.command('ping')  # Fails in dockerhub actions for some reason
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

# Cache helper functions
def get_from_cache(key):
    """Get data from Redis cache"""
    if redis_client is None:
        return None
    try:
        data = redis_client.get(key)
        return json.loads(data) if data else None
    except Exception as e:
        print(f"Cache get error: {e}")
        return None

def set_in_cache(key, value, ttl=CACHE_TTL):
    """Set data in Redis cache with TTL"""
    if redis_client is None:
        return False
    try:
        redis_client.setex(key, ttl, json.dumps(value))
        return True
    except Exception as e:
        print(f"Cache set error: {e}")
        return False

def invalidate_cache(pattern='items:*'):
    """Invalidate cache entries matching pattern"""
    if redis_client is None:
        return
    try:
        keys = redis_client.keys(pattern)
        if keys:
            redis_client.delete(*keys)
    except Exception as e:
        print(f"Cache invalidation error: {e}")

def publish_event(channel, event_type, data):
    """Publish event to Redis pub/sub for message queue"""
    if redis_client is None:
        return
    try:
        message = json.dumps({'type': event_type, 'data': data})
        redis_client.publish(channel, message)
    except Exception as e:
        print(f"Publish error: {e}")

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
        # Try to get from cache first
        cache_key = 'items:all'
        cached_data = get_from_cache(cache_key)
        if cached_data is not None:
            return jsonify(cached_data), 200
        
        # If not in cache, get from database
        items = list(collection.find({}))
        items = [serialize_item(item) for item in items]
        
        # Store in cache
        set_in_cache(cache_key, items)
        
        return jsonify(items), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

@app.route('/api/items/<id>', methods=['GET'])
def get_item(id):
    try:
        if not ObjectId.is_valid(id):
            return jsonify({'error': 'Invalid ID'}), 400
        
        # Try to get from cache first
        cache_key = f'items:{id}'
        cached_data = get_from_cache(cache_key)
        if cached_data is not None:
            return jsonify(cached_data), 200
        
        item = collection.find_one({'_id': ObjectId(id)})
        if not item:
            return jsonify({'error': 'Item not found'}), 404
        
        serialized_item = serialize_item(item)
        
        # Store in cache
        set_in_cache(cache_key, serialized_item)
        
        return jsonify(serialized_item), 200
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
        
        # Invalidate cache and publish event
        invalidate_cache('items:*')
        publish_event('inventory', 'item_created', item)
        
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
        
        # Invalidate cache and publish event
        invalidate_cache('items:*')
        publish_event('inventory', 'item_updated', update_data)
        
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
        
        # Invalidate cache and publish event
        invalidate_cache('items:*')
        publish_event('inventory', 'item_deleted', {'id': id})
        
        return jsonify({'message': 'Item deleted'}), 200
    except Exception as e:
        return jsonify({'error': str(e)}), 500

if __name__ == '__main__':
    PORT = int(os.getenv('PORT'))
    
    print(f"Server starting on port {PORT}")
    print(f"Click on the link to open in your browser: http://localhost:{PORT}")
    app.run(host='0.0.0.0', port=PORT)
