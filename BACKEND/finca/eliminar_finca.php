<?php
require_once  __DIR__ . "/../config/conexion.php";
try {
    $data = json_decode(file_get_contents("php://input"), true);
    $id = $data["id_finca"];


    $sql = "DELETE FROM finca WHERE id_finca = ?";
    $stmt = $conn->prepare($sql);
    $stmt->bind_param("i", $id);

    if ($stmt->execute()) {
        echo json_encode([
            "success" => true,
            "message" => "Finca eliminada correctamente"
        ]);
    } else {
        throw new Exception("Error al eliminar");
    }

    $stmt->close();
    $conn->close();

} catch (Exception $e) {
    echo json_encode([
        "success" => false,
        "message" => $e->getMessage()
    ]);
}