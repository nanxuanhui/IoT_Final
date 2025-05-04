# ESP32 Health Monitoring System

A comprehensive health monitoring system built with ESP32 microcontroller and iOS app.

## Demo Link

https://drive.google.com/drive/folders/1AjyDtbWgDChqLi7MwOfWCEQiP9K11T0d?usp=sharing

## Project Overview

This project consists of two main components:
1. ESP32-based sensor system
2. iOS monitoring application

### ESP32 Sensor System
- Monitors various health and environmental parameters
- Real-time data collection and transmission
- Fall detection capabilities
- Pose detection for elderly care

### iOS Application
- Real-time data visualization
- Historical data analysis
- Alert system for abnormal conditions
- User authentication and management

## Features

### Sensor Monitoring
- Heart Rate (BPM)
- Blood Oxygen (SpO2)
- Temperature
- Humidity
- Air Quality
- Flame Detection
- Fall Detection
- Pose Detection

### iOS App Features
- Real-time data display
- Historical data charts
- Threshold settings
- Alert notifications
- User authentication
- Data export

## Technical Stack

### Backend
- Python Flask
- SQLite database
- RESTful API
- WebSocket for real-time communication

### iOS App
- SwiftUI
- Combine framework
- Core Data
- Charts framework
- WebSocket client

## Installation

### Backend Setup
1. Install Python dependencies:
```bash
pip install -r requirements.txt
```

2. Initialize the database:
```bash
python init_db.py
```

3. Start the server:
```bash
python server.py
```

### iOS App Setup
1. Open the project in Xcode
2. Install dependencies using Swift Package Manager
3. Build and run the project

## Configuration

### Server Configuration
- Default port: 8888
- Database file: sensor_data.db
- Log file: esp32_server.log

### iOS App Configuration
- Server URL: http://localhost:8888
- Default thresholds:
  - Heart Rate: 60-100 BPM
  - Blood Oxygen: >95%
  - Temperature: 36.5-37.5°C
  - Air Quality: <100

## Usage

1. Start the backend server
2. Launch the iOS app
3. Log in with your credentials
4. Monitor real-time data
5. Set thresholds for alerts
6. View historical data

## Project Structure

```
ESP_Final/
├── ESP_Final/
│   ├── Models/
│   │   ├── SensorData.swift
│   │   └── User.swift
│   ├── Views/
│   │   ├── Auth/
│   │   │   ├── LoginView.swift
│   │   │   └── RegisterView.swift
│   │   ├── Settings/
│   │   │   └── ThresholdSettingsView.swift
│   │   └── MainTabView.swift
│   ├── ViewModels/
│   │   ├── SensorDataViewModel.swift
│   │   └── UserViewModel.swift
│   └── Utils/
│       └── WebSocketManager.swift
└── server/
    ├── server.py
    ├── requirements.txt
    └── sensor_data.db
```

## API Documentation

### Authentication
- POST /api/register - User registration
- POST /api/login - User login

### Sensor Data
- POST /api/post-data - Submit sensor data
- GET /api/get-data - Retrieve sensor data
- GET /api/ws - WebSocket connection

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- ESP32 development team
- SwiftUI and Combine framework
- Python Flask
- Charts framework 
