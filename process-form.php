<?php
// Enable error reporting for debugging
error_reporting(E_ALL);
ini_set('display_errors', 1);

// Configuration for Cloud SQL
$connection_name = getenv('DB_HOST');
$db_user = getenv('DB_USER');
$db_pass = getenv('DB_PASS');
$db_name = getenv('DB_NAME');

// Unix socket for Cloud SQL
$socket = sprintf('/cloudsql/%s', $connection_name);

// Function to sanitize input
function sanitize_input($data) {
    $data = trim($data);
    $data = stripslashes($data);
    $data = htmlspecialchars($data);
    return $data;
}

// Initialize response array
$response = array(
    'success' => false,
    'message' => ''
);

try {
    // Validate that this is a POST request
    if ($_SERVER["REQUEST_METHOD"] != "POST") {
        throw new Exception("Invalid request method");
    }

    // Validate and sanitize input
    $name = isset($_POST["name"]) ? sanitize_input($_POST["name"]) : '';
    $email = isset($_POST["email"]) ? sanitize_input($_POST["email"]) : '';
    $message = isset($_POST["message"]) ? sanitize_input($_POST["message"]) : '';

    // Validate required fields
    if (empty($name) || empty($email) || empty($message)) {
        throw new Exception("All fields are required");
    }

    // Validate email
    if (!filter_var($email, FILTER_VALIDATE_EMAIL)) {
        throw new Exception("Invalid email format");
    }

    // Connect to database using unix socket
    $conn = new mysqli(null, $db_user, $db_pass, $db_name, null, $socket);

    // Check connection
    if ($conn->connect_error) {
        error_log("Connection failed: " . $conn->connect_error);
        throw new Exception("Database connection failed");
    }

    // Prepare and execute the SQL statement
    $stmt = $conn->prepare("INSERT INTO contact_submissions (name, email, message, submission_date) VALUES (?, ?, ?, NOW())");
    if (!$stmt) {
        error_log("Prepare failed: " . $conn->error);
        throw new Exception("Database prepare failed");
    }

    $stmt->bind_param("sss", $name, $email, $message);
    
    if ($stmt->execute()) {
        $response['success'] = true;
        $response['message'] = "Thank you for your message! We'll get back to you soon.";
    } else {
        error_log("Execute failed: " . $stmt->error);
        throw new Exception("Error saving your message");
    }

    // Close statement and connection
    $stmt->close();
    $conn->close();

} catch (Exception $e) {
    $response['message'] = $e->getMessage();
    error_log("Form submission error: " . $e->getMessage());
}

// Return JSON response
header('Content-Type: application/json');
echo json_encode($response);
