from app import db
from app.models import User, Listing, Media
from app.extensions import bcrypt # Hash passwords
from datetime import datetime, timedelta

def add_demo_data():
    print("Seeding database...")

    # Clear existing data (for re-seeding)
    db.drop_all() # Drops all tables
    db.create_all() # Re-creates tables based on models
    # OR: to clear data without dropping tables
    # User.query.delete()
    # Listing.query.delete()
    # Media.query.delete()
    # db.session.commit()

    # Create Users
    print("Creating users...")
    user1_password_hash = bcrypt.generate_password_hash("password123").decode('utf-8')
    user2_password_hash = bcrypt.generate_password_hash("securepass").decode('utf-8')
    user3_password_hash = bcrypt.generate_password_hash("devpass").decode('utf-8')

    user1 = User(
        username="prof.farwell",
        email="farwell@example.com",
        password_hash=user1_password_hash,
        first_name="Professor",
        last_name="Farwell",
        phone_number="555-123-4567"
    )
    user2 = User(
        username="jane.doe",
        email="jane@example.com",
        password_hash=user2_password_hash,
        first_name="Jane",
        last_name="Doe",
        phone_number="555-987-6543"
    )
    user3 = User(
        username="john.smith",
        email="john@example.com",
        password_hash=user3_password_hash,
        first_name="John",
        last_name="Smith",
        phone_number="555-111-2222"
    )
    db.session.add_all([user1, user2, user3])
    db.session.commit()
    print(f"Added {User.query.count()} users.")

    # Create Listings
    print("Creating listings...")
    listing1 = Listing(
        user_id=user1.id,
        title="Vintage Telescope - Rare Find!",
        description="A classic brass telescope from the early 20th century. Perfect for stargazing enthusiasts or as a decorative piece. Minor wear and tear, optics in great condition.",
        price=750.00,
        category="Collectibles",
        location="Los Angeles, CA",
        posted_at=datetime.utcnow(),
        valid_until=datetime.utcnow() + timedelta(days=30),
        is_active=True
    )
    listing2 = Listing(
        user_id=user2.id,
        title="Handmade Ceramic Mug Set (4)",
        description="Beautifully crafted ceramic mugs, unique designs. Dishwasher and microwave safe. Perfect for coffee or tea lovers.",
        price=45.00,
        category="Home Goods",
        location="San Francisco, CA",
        posted_at=datetime.utcnow() - timedelta(days=5),
        valid_until=datetime.utcnow() + timedelta(days=25),
        is_active=True
    )
    listing3 = Listing(
        user_id=user1.id,
        title="Abstract Art Piece - 'Chaos Theory'",
        description="A striking large-scale painting exploring the beauty of mathematical chaos. Acrylic on canvas, 48x36 inches. Ideal for a modern living space or office. Created by Professor Farwell.",
        price=1200.00,
        category="Art",
        location="Pasadena, CA",
        posted_at=datetime.utcnow() - timedelta(days=10),
        valid_until=datetime.utcnow() + timedelta(days=20),
        is_active=True
    )
    listing4 = Listing(
        user_id=user3.id,
        title="Used Mountain Bike - Good Condition",
        description="Trek mountain bike, medium frame. Used for local trails, well maintained. Some scratches but fully functional. Great for beginners.",
        price=300.00,
        category="Sporting Goods",
        location="San Diego, CA",
        posted_at=datetime.utcnow() - timedelta(days=2),
        valid_until=datetime.utcnow() + timedelta(days=28),
        is_active=True
    )

    db.session.add_all([listing1, listing2, listing3, listing4])
    db.session.commit()
    print(f"Added {Listing.query.count()} listings.")


    # Create Media
    print("Creating media...")
    media1_l1 = Media(
    listing_id=listing1.id,
    filename="telescope_main.jpg",
        file_extension="jpg",
        mimetype="image/jpeg",
        media_type="photo",
        order=1
    )
    media2_l1 = Media(
        listing_id=listing1.id,
        filename="telescope_lens.jpg",
        file_extension="jpg",
        mimetype="image/jpeg",
        media_type="photo",
        order=2
    )
    media1_l2 = Media(
        listing_id=listing2.id,
        filename="mugs_set.jpg",
        file_extension="jpg",
        mimetype="image/jpeg",
        media_type="photo",
        order=1
    )
    media2_l2 = Media(
        listing_id=listing2.id,
        filename="mugs_closeup.jpg",
        file_extension="jpg",
        mimetype="image/jpeg",
        media_type="photo",
        order=2
    )
    media1_l3 = Media(
        listing_id=listing3.id,
        filename="chaos_theory_full.jpg",
        file_extension="jpg",
        mimetype="image/jpeg",
        media_type="photo",
        order=1
    )
    media2_l3 = Media(
        listing_id=listing3.id,
        filename="chaos_theory_detail.jpg",
        file_extension="jpg",
        mimetype="image/jpeg",
        media_type="photo",
        order=2
    )
    media3_l3 = Media(
        listing_id=listing3.id,
        filename="chaos_theory_video_tour.mp4",
        file_extension="mp4",
        mimetype="video/mp4",
        media_type="video",
        order=3
    )

    db.session.add_all([media1_l1, media2_l1, media1_l2, media2_l2, media1_l3, media2_l3, media3_l3])
    db.session.commit()
    print(f"Added {Media.query.count()} media items.")

    print("Database seeding complete!")