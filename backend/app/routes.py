import os
import uuid # uuid for unique filenames
from flask import Blueprint, jsonify, request, abort, current_app
from app.models import User, Listing, Media
from app.extensions import db, bcrypt, jwt, limiter
from datetime import datetime
from flask_jwt_extended import create_access_token, jwt_required, get_jwt_identity
from sqlalchemy import or_ # Import or_ for OR conditions in queries
from werkzeug.utils import secure_filename # For sanitizing filenames

# Create a Blueprint named 'api'
bp = Blueprint('api', __name__)

# Allowed extensions for file uploads
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'gif', 'mp4', 'mov', 'avi'}

def allowed_file(filename):
    return '.' in filename and \
           filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS

def get_mimetype(filename):
    file_extension = os.path.splitext(filename)[1].lower()
    # default mime-type
    inferred_mimetype = "application/octet-stream"
    if file_extension in ['.mp4', '.avi', '.mov', '.webm', '.flv']: # Added common video formats
        inferred_mimetype = f'video/{file_extension.lstrip(".")}'
        # Special case: If it's .mov, mimetype is often 'video/quicktime'
        if file_extension == '.mov':
            inferred_mimetype = 'video/quicktime'
    elif file_extension in ['.jpg', '.jpeg', '.png', '.gif', '.bmp', '.webp', '.tiff', '.tif']: # Added common image formats
        inferred_mimetype = f'image/{file_extension.lstrip(".")}'
        if file_extension == '.jpeg': # Ensure consistency for jpeg
            inferred_mimetype = 'image/jpeg'
        elif file_extension == '.tiff' or file_extension == '.tif':
            inferred_mimetype = 'image/tiff'
    elif file_extension in ['.mp3', '.wav', '.ogg', '.flac']:
        inferred_mimetype = f'audio/{file_extension.lstrip(".")}'
    elif file_extension == '.pdf':
        inferred_mimetype = 'application/pdf'
    # return inferred (or application/octet-stream) mime-type
    return inferred_mimetype

# Helper function to serialize User objects to a dictionary
def user_to_dict(user):
    return {
        'id': user.id,
        'username': user.username,
        'email': user.email,
        'first_name': user.first_name,
        'last_name': user.last_name,
        'phone_number': user.phone_number,
        'created_at': user.created_at.isoformat(), # Convert datetime to ISO format string
        'updated_at': user.updated_at.isoformat()
    }

# Helper function to serialize Media objects to a dictionary
def media_to_dict(media_item):
    return {
        'id': media_item.id,
        'listing_id': media_item.listing_id,
        'filename': media_item.filename,
        'file_extension': media_item.file_extension,
        'mimetype': media_item.mimetype,
        'media_type': media_item.media_type,
        'order': media_item.order,
        'uploaded_at': media_item.uploaded_at.isoformat(),
        'url': f'/media/{media_item.listing_id}/{media_item.media_type}/{media_item.filename}',
    }

# Helper function to serialize Listing objects to a dictionary
def listing_to_dict(listing):
    author = user_to_dict(listing.author) if listing.author else None
    media_items = [media_to_dict(m) for m in listing.media.order_by(Media.order.asc()).all()]

    return {
        'id': listing.id,
        'user_id': listing.user_id,
        'title': listing.title,
        'description': listing.description,
        'price': listing.price,
        'category': listing.category,
        'location': listing.location,
        'posted_at': listing.posted_at.isoformat(),
        'valid_until': listing.valid_until.isoformat() if listing.valid_until else None,
        'is_active': listing.is_active,
        'author': author,
        'media': media_items
    }


# --- AUTHENTICATION ENDPOINTS ---

@bp.route('/register', methods=['POST'])
@limiter.limit("5 per hour") # Stricter limit for registration to prevent spam/abuse
def register():
    data = request.get_json()

    if not data or not data.get('username') or not data.get('email') or not data.get('password'):
        return jsonify({'message': 'Missing required fields: username, email, and password'}), 400

    if User.query.filter_by(username=data['username']).first():
        return jsonify({'message': 'Username already exists'}), 409
    if User.query.filter_by(email=data['email']).first():
        return jsonify({'message': 'Email already registered'}), 409

    hashed_password = bcrypt.generate_password_hash(data['password']).decode('utf-8')

    new_user = User(
        username=data['username'],
        email=data['email'],
        password_hash=hashed_password,
        first_name=data.get('first_name'),
        last_name=data.get('last_name'),
        phone_number=data.get('phone_number')
    )

    db.session.add(new_user)
    db.session.commit()

    # Create and return an access token upon successful registration
    access_token = create_access_token(identity=str(new_user.id))
    return jsonify(access_token=access_token, user=user_to_dict(new_user)), 201


@bp.route('/login', methods=['POST'])
@limiter.limit("10 per minute") # Stricter limit for login to prevent brute-force attacks
def login():
    username = request.json.get('username', None) # Can also use email
    password = request.json.get('password', None)

    if not username or not password:
        return jsonify({"msg": "Missing username or password"}), 400

    user = User.query.filter_by(username=username).first()
    if not user and '@' in username: # Also try to login with email if username not found
        user = User.query.filter_by(email=username).first()

    if not user or not bcrypt.check_password_hash(user.password_hash, password):
        # Return a generic error message for security, don't tell if username or password was wrong
        return jsonify({"msg": "Bad username or password"}), 401 # 401 Unauthorized

    # Create an access token for the user
    # Convert user.id to a string before passing it as identity
    access_token = create_access_token(identity=str(user.id)) # 'identity' can be any JSON-serializable data, typically user ID
    return jsonify(access_token=access_token)


# --- USER ENDPOINTS ---

@bp.route('/users', methods=['GET'])
# @limiter.limit("60 per hour")
def get_users():
    # In a real app, you might protect this or only allow admin access
    users = User.query.all()
    users_data = [user_to_dict(user) for user in users]
    return jsonify(users_data)

@bp.route('/users/<int:user_id>', methods=['GET'])
def get_user(user_id):
    user = User.query.get_or_404(user_id)
    return jsonify(user_to_dict(user))

@bp.route('/user', methods=['GET'])
@jwt_required() # Requires a valid JWT
@limiter.limit("60 per hour") # Limit fetching current user details
def get_current_user():
    current_user_id = int(get_jwt_identity()) # Get the ID of the logged-in user
    user = User.query.get_or_404(current_user_id) # Fetch the user from the database
    return jsonify(user_to_dict(user)), 200 # Return the user data

@bp.route('/user', methods=['PUT'])
@jwt_required() # Requires a valid JWT
@limiter.limit("60 per hour") # Limit updates
def update_user():
    current_user_id = int(get_jwt_identity()) # Get the ID of the logged-in user
    user = User.query.get_or_404(current_user_id) # Fetch the user from the database

    data = request.get_json()
    if not data:
        return jsonify({'message': 'No data provided for update'}), 400

    # Update fields if they are provided in the request body
    if 'username' in data:
        # Check if new username is unique and not current user's username
        if data['username'] != user.username and User.query.filter_by(username=data['username']).first():
            return jsonify({'message': 'Username already taken'}), 409
        user.username = data['username']

    if 'email' in data:
        # Check if new email is unique and not current user's email
        if data['email'] != user.email and User.query.filter_by(email=data['email']).first():
            return jsonify({'message': 'Email already registered'}), 409
        user.email = data['email']

    if 'password' in data and data['password']: # Ensure password is not empty
        user.password_hash = bcrypt.generate_password_hash(data['password']).decode('utf-8')

    if 'first_name' in data:
        user.first_name = data['first_name']
    if 'last_name' in data:
        user.last_name = data['last_name']
    if 'phone_number' in data:
        user.phone_number = data['phone_number']

    user.updated_at = datetime.utcnow() # Update the timestamp

    db.session.commit()
    return jsonify(user_to_dict(user)), 200 # Return the updated user data

@bp.route('/user', methods=['DELETE'])
@jwt_required() # Requires a valid JWT
@limiter.limit("5 per hour") # Stricter limit for account deletion
def delete_user():
    current_user_id = int(get_jwt_identity())
    user = User.query.get_or_404(current_user_id)

    db.session.delete(user)
    db.session.commit()

    # After deleting the user, invalidate their token and log them out
    # For token-based authentication like JWT, invalidating the token often means
    # adding it to a blacklist or just letting it expire. However, in this case,
    # since the user account is gone, their token is effectively useless.

    return jsonify({'message': 'Account and all associated data deleted successfully'}), 204 # No Content

# --- LISTING ENDPOINTS ---

@bp.route('/listings', methods=['GET'])
def get_listings():
    # Query all listings and then apply filters
    listings_query = Listing.query

    # Get search parameters from query string (request.args)
    search_query = request.args.get('q') # General keyword search
    category = request.args.get('category')
    location = request.args.get('location')
    min_price_str = request.args.get('min_price')
    max_price_str = request.args.get('max_price')

    # Apply filters based on parameters
    if search_query:
        # Search in title or description (case-insensitive)
        search_pattern = f"%{search_query}%"
        listings_query = listings_query.filter(
            or_(
                Listing.title.ilike(search_pattern),
                Listing.description.ilike(search_pattern)
            )
        )
    if category:
        listings_query = listings_query.filter(Listing.category.ilike(f"%{category}%"))
    if location:
        listings_query = listings_query.filter(Listing.location.ilike(f"%{location}%"))

    if min_price_str:
        try:
            min_price = float(min_price_str)
            listings_query = listings_query.filter(Listing.price >= min_price)
        except ValueError:
            # Handle invalid price format
            return jsonify({'message': 'Invalid min_price format'}), 400
    if max_price_str:
        try:
            max_price = float(max_price_str)
            listings_query = listings_query.filter(Listing.price <= max_price)
        except ValueError:
            # Handle invalid price format
            return jsonify({'message': 'Invalid max_price format'}), 400

    # Execute the query
    listings = listings_query.all()
    listings_data = [listing_to_dict(listing) for listing in listings]
    return jsonify(listings_data)

@bp.route('/listings/<int:listing_id>', methods=['GET'])
def get_listing(listing_id):
    listing = Listing.query.get_or_404(listing_id)
    return jsonify(listing_to_dict(listing))

@bp.route('/listings', methods=['POST'])
@jwt_required() # Requires a valid JWT
@limiter.limit("30 per hour") # Limit posting new listings
def create_listing():
    current_user_id = int(get_jwt_identity())
    data = request.get_json()

    if not data or not data.get('title') or not data.get('description'):
        return jsonify({'message': 'Missing required fields: title and description'}), 400

    new_listing = Listing(
        user_id=current_user_id, # Link listing to the authenticated user
        title=data['title'],
        description=data['description'],
        price=data.get('price'),
        category=data.get('category'),
        location=data.get('location'),
        valid_until=datetime.fromisoformat(data['valid_until']) if data.get('valid_until') else None,
        is_active=data.get('is_active', True) # Default to True
    )
    db.session.add(new_listing)
    db.session.commit()

    # If media data is sent, iterate and create Media objects
    if data.get('media') and isinstance(data['media'], list):
        for media_data in data['media']:
            if all(k in media_data for k in ['filename', 'file_extension', 'mimetype', 'media_type']):
                new_media = Media(
                    listing_id=new_listing.id,
                    filename=media_data['filename'],
                    file_extension=media_data['file_extension'],
                    mimetype=media_data['mimetype'],
                    media_type=media_data['media_type'],
                    order=media_data.get('order')
                )
                db.session.add(new_media)
        db.session.commit() # Commit again for media

    return jsonify(listing_to_dict(new_listing)), 201

@bp.route('/listings/<int:listing_id>', methods=['PUT'])
@jwt_required()
@limiter.limit("60 per hour") # Limit updates
def update_listing(listing_id):
    current_user_id = int(get_jwt_identity())
    listing = Listing.query.get_or_404(listing_id)
    data = request.get_json()

    # Authorization Check: Ensure the current user owns this listing
    if listing.user_id != current_user_id:
        return jsonify({'message': 'Unauthorized: You can only update your own listings'}), 403 # Forbidden

    # Update fields if provided in the request body
    if 'title' in data:
        listing.title = data['title']
    if 'description' in data:
        listing.description = data['description']
    if 'price' in data:
        listing.price = data['price']
    if 'category' in data:
        listing.category = data['category']
    if 'location' in data:
        listing.location = data['location']
    if 'valid_until' in data:
        # Allow clearing valid_until or setting it
        listing.valid_until = datetime.fromisoformat(data['valid_until']) if data['valid_until'] else None
    if 'is_active' in data:
        listing.is_active = data['is_active']

    # Update updated_at timestamp (explicitly, though onupdate should handle it too)
    listing.updated_at = datetime.utcnow()

    db.session.commit()
    return jsonify(listing_to_dict(listing)), 200 # OK


@bp.route('/listings/<int:listing_id>', methods=['DELETE'])
@jwt_required()
@limiter.limit("60 per hour") # Limit deletions
def delete_listing(listing_id):
    current_user_id = int(get_jwt_identity())
    listing = Listing.query.get_or_404(listing_id)

    # Authorization Check: Ensure the current user owns this listing
    if listing.user_id != current_user_id:
        return jsonify({'message': 'Unauthorized: You can only delete your own listings'}), 403 # Forbidden

    db.session.delete(listing)
    db.session.commit()

    return jsonify({'message': 'Listing deleted successfully'}), 204 # No Content

# --- MEDIA ENDPOINTS ---

@bp.route('/media', methods=['GET'])
def get_all_media():
    all_media = Media.query.all()
    media_data = [media_to_dict(media_item) for media_item in all_media]
    return jsonify(media_data)

@bp.route('/media/<int:media_id>', methods=['GET'])
def get_media_item(media_id):
    media_item = Media.query.get_or_404(media_id)
    return jsonify(media_to_dict(media_item))

@bp.route('/listings/<int:listing_id>/media', methods=['POST'])
@jwt_required()
def upload_listing_media(listing_id):
    current_user_id = int(get_jwt_identity())
    user = User.query.get(current_user_id)

    if not user:
        return jsonify({'message': 'User not found'}), 404

    listing = Listing.query.get(listing_id)
    if not listing:
        return jsonify({'message': 'Listing not found'}), 404

    # Ensure the user owns the listing
    if listing.user_id != user.id:
        return jsonify({'message': 'Unauthorized: You do not own this listing'}), 403

    # Check if files were sent in the request
    if 'files' not in request.files: # IMPORTANT: 'files' must match the key sent by Flutter
        return jsonify({'message': 'No file part in the request'}), 400

    uploaded_files = request.files.getlist('files') # Get a list of files
    if not uploaded_files:
        return jsonify({'message': 'No selected file'}), 400

    uploaded_media_data = []

    for file in uploaded_files:
        if file.filename == '':
            return jsonify({'message': 'No selected file for one of the uploads'}), 400

        if file and allowed_file(file.filename):
            original_filename = secure_filename(file.filename)
            file_extension = original_filename.rsplit('.', 1)[1].lower()
            mimetype = get_mimetype(file.filename) #file.mimetype
            print(f'WTF is the MIMETYPE {mimetype}')

            if mimetype.startswith('image/'):
                media_type = 'image'
            elif mimetype.startswith('video/'):
                media_type = 'video'
            else:
                return jsonify({'message': f'Unsupported file type: {mimetype}'}), 415 # Unsupported Media Type

            # Generate unique filename using UUID
            unique_filename = f"{uuid.uuid4()}.{file_extension}"

            # Define the specific directory for this listing and media type
            # Access MEDIA_FOLDER from current_app.config
            listing_media_dir = os.path.join(
                current_app.config['MEDIA_FOLDER'], # Correctly access the configured path
                str(listing_id),
                media_type # Use media_type as a subfolder ('image', 'video')
            )
            if not os.path.exists(listing_media_dir):
                os.makedirs(listing_media_dir)

            file_path = os.path.join(listing_media_dir, unique_filename)
            file.save(file_path)

            # Get the current max order for this listing's media
            max_order_result = db.session.query(db.func.max(Media.order)).filter_by(listing_id=listing_id).scalar()
            new_order = (max_order_result if max_order_result is not None else -1) + 1 # Start from 0 or 1

            # Save media info to database
            new_media = Media(
                listing_id=listing_id,
                filename=unique_filename, # Store the UUID filename
                file_extension=file_extension,
                mimetype=mimetype,
                media_type=media_type,
                order=new_order,
                uploaded_at=datetime.utcnow()
            )
            db.session.add(new_media)
            db.session.flush()

            uploaded_media_data.append(media_to_dict(new_media)) # Use the helper function
        else:
            return jsonify({'message': f'Unsupported file: {file.filename}'}), 415 # Unsupported File from Extension

    db.session.commit()

    return jsonify({
        'message': 'Files uploaded successfully!',
        'media': uploaded_media_data
    }), 201

@bp.route('/media/<int:media_id>', methods=['DELETE'])
@jwt_required()
@limiter.limit("60 per hour") # Limit deletions per user
def delete_media(media_id):
    current_user_id = int(get_jwt_identity())

    media_item = Media.query.get(media_id)
    if not media_item:
        return jsonify({'message': 'Media not found'}), 404

    # Fetch the associated listing to check ownership
    listing = Listing.query.get(media_item.listing_id)
    if not listing:
        # This case should ideally not happen if FK constraints are respected, but it's good for robustness.
        return jsonify({'message': 'Associated listing not found'}), 404

    # Authorization Check: Ensure the current user owns this listing (and thus its media)
    if listing.user_id != current_user_id:
        return jsonify({'message': 'Unauthorized: You can only delete media from your own listings'}), 403 # Forbidden

    # Construct the full path to the file on the server
    # This path logic should match how files are saved in upload_listing_media
    media_path = os.path.join(
        current_app.config['MEDIA_FOLDER'],
        str(media_item.listing_id),
        media_item.media_type,
        media_item.filename
    )

    # Delete the physical file from the server
    if os.path.exists(media_path):
        try:
            os.remove(media_path)
        except OSError as e:
            # Log the error but don't prevent DB deletion if file deletion fails
            # This ensures DB is consistent even if file system has issues
            current_app.logger.error(f"Error deleting file {media_path}: {e}")
            # Maybe return a 500 here if file deletion is critical
            # return jsonify({'message': f'Failed to delete file on server: {e}'}), 500

    # Delete the media record from the database
    db.session.delete(media_item)
    db.session.commit()

    return jsonify({'message': 'Media deleted successfully'}), 204 # No Content, successful deletion

@bp.route('/listings/<int:listing_id>/media/order', methods=['PUT'])
@jwt_required()
def media_order(listing_id):
    current_user_id = int(get_jwt_identity())
    user = User.query.get(current_user_id)

    if not user:
        return jsonify({'message': 'User not found'}), 404

    listing = Listing.query.get(listing_id)
    if not listing:
        return jsonify({'message': 'Listing not found'}), 404

    # Ensure the user owns the listing
    if listing.user_id != user.id:
        return jsonify({'message': 'Unauthorized: You do not own this listing'}), 403

    data = request.get_json()

    # Data Validation: Check if 'media_ids' is present and is a list
    if not data or 'media_ids' not in data:
        return jsonify({'message': 'Missing required field: media_ids'}), 400

    media_ids_ordered = data['media_ids']

    if not isinstance(media_ids_ordered, list):
        return jsonify({'message': 'Invalid data type for media_ids: must be a list'}), 400

    # Further validation: Ensure all items in the list are integers
    if not all(isinstance(mid, int) for mid in media_ids_ordered):
        return jsonify({'message': 'Invalid data type in media_ids: all elements must be integers'}), 400

    # Optional but recommended: Check if the number of IDs matches existing media
    # This helps catch cases where IDs are missing or extra IDs are sent.
    existing_media_count = listing.media.count()
    if len(media_ids_ordered) != existing_media_count:
        # This might be an issue if media was deleted but not yet synced, or extra IDs were sent.
        # If media was deleted client-side, make sure the frontend sends only the remaining IDs.
        print(f"Warning: Received {len(media_ids_ordered)} media IDs, but listing has {existing_media_count} existing media items.")
        # return jsonify({'message': 'Mismatch in media item count'}), 400 # Uncomment to enforce strict match

    # Fetch all media for this listing to efficiently update
    # Create a dictionary for quick lookup by ID
    listing_media = {m.id: m for m in listing.media.all()} # .all() here is fine as we need all for comparison

    updated_count = 0
    try:
        # Iterate through the ordered list and update 'order' for each media item
        for index, media_id in enumerate(media_ids_ordered):
            media_item = listing_media.get(media_id) # Get media item by ID from our lookup dict

            # Validate that the media_id belongs to this listing
            if not media_item or media_item.listing_id != listing.id:
                # This could happen if a malicious user tries to include a media_id
                # that doesn't belong to this listing or doesn't exist.
                # It's important to not update arbitrary media items.
                print(f"Attempted to update non-existent or unassociated media_id: {media_id}")
                # Possibly choose to return an error, or just skip it.
                # Skipping allows partial updates if some IDs are invalid, but success for valid ones.
                continue

            # Update the order
            if media_item.order != index: # Only update if order actually changed
                media_item.order = index
                updated_count += 1
                db.session.add(media_item) # Mark for update

        # Commit all changes in a single transaction
        db.session.commit()

        # If strictly enforcing `media_ids_ordered` matches `listing.media.all()`
        # and some IDs were missing from `media_ids_ordered` that still existed on the listing,
        # their 'order' values wouldn't be updated, which might be undesired.
        # The current approach updates only the provided IDs.

        return jsonify({'message': f'Media order updated successfully. {updated_count} items updated.'}), 200 # Changed to 200 OK

    except Exception as e:
        db.session.rollback() # Rollback changes if any error occurs
        print(f"Error updating media order: {e}")
        return jsonify({'message': f'Internal Server Error: Could not update media order. {str(e)}'}), 500