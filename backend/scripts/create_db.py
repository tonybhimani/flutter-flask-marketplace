import os
import sys

# Add project's root directory to the Python path (if necessary)
sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from app import create_app, db
from app.models import User, Listing, Media # Import all models
from seed_data import add_demo_data # Import seeding function

# Create application instance
app = create_app()

with app.app_context():
    # Delete existing database file if it exists, for a truly fresh start
    db_path = os.path.join(app.root_path, 'app.db') # Adjust 'app.db' if db file has a different name
    if os.path.exists(db_path):
        os.remove(db_path)
        print(f"Existing database file '{db_path}' deleted.")

    # Create all tables defined in the models
    db.create_all()
    print("Database tables created successfully!")

    # Optionally add demo data
    if '--seed' in sys.argv or '-s' in sys.argv:
        add_demo_data()
    else:
        print("Skipping demo data population. Run with 'python create_db.py --seed' to include demo data.")

print("Database setup process complete.")