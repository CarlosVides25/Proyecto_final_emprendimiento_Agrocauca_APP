<?php
require_once __DIR__ . "/config/conexion.php";

$data = json_decode(file_get_contents("php://input"), true);


if (!isset($data['token'])) {
    echo json_encode(["success" => false, "message" => "Token no proporcionado"]);
    exit;
}

$token = $data['token'];

// Consulta con JOIN para traer datos del usuario según el token de la sesión
$sql = "SELECT u.id_usuario, u.nombre, u.correo,
        u.id_empresa, e.nombre AS nombre_empresa
        FROM sesiones s
        INNER JOIN usuario u ON s.id_usuario = u.id_usuario
        INNER JOIN empresa e ON e.id_empresa = u.id_empresa
        WHERE s.token = ?
        LIMIT 1";

$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $token);
$stmt->execute();
$res = $stmt->get_result();

if ($datos = $res->fetch_assoc()) {
    // Si el token es válido, devolvemos toda la info
    echo json_encode([
        "success" => true,
        "usuario" => $datos['id_usuario'],
        "nombre" => $datos['nombre'],
        "correo" => $datos['correo'],
        "nombre_empresa" => $datos['nombre_empresa'],
        "id_empresa" => $datos['id_empresa']
    ]);
} else {
    // Si el token no existe o expiró
    echo json_encode([
        "success" => false,
        "message" => "Sesión inválida"
    ]);
}
?>