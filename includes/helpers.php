<?php
// includes/helpers.php
// Funciones compartidas para el módulo de reservas, préstamos, fallas,
// sanciones, notificaciones y auditoría (próxima etapa del proyecto,
// sobre las tablas ya creadas en la Entrega 4).

// ---------------------------------------------------------------------
// Auditoría: registra toda acción relevante del sistema.
// ---------------------------------------------------------------------
function registrar_log($conn, $id_usuario, $accion, $entidad, $id_entidad = null) {
    $stmt = $conn->prepare("INSERT INTO log_auditoria (id_usuario, accion, entidad, id_entidad) VALUES (?,?,?,?)");
    $stmt->bind_param('issi', $id_usuario, $accion, $entidad, $id_entidad);
    $stmt->execute();
}

// ---------------------------------------------------------------------
// Notificaciones: avisos que el usuario ve en su panel.
// ---------------------------------------------------------------------
function crear_notificacion($conn, $id_usuario, $tipo, $mensaje) {
    $stmt = $conn->prepare("INSERT INTO notificacion (id_usuario, tipo, mensaje) VALUES (?,?,?)");
    $stmt->bind_param('iss', $id_usuario, $tipo, $mensaje);
    $stmt->execute();
}

// ---------------------------------------------------------------------
// Sanciones: ¿el usuario tiene una restricción vigente hoy?
// Un usuario sancionado no puede generar nuevas reservas ni préstamos.
// ---------------------------------------------------------------------
function sancion_vigente($conn, $id_usuario) {
    $stmt = $conn->prepare("
        SELECT id_sancion, motivo, fecha_fin
        FROM sancion
        WHERE id_usuario = ? AND fecha_fin >= CURDATE()
        ORDER BY fecha_fin DESC LIMIT 1
    ");
    $stmt->bind_param('i', $id_usuario);
    $stmt->execute();
    $res = $stmt->get_result();
    return $res->num_rows === 1 ? $res->fetch_assoc() : null;
}

// Días de atraso entre la fecha esperada y la fecha real (o el momento actual).
function dias_atraso($fecha_esperada, $fecha_real = null) {
    $fin = $fecha_real ? new DateTime($fecha_real) : new DateTime();
    $esperada = new DateTime($fecha_esperada);
    if ($fin <= $esperada) return 0;
    return (int)$esperada->diff($fin)->days;
}

// ¿Ya se generó hoy un recordatorio de vencimiento para este préstamo?
// (evita mandar la misma notificación varias veces el mismo día)
function ya_notificado_hoy($conn, $entidad, $id_entidad, $accion) {
    $stmt = $conn->prepare("
        SELECT id_log FROM log_auditoria
        WHERE entidad = ? AND id_entidad = ? AND accion = ? AND DATE(fecha_hora) = CURDATE()
        LIMIT 1
    ");
    $stmt->bind_param('sis', $entidad, $id_entidad, $accion);
    $stmt->execute();
    return $stmt->get_result()->num_rows === 1;
}

// ---------------------------------------------------------------------
// Etiquetas y badges (mismo patrón visual que badge_disp/badge_cond)
// ---------------------------------------------------------------------
function label_reserva_estado($v) {
    $m = ['pendiente' => 'Pendiente', 'convertida' => 'Convertida', 'cancelada' => 'Cancelada', 'vencida' => 'Vencida'];
    return $m[$v] ?? $v;
}
function label_prestamo_estado($v) {
    $m = ['activo' => 'Activo', 'atrasado' => 'Atrasado', 'devuelto' => 'Devuelto'];
    return $m[$v] ?? $v;
}
function label_gravedad($v) {
    $m = ['leve' => 'Leve', 'media' => 'Media', 'grave' => 'Grave'];
    return $m[$v] ?? $v;
}
function label_notif_tipo($v) {
    $m = ['confirmacion_prestamo' => 'Préstamo', 'recordatorio_vencimiento' => 'Vencimiento', 'sancion' => 'Sanción', 'reserva' => 'Reserva'];
    return $m[$v] ?? $v;
}

function badge_html($valor, $prefijo, $label) {
    return '<span class="badge ' . $prefijo . '-' . htmlspecialchars($valor) . '">' . htmlspecialchars($label) . '</span>';
}
function badge_reserva($v) { return badge_html($v, 'res', label_reserva_estado($v)); }
function badge_prestamo($v) { return badge_html($v, 'pre', label_prestamo_estado($v)); }
function badge_gravedad($v) { return badge_html($v, 'grav', label_gravedad($v)); }
