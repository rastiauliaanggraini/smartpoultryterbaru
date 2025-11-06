# Project Blueprint

## Overview

This is a Flutter application designed for real-time sensor data monitoring and prediction analysis. The app features a responsive and intuitive user interface with both light and dark modes, built with Material Design 3 components. It allows users to view live sensor readings, input manual parameters, and receive predictions. Authentication is handled via Firebase.

## Style, Design, and Features

### Authentication

*   **Login Page:** A clean and simple login page (`lib/login_page.dart`) allows users to sign in with their email and password using Firebase Authentication.
*   **Session Management:** The app maintains user sessions, displaying the user's email on the dashboard and providing a logout button.

### Theming and Appearance

*   **Material Design 3:** The app uses the latest Material You design principles for a modern look and feel.
*   **Color Scheme:** A dynamic color scheme is generated from a seed color (`Colors.blue`), creating harmonious light and dark themes.
*   **Typography:** Custom fonts are implemented using the `google_fonts` package (`Oswald` for display, `Roboto` for titles, and `Open Sans` for body text) to create a clear and readable text hierarchy.
*   **Theme Provider:** A `ThemeProvider` (`lib/theme_provider.dart`) manages the app's theme, allowing users to switch between light and dark modes.
*   **Dark Mode Toggle:** A toggle switch in the `SettingsPage` allows users to manually switch between light and dark themes.

### Navigation

*   **Bottom Navigation Bar:** The main dashboard features a bottom navigation bar for easy access to the Prediction, Settings, and Notifications pages.
*   **Page Routing:** Navigation between pages is handled with `Navigator.push` and `Navigator.pushReplacement` for a smooth user experience.

### Dashboard (`lib/dashboard_page.dart`)

*   **Real-time Sensor Data:**
    *   The dashboard displays simulated real-time data for **Temperature** and **Humidity**.
    *   Data is updated every 5 seconds to mimic a live feed.
    *   Sensor readings are displayed in visually distinct `SensorCard` widgets with corresponding icons.
*   **Manual Input Parameters:**
    *   A grid layout allows users to input various parameters, such as "Amount of Chicken," "Ammonia (ppm)," etc.
    *   Input fields are designed for numeric input and have a clean, modern appearance.
*   **Prediction Button:** A prominent "Calculate Prediction" button is available for users to initiate the prediction process (functionality to be implemented).
*   **User Welcome Message:** The dashboard greets the logged-in user with their email address.

### Settings (`lib/settings_page.dart`)

*   **Dark Mode Toggle:** A simple and intuitive switch allows users to enable or disable dark mode for the entire application.

### Notifications (`lib/notifications_page.dart`)

*   A placeholder page to display future notifications.

## Current Plan

*   **Implement Prediction Logic:** Connect the "Calculate Prediction" button to a backend or a local model to perform predictions based on the sensor data and manual inputs.
*   **Display Prediction Results:** Create a new UI to display the prediction results in a clear and understandable format.
*   **Enhance Notifications:** Implement a real notification system to alert users of important events or predictions.
*   **Improve Form Validation:** Add validation to the manual input fields to ensure data integrity.
