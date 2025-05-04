# T2
# server.py

from flask import Flask, request, jsonify, session
import json
import sqlite3
import re
import logging
import os
from datetime import datetime, timedelta
import shutil
import threading
import time
from flask_cors import CORS
from flask_sqlalchemy import SQLAlchemy
from routes.auth import auth
from routes.sensor import sensor
from models.user import User, db
from database import init_db
import hashlib
import jwt
from werkzeug.security import generate_password_hash, check_password_hash

logging.basicConfig(
    level=logging.DEBUG,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler('esp32_server.log', mode='a', encoding='utf-8'),
        logging.StreamHandler()
    ]
)
logger = logging.getLogger(__name__)

logging.getLogger('werkzeug').setLevel(logging.DEBUG)

app = Flask(__name__)

CORS(app, 
     resources={r"/*": {
         "origins": ["http://localhost:3000"],
         "methods": ["GET", "POST", "OPTIONS"],
         "allow_headers": ["Content-Type", "Authorization", "Accept"],
         "expose_headers": ["Content-Type", "Authorization"],
         "supports_credentials": True,
         "max_age": 3600
     }},
     supports_credentials=True
)

app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'your-secret-key')
app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///health_monitor.db'
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
app.config['SESSION_COOKIE_SECURE'] = False
app.config['SESSION_COOKIE_SAMESITE'] = 'Lax'
app.config['SESSION_COOKIE_HTTPONLY'] = True

init_db(app)
app.register_blueprint(auth, url_prefix='/api/auth')
app.register_blueprint(sensor, url_prefix='/api')

# New: User table initialization
USER_DB_NAME = 'sensor_data.db'
def init_user_table():
    conn = sqlite3.connect(USER_DB_NAME)
    cursor = conn.cursor()
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE NOT NULL,
            password_hash TEXT NOT NULL
        )
    ''')
    conn.commit()
    conn.close()

init_user_table()

# User registration endpoint
@app.route('/api/register', methods=['POST'])
def register():
    data = request.json
    username = data.get('username')
    password = data.get('password')
    if not username or not password:
        return jsonify({'error': 'Missing username or password'}), 400
    password_hash = generate_password_hash(password)
    try:
        with sqlite3.connect(USER_DB_NAME) as conn:
            cursor = conn.cursor()
            cursor.execute('INSERT INTO users (username, password_hash) VALUES (?, ?)', (username, password_hash))
            conn.commit()
        return jsonify({'message': 'User registered successfully', 'username': username})
    except sqlite3.IntegrityError:
        return jsonify({'error': 'Username already exists'}), 409
    except Exception as e:
        return jsonify({'error': str(e)}), 500

# User login endpoint
@app.route('/api/login', methods=['POST'])
def login():
    data = request.json
    username = data.get('username')
    password = data.get('password')
    conn = sqlite3.connect(USER_DB_NAME)
    cursor = conn.cursor()
    cursor.execute('SELECT password_hash FROM users WHERE username = ?', (username,))
    row = cursor.fetchone()
    conn.close()
    if row and check_password_hash(row[0], password):
        return jsonify({'message': 'Login successful', 'username': username})
    else:
        return jsonify({'error': 'Invalid username or password'}), 401

@app.errorhandler(404)
def not_found_error(error):
    return jsonify({"error": "Requested resource not found"}), 404

@app.errorhandler(500)
def internal_error(error):
    return jsonify({"error": "Internal server error"}), 500

@app.after_request
def after_request(response):
    return response

@app.route('/api/get-data', methods=['GET', 'OPTIONS'])
def get_data():
    if request.method == 'OPTIONS':
        return jsonify({'message': 'OK'})
    try:
        start_time = request.args.get('start_time', type=int)
        end_time = request.args.get('end_time', type=int)
        conn = sqlite3.connect(DB_NAME)
        cursor = conn.cursor()
        if start_time and end_time:
            cursor.execute("""
                SELECT temperature, humidity, bpm, ir, accX, accY, accZ, flameDigital, flameAnalog, gasDigital, gasAnalog, spo2, timestamp, created_at
                FROM sensor_data
                WHERE timestamp BETWEEN ? AND ?
                ORDER BY created_at DESC
            """, (start_time, end_time))
        else:
            cursor.execute("""
                SELECT temperature, humidity, bpm, ir, accX, accY, accZ, flameDigital, flameAnalog, gasDigital, gasAnalog, spo2, timestamp, created_at
                FROM sensor_data
                ORDER BY created_at DESC
                LIMIT 100
            """)
        rows = cursor.fetchall()
        conn.close()
        data_list = []
        for row in rows:
            data = {
                "temperature": row[0],
                "humidity": row[1],
                "bpm": row[2],
                "ir": row[3],
                "accX": row[4],
                "accY": row[5],
                "accZ": row[6],
                "flameDigital": row[7],
                "flameAnalog": row[8],
                "gasDigital": row[9],
                "gasAnalog": row[10],
                "spo2": row[11],
                "timestamp": row[12],
                "created_at": row[13]
            }
            data_list.append(data)
        return jsonify(data_list)
    except Exception as e:
        logger.error(f"Failed to read data: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500

DB_NAME = 'sensor_data.db'

@app.route('/api/post-data', methods=['POST'])
def receive_data():
    try:
        data = request.get_json()
        if not data:
            return jsonify({"error": "No valid JSON data provided"}), 400

        required_fields = ['temperature', 'humidity', 'timestamp']
        if not all(field in data for field in required_fields):
            logger.warning(f"Missing fields, received data: {data}")
            return jsonify({"error": "Missing required fields"}), 400

        try:
            data['timestamp'] = int(time.time())  # Timestamp in seconds
            conn = sqlite3.connect(DB_NAME)
            cursor = conn.cursor()
            cursor.execute("""
                CREATE TABLE IF NOT EXISTS sensor_data (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    temperature REAL,
                    humidity REAL,
                    bpm REAL,
                    ir INTEGER,
                    accX REAL,
                    accY REAL,
                    accZ REAL,
                    flameDigital INTEGER,
                    flameAnalog INTEGER,
                    gasDigital INTEGER,
                    gasAnalog INTEGER,
                    spo2 REAL,
                    timestamp INTEGER,
                    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                )
            """)
            cursor.execute("""
                INSERT INTO sensor_data (
                    temperature, humidity, bpm, ir,
                    accX, accY, accZ,
                    flameDigital, flameAnalog,
                    gasDigital, gasAnalog,
                    spo2,
                    timestamp
                ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
            """, (
                data.get('temperature'),
                data.get('humidity'),
                data.get('bpm'),
                data.get('ir'),
                data.get('accX'),
                data.get('accY'),
                data.get('accZ'),
                data.get('flameDigital'),
                data.get('flameAnalog'),
                data.get('gasDigital'),
                data.get('gasAnalog'),
                data.get('spo2'),
                data.get('timestamp')
            ))
            conn.commit()
            conn.close()
        except Exception as e:
            logger.error(f"Failed to save data: {str(e)}")
            return jsonify({"error": "Data save failed"}), 500
            
        return jsonify({"message": "Data received successfully"}), 201
    except Exception as e:
        logger.error(f"Failed to process data: {str(e)}")
        return jsonify({"error": "Internal server error"}), 500

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8888, debug=True)
