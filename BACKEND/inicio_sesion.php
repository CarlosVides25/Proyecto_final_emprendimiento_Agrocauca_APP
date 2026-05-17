<?php
require_once __DIR__ . "/config/conexion.php";


// Recibir datos
$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data['correo']) || !isset($data['clave'])) {
    echo json_encode(["success" => false, "message" => "Faltan datos"]);
    exit;
}

$correo = $data['correo'];
$clave = $data['clave'];

// 1. Consulta: Traemos id, nombre y la contraseña para validar
// Ajusta 'id_usuario' si en tu tabla se llama solo 'id'
$sql = "SELECT 
u.id_usuario,
u.id_empresa,
u.nombre,
u.correo,
u.contrasena,
e.nombre as nombre_empresa
FROM usuario u
INNER JOIN empresa e ON e.id_empresa = u.id_empresa
WHERE correo = ?";
$stmt = $conn->prepare($sql);
$stmt->bind_param("s", $correo);
$stmt->execute();
$result = $stmt->get_result();

if ($user = $result->fetch_assoc()) {
    // 2. Validar contraseña (Comparación directa)
    if ($clave === $user['contrasena']) {
        $id_usuario = $user['id_usuario'];
        $nombre_usuario = $user['nombre'];
        $id_empresa = $user['id_empresa'];
        $nombre_empresa= $user['nombre_empresa'];
        // 3. Generar un token único
        $token = bin2hex(random_bytes(32));

        // 4. Guardar en la tabla sesiones
        $sql_token = "INSERT INTO sesiones (id_usuario, token) VALUES (?, ?)";
        $stmt_token = $conn->prepare($sql_token);
        $stmt_token->bind_param("is", $id_usuario, $token);
        
        if ($stmt_token->execute()) {
            // Enviamos todo lo que SessionManager.guardarSesion necesita
            echo json_encode([
                "success" => true,
                "token" => $token,
                "usuario" => $id_usuario,
                "nombre" => $nombre_usuario,
                "correo" => $correo,
                "id_empresa" => $id_empresa,
                "nombre_empresa" => $nombre_empresa,
            ]);
        } else {
            echo json_encode(["success" => false, "message" => "Error al crear la sesión"]);
        }
    } else {
        echo json_encode(["success" => false, "message" => "Contraseña incorrecta"]);
    }
} else {
    echo json_encode(["success" => false, "message" => "El correo no está registrado"]);
}

?>