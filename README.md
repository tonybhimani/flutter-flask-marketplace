# flutter-flask-marketplace

A full-stack demo app for browsing and managing listings, built with Flutter and Flask.

This project includes a Python backend with a REST API and a Flutter frontend that runs on web and desktop (Windows). It features user authentication, media uploads, and dynamic listings with keyword search and filters.

---

## 🧩 Features

### ✅ Backend (Python + Flask)

- Built with Flask, SQLAlchemy, SQLite
- RESTful API endpoints (users, listings, media)
- JWT-based authentication
- Password hashing with `bcrypt`
- Rate limiting with Flask-Limiter
- Blueprint routing for modular code
- `.env` configuration support
- Scripts for database creation and optional seeding
- Secure media file storage (image and video)

### ✅ Frontend (Flutter)

- Responsive Flutter UI (Web, Windows desktop tested)
- User authentication (register, login, logout, delete account)
- Listings:
  - Browse with thumbnails
  - Search by keyword, category, price, or location
  - View images and videos (with controls: play, pause, stop, seek)
  - Create, edit, delete (only owner can edit/delete)
- Media handling:
  - Upload, delete, and reorder (long-press drag and move)
- Profile editing
- Authentication guards and validation

> ⚠️ Pagination is not yet implemented but planned for future versions.

---

## 📁 Project Structure

```
flutter-flask-marketplace/
├── backend/                   # Flask backend app (REST API, SQLite, image handling)
├── frontend/                  # Flutter frontend app (UI, media upload/view, user flows)
├── LICENSE                    # MIT license for the entire project
└── README.md                  # Root README with project overview and structure
```

---

## 🚀 Getting Started

### 1. Backend Setup (Flask)

#### a. Create `.env` file in `/backend` folder:

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

#### b. Set up virtual environment and install dependencies

```bash
cd backend
python -m venv venv
source venv/bin/activate      # On Windows: .\venv\Scripts\activate
pip install -r requirements.txt
```

#### c. Create database (optional seed)

```bash
cd backend/scripts
python create_db.py           # Create database
python create_db.py --seed    # Add dummy data
```

#### d. Run the API server

```bash
python run.py
```

Your API will be available at: `http://127.0.0.1:5000/api`

---

### 2. Frontend Setup (Flutter)

Ensure Flutter is installed and working (`flutter doctor`)

```bash
cd frontend
flutter pub get
flutter run -d chrome         # or edge or windows
```

To update the API base URL, open:
`frontend/lib/utils/constants.dart`

---

## 🔌 API Endpoints

| Endpoint        | Method | Description              |
| --------------- | ------ | ------------------------ |
| `/api/register` | POST   | Register a new user      |
| `/api/login`    | POST   | Log in and get JWT token |
| `/api/user`     | GET    | Get current user info    |
| `/api/listings` | CRUD   | Manage listings          |
| `/api/media`    | CRUD   | Upload and manage media  |

> Full routing logic lives in: `/backend/app/routes.py`

---

## 📸 Demo Preview

**Login and Authentication**
![Login](https://raw.githubusercontent.com/tonybhimani/flutter-flask-marketplace/refs/heads/media/marketplace_login.gif)

**Edit a Listing (Price Change)**
![Edit Listing](https://raw.githubusercontent.com/tonybhimani/flutter-flask-marketplace/refs/heads/media/marketplace_edit.gif)

**Upload Multiple Images**
![Upload Images](https://raw.githubusercontent.com/tonybhimani/flutter-flask-marketplace/refs/heads/media/marketplace_upload.gif)

**Reorder Images by Dragging**
![Reorder Images](https://raw.githubusercontent.com/tonybhimani/flutter-flask-marketplace/refs/heads/media/marketplace_reorder.gif)

**View Images in Media Gallery**
![Media Gallery](https://raw.githubusercontent.com/tonybhimani/flutter-flask-marketplace/refs/heads/media/marketplace_media.gif)

---

## 📌 Future Plans

- Add pagination for listings
- Implement refresh/login token support for persistent sessions
- Add "log out all devices" feature
- Explore mobile (Android/iOS) builds

---

## 🙌 Acknowledgments

This project was a way to get hands-on with Flutter for the frontend while using Python Flask on the backend, transitioning from my typical Laravel-based workflows. More improvements and side projects are on the way!

---

## 📄 License

MIT License. Feel free to use or build on it. Attribution is appreciated but not required.
