<?php
require_once "../config/conexion.php";

$data = json_decode(file_get_contents("php://input"), true);

$id_empresa = intval($data["id_empresa"]);

// =========================
// 🔹 RESUMEN GENERAL
// =========================
$resumen = $conn->query("
  SELECT 
    (SELECT COUNT(*) 
      FROM finca 
      WHERE id_empresa = $id_empresa 
      AND eliminado = 0
    ) AS total_fincas,

    (SELECT COUNT(*) 
      FROM animal a
      INNER JOIN finca f ON a.id_finca = f.id_finca
      WHERE f.id_empresa = $id_empresa
      AND a.eliminado = 0
      AND f.eliminado = 0
    ) AS total_animales
")->fetch_assoc();


// =========================
// 🔹 ANIMALES POR FINCA
// =========================
$fincas = $conn->query("
  SELECT 
    f.id_finca,
    f.nombre,

    COUNT(a.id_animal) AS total_animales,

    ROUND(AVG(a.peso),1) AS peso_promedio

  FROM finca f

  LEFT JOIN animal a 
    ON a.id_finca = f.id_finca
    AND a.eliminado = 0

  WHERE f.id_empresa = $id_empresa
    AND f.eliminado = 0

  GROUP BY f.id_finca

  ORDER BY total_animales DESC
")->fetch_all(MYSQLI_ASSOC);


// =========================
// 🔹 DISTRIBUCIÓN POR TIPO
// =========================
$tipo = $conn->query("
  SELECT 
    a.tipo,
    COUNT(*) AS total

  FROM animal a

  INNER JOIN finca f 
    ON a.id_finca = f.id_finca

  WHERE f.id_empresa = $id_empresa
    AND a.eliminado = 0
    AND f.eliminado = 0

  GROUP BY a.tipo

  ORDER BY total DESC
")->fetch_all(MYSQLI_ASSOC);


// =========================
// 🔹 DISTRIBUCIÓN POR SEXO
// =========================
$sexo = $conn->query("
  SELECT 
    a.tipo,
    a.sexo,
    COUNT(*) AS total

  FROM animal a

  INNER JOIN finca f 
    ON a.id_finca = f.id_finca

  WHERE f.id_empresa = $id_empresa
    AND a.eliminado = 0
    AND f.eliminado = 0

  GROUP BY a.tipo, a.sexo

  ORDER BY total DESC
")->fetch_all(MYSQLI_ASSOC);


// =========================
// 🔹 DISTRIBUCIÓN POR RAZA
// =========================
$raza = $conn->query("
  SELECT 
    a.tipo,
    a.raza,
    COUNT(*) AS total

  FROM animal a

  INNER JOIN finca f 
    ON a.id_finca = f.id_finca

  WHERE f.id_empresa = $id_empresa
    AND a.eliminado = 0
    AND f.eliminado = 0

  GROUP BY a.tipo, a.raza

  ORDER BY total DESC
")->fetch_all(MYSQLI_ASSOC);


// =========================
// 🔹 DISTRIBUCIÓN POR PROPÓSITO
// =========================
$proposito = $conn->query("
  SELECT 
    a.proposito,
    COUNT(*) AS total

  FROM animal a

  INNER JOIN finca f 
    ON a.id_finca = f.id_finca

  WHERE f.id_empresa = $id_empresa
    AND a.eliminado = 0
    AND f.eliminado = 0

  GROUP BY a.proposito

  ORDER BY total DESC
")->fetch_all(MYSQLI_ASSOC);


// =========================
// 🔹 DISTRIBUCIÓN POR ESTADO
// =========================
$estado = $conn->query("
  SELECT 
    a.estado,
    COUNT(*) AS total

  FROM animal a

  INNER JOIN finca f 
    ON a.id_finca = f.id_finca

  WHERE f.id_empresa = $id_empresa
    AND a.eliminado = 0
    AND f.eliminado = 0

  GROUP BY a.estado

  ORDER BY total DESC
")->fetch_all(MYSQLI_ASSOC);


// =========================
// 🔹 RESPUESTA FINAL
// =========================
echo json_encode([
  "success" => true,

  "resumen" => $resumen,

  "fincas" => $fincas,

  "distribucion" => [
    "tipo" => $tipo,
    "sexo" => $sexo,
    "raza" => $raza,
    "proposito" => $proposito,
    "estado" => $estado
  ]
]);

?>