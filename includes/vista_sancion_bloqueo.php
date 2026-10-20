<?php
// includes/vista_sancion_bloqueo.php
// Se incluye desde reserva_form.php cuando sancion_vigente() detecta que
// el usuario logueado tiene una sanción activa hoy. Espera la variable
// $sancion (fila de la tabla sancion) y $rol ya definidas.
?>
<!DOCTYPE html>
<html lang="es">
<head>
<meta charset="UTF-8">
<title>SGPET - Sanción vigente</title>
<link rel="stylesheet" href="css/style.css">
</head>
<body>
    <div class="form-page">
        <h2>No podés reservar equipos</h2>
        <div class="sancion-aviso">
            Tenés una sanción vigente hasta el <?php echo date('d/m/Y', strtotime($sancion['fecha_fin'])); ?>.<br>
            Motivo: <?php echo htmlspecialchars($sancion['motivo']); ?>
        </div>
        <p class="nota">Mientras la sanción esté vigente no podés generar nuevas reservas ni préstamos. Consultá con un administrador si creés que se trata de un error.</p>
        <div class="acciones">
            <a href="<?php echo panel_de_rol($rol); ?>" class="btn btn-editar">Volver al panel</a>
        </div>
    </div>
</body>
</html>
