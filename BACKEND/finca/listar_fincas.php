<?php
require_once __DIR__ . "/../config/conexion.php";


// Recibir ID del usuario (desde Flutter)
$data = json_decode(file_get_contents("php://input"), true);

$id_empresa = $data['id_empresa'];

$sql = "SELECT finca.*, COUNT(animal.id_animal) AS total_animales
FROM finca
LEFT JOIN animal ON animal.id_finca = finca.id_finca
WHERE finca.id_empresa = '$id_empresa' AND finca.eliminado=0
GROUP BY finca.id_finca";

$result = $conn->query($sql);

$fincas = [];

while ($row = $result->fetch_assoc()) {
    $fincas[] = $row;
}

echo json_encode($fincas);
?>