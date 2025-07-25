import os

# Absolute path to the project root directory
basedir = os.path.abspath(os.path.join(os.path.dirname(__file__), '..'))

class Config:
    SECRET_KEY = os.environ.get('SECRET_KEY') or 'a_very_secret_key_that_should_be_randomized'

    # Database configuration
    SQLALCHEMY_DATABASE_URI = os.environ.get('DATABASE_URL') or \
                              'sqlite:///' + os.path.join(basedir, 'app.db') # Explicitly put in project root
    SQLALCHEMY_TRACK_MODIFICATIONS = False

    # JWT Configuration
    JWT_SECRET_KEY = os.environ.get('JWT_SECRET_KEY') or 'super-secret-jwt-key-change-this'
    JWT_ACCESS_TOKEN_EXPIRES = os.environ.get('JWT_ACCESS_TOKEN_EXPIRES') or 3600 # 1 hour

    # Rate Limiting Configuration
    # Store limits in memory for simplicity (development)
    # For production, consider 'redis://localhost:6379' or 'memcached://localhost:11211'
    RATELIMIT_STORAGE_URI = os.environ.get('RATELIMIT_STORAGE_URI') or 'memory://'
    RATELIMIT_DEFAULT = os.environ.get('RATELIMIT_DEFAULT') or '200 per 15 minute' # Default global limit

    # Media Storage Configuration
    MEDIA_FOLDER = os.path.join(basedir, 'media') # Store media in a 'media' folder at the project root
    # Ensure the directory exists when the app starts
    if not os.path.exists(MEDIA_FOLDER):
        os.makedirs(MEDIA_FOLDER)