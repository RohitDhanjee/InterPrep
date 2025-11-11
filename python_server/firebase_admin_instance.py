import firebase_admin
from firebase_admin import credentials, firestore, storage

# Initialize Firebase Admin
cred = credentials.Certificate('./file.json')
default_app = firebase_admin.initialize_app(cred)

def get_firestore_instance():
    return firestore.client()

def get_storage_bucket():
    # Correct Bucket Name from your project
    return storage.bucket('interprep-585db.firebasestorage.app')