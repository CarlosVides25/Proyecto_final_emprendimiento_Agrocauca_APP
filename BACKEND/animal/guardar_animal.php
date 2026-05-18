<?php
require_once __DIR__ . "/../config/conexion.php";

$data = json_decode(file_get_contents("php://input"), true);
//  DATOS
$identificador = $data['identificador'] ?? '';
$tipo = $data['tipo'] ?? '';
$raza = $data['raza'] ?? '';
$edad = $data['edad'] ?? 0;
$peso = $data['peso'] ?? null;
$sexo = $data['sexo'] ?? '';
$proposito = $data['proposito'] ?? '';
$estado_reproductivo = $data['estado_reproductivo'] ?? '';
$gasto_mantenimiento = $data['gasto_mantenimiento'] ?? 0;
$precio_kilo = $data['precio_kilo'] ?? 0;
$estado = $data['estado'] ?? '';
$precio_compra = $data['precio_compra'] ?? 0;
$id_finca = $data['id_finca'] ?? 0;
$id_animal= $data['id_animal'] ?? 0;
$eliminado= $data['eliminado'] ?? 0;
$id_sincro = $data['id_sincro'] ?? 0;

// VALIDACIÓN
if ($identificador == '' || $tipo == '' || $id_finca == 0) {
    echo json_encode([
        "success" => false,
        "error" => "Datos incompletos"
    ]);
    exit;
}
// manejar nulls
if ($peso == '') $peso = NULL;
if ($precio_kilo == '') $precio_kilo = NULL;

$result = $conn->query("SELECT id_animal FROM animal WHERE id_animal = $id_animal");

if ($result && $result->num_rows > 0) {

    // UPDATE
    $sql = "UPDATE animal SET
            identificador = '$identificador',
            tipo = '$tipo',
            raza = '$raza',
            edad = $edad,
            peso = $peso,
            sexo = '$sexo',
            proposito = '$proposito',
            estado_reproductivo = '$estado_reproductivo',
            precio_kilo = $precio_kilo,
            estado = '$estado',
            precio_compra = $precio_compra,
            gasto_mantenimiento = '$gasto_mantenimiento',
            id_finca = $id_finca,
            estado_sincronizacion = 1,
            actualizado_fecha= NOW(),
            eliminado=$eliminado,
            id_sincro='$id_sincro'
        WHERE id_animal = $id_animal";

    $accion = "actualizado";

} else {

    $sql = "INSERT INTO animal (
            identificador,
            tipo,
            raza,
            edad,
            peso,
            sexo,
            proposito,
            estado_reproductivo,
            precio_kilo,
            estado,
            precio_compra,
            fecha_creacion,
            gasto_mantenimiento,
            id_finca,
            estado_sincronizacion,
            actualizado_fecha,
            eliminado,
            fecha_compra,
            id_sincro
        ) VALUES ('$identificador', 
                  '$tipo',
                  '$raza', 
                  $edad,
                  $peso, '$sexo', '$proposito', '$estado_reproductivo', $precio_kilo, '$estado', $precio_compra,NOW(),$gasto_mantenimiento, $id_finca,1,NOW(),0,NOW(),'$id_sincro')";

    $accion = "creado";
}
if ($conn->query($sql)) {

    // Si fue INSERT obtener nuevo ID
    if ($id_animal == 0) {
        $id_animal = $conn->insert_id;
    }

    // Obtener animal actualizado
    $consulta = $conn->query("
        SELECT *
        FROM animal
        WHERE id_animal = $id_animal
    ");

    $animal = $consulta->fetch_assoc();

    echo json_encode([
        "success" => true,
        "message" => "Animal $accion correctamente",
        "animal" => $animal
    ]);

} else {

    echo json_encode([
        "success" => false,
        "error" => $conn->error
    ]);
}

?>