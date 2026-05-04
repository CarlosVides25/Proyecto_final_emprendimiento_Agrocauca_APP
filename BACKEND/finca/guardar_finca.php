<?php
require_once __DIR__ . "/../config/conexion.php";

// verificar conexión
if ($conn->connect_error) {
    echo json_encode(["success" => false, "error" => "Error de conexión"]);
    exit;
}
//  recibir datos
$data = json_decode(file_get_contents("php://input"), true);

$id_finca = $data["id_finca"] ?? 0;
$nombre = $data['nombre'] ?? '';
$ubicacion = $data['ubicacion'] ?? '';
$area = $data['area'] ?? 0;
$id_usuario = $data['id_usuario'] ?? 0;
$eliminado = $data['eliminado'] ?? 0;

$result = $conn->query("SELECT id_finca FROM finca WHERE id_finca = $id_finca");

if ($result && $result->num_rows > 0) {

    // 🔄 UPDATE
    $sql = "UPDATE finca SET 
                nombre = '$nombre',
                ubicacion = '$ubicacion',
                area = $area,
                actualizado_fecha = NOW(),
                estado_sincronizacion= 1,
                eliminado= $eliminado
            WHERE id_finca = $id_finca";

    $accion = "actualizada";

} else {

    // INSERT
    $sql = "INSERT INTO finca 
            (nombre, ubicacion, area, id_usuario, fecha_creacion,creado_fecha,actualizado_fecha,estado_sincronizacion,eliminado)
            VALUES 
            ('$nombre', '$ubicacion', $area, $id_usuario, NOW(), NOW(), NOW(), 0, 0 )";

    $accion = "creada";
}

// Ejecutar
if ($conn->query($sql)) {
    echo json_encode([
        "success" => true,
        "message" => "Finca $accion correctamente"
    ]);
} else {
    echo json_encode([
        "success" => false,
        "error" => $conn->error
    ]);
}
