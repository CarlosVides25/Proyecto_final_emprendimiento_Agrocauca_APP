<?php
// 🔹 Permitir peticiones desde Flutter (CORS)
header("Access-Control-Allow-Origin: *");
header("Access-Control-Allow-Headers: Content-Type");
header("Content-Type: application/json");
date_default_timezone_set('America/Bogota');
// Datos de conexión
$host = "localhost";
$user = "root";
$password = "rokka-25";
$dbname = "agrocauca";

// Crear conexión
$conn = new mysqli($host, $user, $password, $dbname);

// Verificar conexión
if ($conn->connect_error) {
    echo json_encode([
        "success" => false,
        "error" => "Error de conexión: " . $conn->connect_error
    ]);
    exit;
}

// 🔹 Configurar charset (MUY IMPORTANTE para tildes y ñ)
$conn->set_charset("utf8");
?>