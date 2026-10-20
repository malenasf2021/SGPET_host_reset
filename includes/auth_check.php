<?php
// includes/auth_check.php
// Incluir este archivo al principio de cada dashboard para exigir sesión y rol correcto

// Mapeo entre el valor de "rol" guardado en la base (admin/docente/estudiante)
// y el nombre del panel correspondiente (dashboard_administrador.php, etc.)
function panel_de_rol($rol) {
    $mapa = [
        'admin'      => 'dashboard_administrador.php',
        'docente'    => 'dashboard_docente.php',
        'estudiante' => 'dashboard_estudiante.php',
    ];
    return $mapa[$rol] ?? 'index.html';
}

function requerir_sesion() {
    if (!isset($_SESSION['id_usuario']) || !isset($_SESSION['rol'])) {
        header('Location: index.html');
        exit;
    }
}

function requerir_rol($rol_esperado) {
    requerir_sesion();
    if ($_SESSION['rol'] !== $rol_esperado) {
        // Si intenta entrar a una vista que no le corresponde, lo mandamos a SU panel
        header('Location: ' . panel_de_rol($_SESSION['rol']));
        exit;
    }
}

// Para vistas compartidas por más de un rol (ej: reservar equipo, que
// pueden hacer tanto docentes como estudiantes, pero no el admin).
function requerir_rol_alguno($roles_permitidos) {
    requerir_sesion();
    if (!in_array($_SESSION['rol'], $roles_permitidos, true)) {
        header('Location: ' . panel_de_rol($_SESSION['rol']));
        exit;
    }
}
