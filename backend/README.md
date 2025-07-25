# Backend – Flask API

This is the backend component of the full-stack marketplace app. It provides a RESTful API for managing users, listings, and media, with authentication and image handling built in.

---

## 🧩 Features

- User registration and login
- JWT-based authentication
- Create, update, and delete listings
- Upload, delete, and reorder listing images
- SQLite database with SQLAlchemy
- Flask Blueprints for modular API structure
- CORS enabled for Flutter frontend access

---

## 📁 Project Structure

```
backend/
├── app/
│   ├── __init__.py        # Initializes the Flask app and registers routes/extensions
│   ├── config.py          # Central configuration for environment, database, and secrets
│   ├── extensions.py      # Initializes Flask extensions (e.g., SQLAlchemy, JWT)
│   ├── models.py          # SQLAlchemy ORM models (User, Listing, Media, etc.)
│   ├── routes.py          # API endpoints for authentication, listings, and media
├── scripts/
│   ├── create_db.py       # Script to initialize the database schema
│   ├── seed_data.py       # Optional script to populate the database with sample data
├── .env                   # (You create this) Stores environment variables like SECRET_KEY
├── requirements.txt       # Python dependencies
├── run.py                 # Entry point for running the Flask server
└── README.md              # This file
```

---

## 📦 Requirements

- Python 3.10+
- pip
- virtualenv (optional but recommended)

---

## 🚀 Setup

1. Clone the repository and navigate to the backend folder:

```bash
cd backend
```

2. (Optional) Create and activate a virtual environment:

```bash
python -m venv venv
source venv/bin/activate      # On Windows: .\venv\Scripts\activate
```

3. Install dependencies:

```bash
pip install -r requirements.txt
```

4. Create database (optional seed)

```bash
cd scripts
python create_db.py           # Create database
python create_db.py --seed    # Add demo data
```

5. Run the development server:

```bash
python run.py
```

The API will be available at `http://127.0.0.1:5000/api`.

---

## 🌱 Environment Variables

You can configure the secret keys and database URL settings in a `.env` file:

```ini
SECRET_KEY='YOUR SECRET KEY'
DATABASE_URL='sqlite:///C:/YOUR_PATH/flutter-flask-marketplace/backend/app.db'
JWT_SECRET_KEY='YOUR JWT SECRET KEY'
```

Generate keys (inside Python shell):

```python
import secrets
print(secrets.token_hex(32))
```
