<?php

require_once __DIR__ . "/../config/conexion.php";

header("Content-Type: application/json");

$data = json_decode(file_get_contents("php://input"), true);

$fincas = $data["fincas"] ?? [];
$animales = $data["animales"] ?? [];

$ultimaSync = $data["ultima_sincronizacion"] ?? "2000-01-01 00:00:00";

$id_empresa = intval($data["id_empresa"] ?? 0);

$tempIdsFincas = [];
$tempIdsAnimales = [];



// ======================================================
// 🔹 1. SINCRONIZAR FINCAS
// ======================================================

foreach ($fincas as $f) {

    $idFinca = intval($f["id_finca"]);
    $id_sincro = $f["id_sincro"];


    // ======================================================
    // 🔹 DELETE LÓGICO
    // ======================================================

    if (intval($f["eliminado"]) == 1) {

        $stmt = $conn->prepare("
            UPDATE finca
            SET eliminado = 1,
                actualizado_fecha = ?
            WHERE id_sincro = ?
        ");

        $stmt->bind_param(
            "ss",
            $f["actualizado_fecha"],
            $id_sincro
        );

        $stmt->execute();

        continue;
    }



    // ======================================================
    // 🔹 BUSCAR SI YA EXISTE POR id_sincro
    // ======================================================

    $stmt = $conn->prepare("
        SELECT id_finca, actualizado_fecha
        FROM finca
        WHERE id_sincro = ?
    ");

    $stmt->bind_param("s", $id_sincro);
    $stmt->execute();

    $resultado = $stmt->get_result();



    // ======================================================
    // 🔹 INSERT NUEVO
    // ======================================================

    if ($resultado->num_rows == 0) {

        $stmt = $conn->prepare("
            INSERT INTO finca(
                id_sincro,
                nombre,
                ubicacion,
                area,
                id_empresa,
                fecha_creacion,
                actualizado_fecha,
                eliminado
            )
            VALUES (?, ?, ?, ?, ?, ?, ?, 0)
        ");

        $stmt->bind_param(
            "sssdiss",
            $id_sincro,
            $f["nombre"],
            $f["ubicacion"],
            $f["area"],
            $f["id_empresa"],
            $f["fecha_creacion"],
            $f["actualizado_fecha"]
        );

        $stmt->execute();

        $nuevoId = $conn->insert_id;

        $tempIdsFincas[] = [
            "temp_id" => $idFinca,
            "nuevo_id" => $nuevoId,
            "id_sincro" => $id_sincro
        ];

        continue;
    }



    // ======================================================
    // 🔹 UPDATE EXISTENTE
    // ======================================================

    $serverData = $resultado->fetch_assoc();

    if (
        strtotime($f["actualizado_fecha"]) >
        strtotime($serverData["actualizado_fecha"])
    ) {

        $stmt = $conn->prepare("
            UPDATE finca
            SET
                nombre = ?,
                ubicacion = ?,
                area = ?,
                actualizado_fecha = ?,
                eliminado = ?
            WHERE id_sincro = ?
        ");

        $stmt->bind_param(
            "ssdsis",
            $f["nombre"],
            $f["ubicacion"],
            $f["area"],
            $f["actualizado_fecha"],
            $f["eliminado"],
            $id_sincro
        );

        $stmt->execute();
    }
}




// ======================================================
// 🔹 ACTUALIZAR IDS TEMPORALES EN ANIMALES
// ======================================================

foreach ($animales as &$a) {

    foreach ($tempIdsFincas as $map) {

        if ($a["id_finca"] == $map["temp_id"]) {
            $a["id_finca"] = $map["nuevo_id"];
        }
    }
}




// ======================================================
// 🔹 2. SINCRONIZAR ANIMALES
// ======================================================

foreach ($animales as $a) {

    $idAnimal = intval($a["id_animal"]);
    $id_sincro = $a["id_sincro"];



    // ======================================================
    // 🔹 DELETE
    // ======================================================

    if (intval($a["eliminado"]) == 1) {

        $stmt = $conn->prepare("
            UPDATE animal
            SET eliminado = 1,
                actualizado_fecha = ?
            WHERE id_sincro = ?
        ");

        $stmt->bind_param(
            "ss",
            $a["actualizado_fecha"],
            $id_sincro
        );

        $stmt->execute();

        continue;
    }



    // ======================================================
    // 🔹 BUSCAR EXISTENTE
    // ======================================================

    $stmt = $conn->prepare("
        SELECT id_animal, actualizado_fecha
        FROM animal
        WHERE id_sincro = ?
    ");

    $stmt->bind_param("s", $id_sincro);
    $stmt->execute();

    $resultado = $stmt->get_result();



    // ======================================================
    // 🔹 INSERT NUEVO
    // ======================================================

    if ($resultado->num_rows == 0) {

        $stmt = $conn->prepare("
            INSERT INTO animal(
                id_sincro,
                identificador,
                tipo,
                raza,
                edad,
                peso,
                sexo,
                proposito,
                estado_reproductivo,
                estado,
                id_finca,
                precio_compra,
                precio_kilo,
                gasto_mantenimiento,
                fecha_compra,
                fecha_creacion,
                actualizado_fecha,
                eliminado
            )
            VALUES (
                ?,?,?,?,?,?,?,?,?,?,
                ?,?,?,?,?,?,?,0
            )
        ");

        $stmt->bind_param(
            "ssssidssssidddsss",
            $id_sincro,
            $a["identificador"],
            $a["tipo"],
            $a["raza"],
            $a["edad"],
            $a["peso"],
            $a["sexo"],
            $a["proposito"],
            $a["estado_reproductivo"],
            $a["estado"],
            $a["id_finca"],
            $a["precio_compra"],
            $a["precio_kilo"],
            $a["gasto_mantenimiento"],
            $a["fecha_compra"],
            $a["fecha_creacion"],
            $a["actualizado_fecha"]
        );

        $stmt->execute();

        $nuevoId = $conn->insert_id;

        $tempIdsAnimales[] = [
            "temp_id" => $idAnimal,
            "nuevo_id" => $nuevoId,
            "id_sincro" => $id_sincro
        ];

        continue;
    }



    // ======================================================
    // 🔹 UPDATE EXISTENTE
    // ======================================================

    $serverData = $resultado->fetch_assoc();

    if (
        strtotime($a["actualizado_fecha"]) >
        strtotime($serverData["actualizado_fecha"])
    ) {

        $stmt = $conn->prepare("
            UPDATE animal
            SET
                identificador = ?,
                tipo = ?,
                raza = ?,
                edad = ?,
                peso = ?,
                sexo = ?,
                proposito = ?,
                estado_reproductivo = ?,
                estado = ?,
                precio_compra = ?,
                precio_kilo = ?,
                gasto_mantenimiento = ?,
                fecha_compra = ?,
                actualizado_fecha = ?,
                eliminado = ?
            WHERE id_sincro = ?
        ");

        $stmt->bind_param(
            "sssidssssdddssis",
            $a["identificador"],
            $a["tipo"],
            $a["raza"],
            $a["edad"],
            $a["peso"],
            $a["sexo"],
            $a["proposito"],
            $a["estado_reproductivo"],
            $a["estado"],
            $a["precio_compra"],
            $a["precio_kilo"],
            $a["gasto_mantenimiento"],
            $a["fecha_compra"],
            $a["actualizado_fecha"],
            $a["eliminado"],
            $id_sincro
        );

        $stmt->execute();
    }
}




// ======================================================
// 🔹 3. ENVIAR CAMBIOS DEL SERVIDOR
// ======================================================

$fincasServer = $conn->query("
    SELECT *
    FROM finca
    WHERE actualizado_fecha > '$ultimaSync'
    AND id_empresa = $id_empresa
")->fetch_all(MYSQLI_ASSOC);



$animalesServer = $conn->query("
    SELECT a.*
    FROM animal a
    INNER JOIN finca f
        ON a.id_finca = f.id_finca
    WHERE a.actualizado_fecha > '$ultimaSync'
    AND f.id_empresa = $id_empresa
")->fetch_all(MYSQLI_ASSOC);




// ======================================================
// 🔹 RESPUESTA
// ======================================================

echo json_encode([
    "success" => true,

    "temp_ids_fincas" => $tempIdsFincas,
    "temp_ids_animales" => $tempIdsAnimales,

    "fincas" => $fincasServer,
    "animales" => $animalesServer,

    "id_empresa" => $id_empresa,

    "server_time" => date("Y-m-d H:i:s")
]);

?>