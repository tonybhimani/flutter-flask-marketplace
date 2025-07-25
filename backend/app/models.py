from app.extensions import db
from datetime import datetime

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(80), unique=True, nullable=False)
    email = db.Column(db.String(120), unique=True, nullable=False)
    password_hash = db.Column(db.String(128), nullable=False) # For hashed passwords
    first_name = db.Column(db.String(50), nullable=True)
    last_name = db.Column(db.String(50), nullable=True)
    phone_number = db.Column(db.String(20), nullable=True)
    created_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    updated_at = db.Column(db.DateTime, default=datetime.utcnow, onupdate=datetime.utcnow, nullable=False)

    # Relationship to Listing: A user can have many listings
    listings = db.relationship('Listing', backref='author', lazy='dynamic', cascade="all, delete-orphan")

    def __repr__(self):
        return f'<User {self.username}>'

class Listing(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    user_id = db.Column(db.Integer, db.ForeignKey('user.id'), nullable=False) # Foreign key to User
    title = db.Column(db.String(150), nullable=False)
    description = db.Column(db.Text, nullable=False)
    price = db.Column(db.Float, nullable=True) # Using Float for prices
    category = db.Column(db.String(50), nullable=True)
    location = db.Column(db.String(100), nullable=True)
    posted_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)
    valid_until = db.Column(db.DateTime, nullable=True)
    is_active = db.Column(db.Boolean, default=True, nullable=False)

    # Relationship to Media: A listing can have many media items
    media = db.relationship('Media', backref='listing_owner', lazy='dynamic', cascade="all, delete-orphan")

    def __repr__(self):
        return f'<Listing {self.title}>'

class Media(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    listing_id = db.Column(db.Integer, db.ForeignKey('listing.id'), nullable=False) # Foreign key to Listing
    filename = db.Column(db.String(255), nullable=False) # Store the UUID filename
    file_extension = db.Column(db.String(10), nullable=False)
    mimetype = db.Column(db.String(50), nullable=False)
    media_type = db.Column(db.String(20), nullable=False) # 'photo', 'video', 'document'
    order = db.Column(db.Integer, nullable=True) # For display order
    uploaded_at = db.Column(db.DateTime, default=datetime.utcnow, nullable=False)

    def __repr__(self):
        return f'<Media {self.filename}>'