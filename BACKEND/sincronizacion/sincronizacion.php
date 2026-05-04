<?php
require_once "conexion.php";

if ($conn->connect_error) {
    echo json_encode(["success" => false, "error" => "Error de conexión"]);
    exit;
}

$data = json_decode(file_get_contents("php://input"), true);

$response = [
    "success" => true,
    "procesados" => []
];

$conn->begin_transaction();

try {

    // =========================
    // SINCRONIZAR FINCAS
    // =========================
    if (!empty($data['fincas'])) {
        foreach ($data['fincas'] as $f) {

            $id = intval($f['id_finca']);
            $nombre = $conn->real_escape_string($f['nombre']);
            $ubicacion = $conn->real_escape_string($f['ubicacion']);
            $area = floatval($f['area']);
            $usuario = intval($f['usuario_id']);
            $eliminado = intval($f['eliminado']);

            //  Verificar si existe
            $check = $conn->query("SELECT id_finca FROM finca WHERE id_finca = $id");

            if ($check->num_rows > 0) {

                // DELETE lógico
                if ($eliminado == 1) {
                    $conn->query("UPDATE finca SET eliminado = 1 WHERE id_finca = $id");
                } else {
                    // 🔄 UPDATE
                    $conn->query("
                        UPDATE finca SET
                            nombre = '$nombre',
                            ubicacion = '$ubicacion',
                            area = $area,
                            fecha_actualizacion = NOW()
                        WHERE id_finca = $id
                    ");
                }

            } else {
                // INSERT
                if ($eliminado == 0) {
                    $conn->query("
                        INSERT INTO finca 
                        (id_finca, nombre, ubicacion, area, id_usuario, fecha_creacion, eliminado)
                        VALUES
                        ($id, '$nombre', '$ubicacion', $area, $usuario, NOW(), 0)
                    ");
                }
            }

            $response["procesados"]["fincas"][] = $id;
        }
    }

    // =========================
    // SINCRONIZAR ANIMALES
    // =========================
    if (!empty($data['animales'])) {
        foreach ($data['animales'] as $a) {

            $id = intval($a['id_animal']);
            $identificador = $conn->real_escape_string($a['identificador']);
            $tipo = $conn->real_escape_string($a['tipo']);
            $raza = $conn->real_escape_string($a['raza']);
            $peso = floatval($a['peso']);
            $finca = intval($a['finca_id']);
            $eliminado = intval($a['eliminado']);

            $check = $conn->query("SELECT id_animal FROM animal WHERE id_animal = $id");

            if ($check->num_rows > 0) {

                if ($eliminado == 1) {
                    $conn->query("UPDATE animal SET eliminado = 1 WHERE id_animal = $id");
                } else {
                    $conn->query("
                        UPDATE animal SET
                            identificador = '$identificador',
                            tipo = '$tipo',
                            raza = '$raza',
                            peso = $peso,
                            fecha_actualizacion = NOW()
                        WHERE id_animal = $id
                    ");
                }

            } else {
                if ($eliminado == 0) {
                    $conn->query("
                        INSERT INTO animal
                        (id_animal, identificador, tipo, raza, peso, id_finca, fecha_creacion, eliminado)
                        VALUES
                        ($id, '$identificador', '$tipo', '$raza', $peso, $finca, NOW(), 0)
                    ");
                }
            }

            $response["procesados"]["animales"][] = $id;
        }
    }

    $conn->commit();

} catch (Exception $e) {
    $conn->rollback();
    $response["success"] = false;
    $response["error"] = $e->getMessage();
}

echo json_encode($response);
?>