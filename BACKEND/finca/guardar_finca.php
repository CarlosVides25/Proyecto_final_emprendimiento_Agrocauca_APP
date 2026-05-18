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
$id_empresa = $data['id_empresa'] ?? 0;
$eliminado = $data['eliminado'] ?? 0;
$id_sincro = $data['id_sincro'] ?? "";


$result = $conn->query("SELECT id_finca FROM finca WHERE id_finca = $id_finca");

if ($result && $result->num_rows > 0) {

    // 🔄 UPDATE
    $sql = "UPDATE finca SET 
                nombre = '$nombre',
                ubicacion = '$ubicacion',
                area = $area,
                actualizado_fecha = NOW(),
                estado_sincronizacion= 1,
                eliminado= $eliminado,
                id_sincro='$id_sincro'
            WHERE id_finca = $id_finca";

    $accion = "actualizada";

} else {

    // INSERT
    $sql = "INSERT INTO finca 
            (nombre, ubicacion, area, id_empresa, fecha_creacion,actualizado_fecha,estado_sincronizacion,eliminado,id_sincro)
            VALUES 
            ('$nombre', '$ubicacion', $area, $id_empresa, NOW(), NOW(), 1, 0, '$id_sincro' )";

    $accion = "creada";
}

// Ejecutar
if ($conn->query($sql)) {
    // Si fue INSERT obtener el nuevo ID
    if ($id_finca == 0) {
        $id_finca = $conn->insert_id;
    }

    // Obtener la finca actualizada
    $consulta = $conn->query("
        SELECT *
        FROM finca
        WHERE id_finca = $id_finca
    ");

    $finca = $consulta->fetch_assoc();
    echo json_encode([
        "success" => true,
        "message" => "Finca $accion correctamente",
        "finca" => $finca
    ]);
} else {
    echo json_encode([
        "success" => false,
        "error" => $conn->error
    ]);
}
