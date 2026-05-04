<?php
require_once __DIR__ . "/../config/conexion.php";


$data = json_decode(file_get_contents("php://input"), true);
$id_usuario = $data['usuario'] ?? 0;

$sql = "SELECT 
            a.id_animal,
            a.identificador,
            a.tipo,
            a.raza,
            a.edad,
            a.peso,
            a.sexo,
            a.proposito,
            a.estado_reproductivo,
            a.gasto_mantenimiento,
            a.precio_kilo,
            a.estado,
            a.precio_compra,
            a.fecha_creacion,
            a.id_finca,
            a.estado_sincronizacion,
            a.actualizado_fecha,
            a.fecha_compra,
            f.nombre AS nombre_finca
        FROM animal a
        INNER JOIN finca f ON a.id_finca = f.id_finca
        WHERE f.id_usuario = ?";

$stmt = $conn->prepare($sql);
$stmt->bind_param("i", $id_usuario);
$stmt->execute();

$result = $stmt->get_result();

$animales = [];

while ($row = $result->fetch_assoc()) {
    $animales[] = $row;
}

echo json_encode([
    "success" => true,
    "data" => $animales
]);


?>