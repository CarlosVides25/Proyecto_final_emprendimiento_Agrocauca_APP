<?php
require_once __DIR__ . "/../config/conexion.php";

try {
    $data = json_decode(file_get_contents("php://input"), true);
    $id = $data["id_animal"];

    $sql = "DELETE FROM animal WHERE id_animal = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $id);

    if ($stmt->execute()) {
        echo json_encode([
            "success" => true,
            "message" => "animal eliminado correctamente"
        ]);
    } else {
        throw new Exception("Error al eliminar");
    }


} catch (Exception $e) {
    echo json_encode([
        "success" => false,
        "message" => $e->getMessage()
    ]);
}