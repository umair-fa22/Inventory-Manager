Inventory Manager
=================

Simple inventory CRUD app built with Go, Gin, MongoDB, and a lightweight HTML/JS frontend. Add, edit, and delete items while tracking total value in real time.

Quick Start
-----------
1. Prereqs: Go 1.23+, running MongoDB, curl (optional for API checks).
2. Clone & enter: `git clone https://github.com/ud3v/Inventory-Manager.git && cd Inventory-Manager`
3. Configure env (create `.env` or export vars):
	 - `MONGODB_URI` (required) – e.g. `mongodb://localhost:27017`
	 - `PORT` (default `3000`)
	 - `DATABASE` (default `inventorydb`)
	 - `COLLECTION` (default `products`)
4. Run the server: `go run main.go`
5. Open the UI: http://localhost:3000

API Reference
-------------
- `GET /api/items` – list all items
- `GET /api/items/:id` – get one item by ObjectID
- `POST /api/items` – create `{ name, unitPrice, quantity }`
- `PUT /api/items/:id` – update `{ name, unitPrice, quantity }`
- `DELETE /api/items/:id` – remove item

Example create request:

```bash
curl -X POST http://localhost:3000/api/items \
	-H "Content-Type: application/json" \
	-d '{"name":"Notebook","unitPrice":5.5,"quantity":3}'
```

Frontend Usage
--------------
- Add items with name, unit price, and quantity from the form at the top.
- Click **Edit** to inline-edit price, quantity, or name; **Save** or **Cancel** to commit/undo.
- Click **Delete** to remove an item.
- Total inventory value updates automatically.

Project Structure
-----------------
- `main.go` – Gin server, MongoDB connection, REST handlers.
- `static/index.html` – single-page UI consuming the API.
- `static/style.css` – styling for layout and interactions.

Development Notes
-----------------
- The server loads `.env` if present; logs a notice when missing.
- Mongo connection is checked with `Ping`; server exits if `MONGODB_URI` is unset.
- Default database/collection/port values are used when env vars are absent.

Troubleshooting
---------------
- Connection error on startup: verify `MONGODB_URI` and that MongoDB is running.
- Empty UI list: ensure the API is reachable at `/api/items`; check server logs for errors.
