# Project Blueprint

## Overview

This is a Flutter application designed for real-time sensor data monitoring and prediction analysis. The app features a responsive and intuitive user interface with both light and dark modes, built with Material Design 3 components. It allows users to view live sensor readings, input manual parameters, and receive predictions. Authentication is handled via Firebase.

## Style, Design, and Features

### Authentication

*   **Login Page:** A clean and simple login page (`lib/login_page.dart`) allows users to sign in with their email and password using Firebase Authentication.
*   **Register Page:** A page for new users to register an account.
*   **Session Management:** The app maintains user sessions, displaying the user's email on the dashboard and providing a logout button.

### Theming and Appearance

*   **Material Design 3:** The app uses the latest Material You design principles for a modern look and feel.
*   **Color Scheme:** A dynamic color scheme is generated from a seed color (`Colors.blue`), creating harmonious light and dark themes.
*   **Theme Provider:** A `ThemeProvider` (`lib/theme_provider.dart`) manages the app's theme, allowing for future theme-related enhancements.

### Dashboard (`lib/dashboard_page.dart`)

*   **Real-time Sensor Data:**
    *   The dashboard displays real-time data for **Temperature** and **Humidity** streamed directly from Firebase Realtime Database.
    *   The UI handles loading, error, and no-data states gracefully.
    *   Sensor readings are displayed in visually distinct `SensorCard` widgets with corresponding icons.
*   **Manual Input Parameters:**
    *   A responsive wrap layout allows users to input various parameters, such as "Amount of Chicken," "Ammonia (ppm)," etc.
    *   Input fields are designed for numeric input and have a clean, modern appearance.
*   **Prediction Logic:**
    *   A "Calculate Prediction" button triggers a local prediction model.
    *   The model uses both real-time sensor data and manual inputs to calculate an estimated daily egg production.
    *   It provides a "Healthy" or "Danger" status and generates actionable recommendations based on the input values.
*   **Prediction Results:** The results, including status, recommendations, and predicted egg count, are displayed in a color-coded card.
*   **User Welcome Message:** The dashboard greets the logged-in user with their email address.

## Current Plan

*   The application is now focused on a single-screen dashboard experience for sensor monitoring and prediction.
*   Future enhancements could include more sophisticated prediction models, historical data visualization, or user profile management.
