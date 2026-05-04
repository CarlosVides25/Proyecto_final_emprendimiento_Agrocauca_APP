<?php
require_once __DIR__ . "config/conexion.php";

$data = json_decode(file_get_contents("php://input"), true);

if (!isset($data["id_usuario"])) {
    echo json_encode([
        "success" => false,
        "message" => "Falta id_usuario"
    ]);
    exit;
}

$id_usuario = intval($data["id_usuario"]);


//  1. OBTENER USUARIO
$stmtUser = $conn->prepare("SELECT id_usuario, nombre, contrasena, correo FROM usuario WHERE id_usuario = ?");
$stmtUser->bind_param("i", $id_usuario);
$stmtUser->execute();
$resultUser = $stmtUser->get_result();
$usuario = $resultUser->fetch_assoc();


// 2. OBTENER FINCAS + TOTAL ANIMALES
$stmtFincas = $conn->prepare("
    SELECT 
        f.id_finca,
        f.nombre,
        f.ubicacion,
        f.area,
        f.id_usuario,
        f.fecha_creacion,
        f.actualizado_fecha,
        COUNT(a.id_animal) AS total_animales
    FROM finca f
    LEFT JOIN animal a ON a.id_finca = f.id_finca
    WHERE f.id_usuario = ?
    GROUP BY f.id_finca
");
$stmtFincas->bind_param("i", $id_usuario);
$stmtFincas->execute();
$resultFincas = $stmtFincas->get_result();

$fincas = [];
while ($row = $resultFincas->fetch_assoc()) {
    $fincas[] = $row;
}


// 3. OBTENER ANIMALES
$stmtAnimales = $conn->prepare("
    SELECT 
        a.id_animal,
        a.identificador,
        a.tipo,
        a.raza,
        a.edad,
        a.peso,
        a.id_finca,
        a.fecha_creacion,
        a.actualizado_fecha
    FROM animal a
    INNER JOIN finca f ON a.id_finca = f.id_finca
    WHERE f.id_usuario = ?
");
$stmtAnimales->bind_param("i", $id_usuario);
$stmtAnimales->execute();
$resultAnimales = $stmtAnimales->get_result();

$animales = [];
while ($row = $resultAnimales->fetch_assoc()) {
    $animales[] = $row;
}


// 🔹 RESPUESTA FINAL
echo json_encode([
    "success" => true,
    "usuario" => $usuario,
    "fincas" => $fincas,
    "animales" => $animales
]);

?>