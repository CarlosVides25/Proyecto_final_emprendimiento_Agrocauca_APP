<?php

require_once __DIR__ . "/config/conexion.php";

header("Content-Type: application/json");

$data = json_decode(file_get_contents("php://input"), true);

$idUsuario = intval($data["id_usuario"]);
$id_empresa = intval($data["id_empresa"]);
// =========================
// USUARIO
// =========================

$usuario = $conn->query("
    SELECT *
    FROM usuario
    WHERE id_usuario = $idUsuario
")->fetch_assoc();

$empresa = $conn->query("
    SELECT *
    FROM empresa
    WHERE id_empresa = $id_empresa
")->fetch_assoc();



// =========================
// FINCAS
// =========================

$fincas = $conn->query("
    SELECT *
    FROM finca
    WHERE id_empresa = $id_empresa
")->fetch_all(MYSQLI_ASSOC);


// =========================
// ANIMALES
// =========================

$animales = $conn->query("
    SELECT a.*
    FROM animal a
    INNER JOIN finca f
        ON a.id_finca = f.id_finca
    WHERE f.id_empresa = $id_empresa
")->fetch_all(MYSQLI_ASSOC);


echo json_encode([
    "success" => true,
    "usuario" => $usuario,
    "empresa" => $empresa,
    "fincas" => $fincas,
    "animales" => $animales
]);