-- =====================================================================
-- SGPET - REINICIO COMPLETO de la base de datos (hosting / InfinityFree)
-- Deja la base exactamente como el estado inicial: borra TODAS las tablas
-- (incluyendo préstamos, reservas, fallas, sanciones, notificaciones y
-- auditoría generados durante las pruebas) y las vuelve a crear con los
-- usuarios y equipos de prueba originales.
--
-- USO: phpMyAdmin -> elegir tu base (if0_..._sgpet) -> pestaña "Importar"
--      -> seleccionar este archivo. No hace falta vaciar nada antes.
-- ADVERTENCIA: borra todos los datos actuales. No se puede deshacer.
-- =====================================================================

SET NAMES utf8mb4;
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS log_auditoria;
DROP TABLE IF EXISTS notificacion;
DROP TABLE IF EXISTS sancion;
DROP TABLE IF EXISTS falla;
DROP TABLE IF EXISTS prestamo;
DROP TABLE IF EXISTS reserva;
DROP TABLE IF EXISTS equipo;
DROP TABLE IF EXISTS usuario;

SET FOREIGN_KEY_CHECKS = 1;

-- =====================================================================
-- A partir de acá: schema original + datos de prueba
-- =====================================================================

-- =====================================================================
-- SGPET - Sistema de Gestión de Préstamos de Equipamiento Tecnológico
-- Script inicial de creación de la base de datos
-- Entrega 4 - Diseño de la base de datos
-- Taller integrador de sistemas - Ce.R.P. del Suroeste - 2026
-- Autoras: Castro - Sáenz - Sánchez
-- Motor: MySQL 8.0 (compatible con MariaDB 10.4+) sobre entorno XAMPP
-- =====================================================================

-- ---------------------------------------------------------------------
-- 0. Creación y selección de la base de datos
-- ---------------------------------------------------------------------

-- Fuerza el charset de ESTA sesión de importación a utf8mb4.
-- Sin esto, si tu cliente de MySQL/phpMyAdmin usa latin1 por defecto,
-- los acentos y la ñ de este script se guardan mal (mojibake).
SET NAMES utf8mb4;

-- ---------------------------------------------------------------------
-- 1. Tabla USUARIO
-- Almacena administradores, docentes y estudiantes en una única tabla
-- (herencia por tabla única / "single table inheritance"), diferenciados
-- por el atributo "rol". "departamento" solo aplica a docentes y "grupo"
-- solo a estudiantes; por eso ambos admiten NULL.
-- ---------------------------------------------------------------------
CREATE TABLE usuario (
    id_usuario          INT(8)       NOT NULL AUTO_INCREMENT,
    nombre              VARCHAR(60)  NOT NULL,
    apellido            VARCHAR(60)  NOT NULL,
    cedula              VARCHAR(12)  NOT NULL,
    email               VARCHAR(120) NOT NULL,
    telefono            VARCHAR(20)  NULL,
    contrasena_hash     VARCHAR(255) NOT NULL,
    rol                 ENUM('admin','docente','estudiante') NOT NULL,
    departamento        VARCHAR(60)  NULL,
    grupo               VARCHAR(20)  NULL,
    fecha_alta          DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
    activo              BOOLEAN      NOT NULL DEFAULT TRUE,
    PRIMARY KEY (id_usuario),
    UNIQUE KEY uq_usuario_cedula (cedula),
    UNIQUE KEY uq_usuario_email (email),
    INDEX idx_usuario_rol (rol)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ---------------------------------------------------------------------
-- 2. Tabla EQUIPO
-- Inventario del laboratorio. "condicion_tecnica" y "disponibilidad"
-- son independientes entre sí (Entrega 3, Diagrama de Clases).
-- ---------------------------------------------------------------------
CREATE TABLE equipo (
    id_equipo           INT          NOT NULL AUTO_INCREMENT,
    numero_serie        VARCHAR(50)  NOT NULL,
    tipo                VARCHAR(40)  NOT NULL,
    condicion_tecnica   ENUM('funcional','dañado','en_reparacion','kit_incompleto')
                                     NOT NULL DEFAULT 'funcional',
    disponibilidad      ENUM('disponible','reservado','prestado','en_mantenimiento','dado_de_baja')
                                     NOT NULL DEFAULT 'disponible',
    restriccion_uso     VARCHAR(120) NULL,
    PRIMARY KEY (id_equipo),
    UNIQUE KEY uq_equipo_numero_serie (numero_serie),
    INDEX idx_equipo_tipo (tipo),
    INDEX idx_equipo_disponibilidad (disponibilidad)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ---------------------------------------------------------------------
-- 3. Tabla RESERVA
-- Un docente o estudiante reserva un equipo para una fecha futura.
-- La reserva puede convertirse en préstamo (CU01/CU03, Entrega 3).
-- (Funcionalidad PHP implementada: ver reserva_form.php, prestamo_form.php,
-- prestamo_devolucion.php, sancion_form.php y el panel de administración)
-- ---------------------------------------------------------------------
CREATE TABLE reserva (
    id_reserva          INT       NOT NULL AUTO_INCREMENT,
    id_usuario          INT(8)    NOT NULL,
    id_equipo           INT       NOT NULL,
    fecha_inicio        DATETIME  NOT NULL,
    fecha_fin            DATETIME  NOT NULL,
    estado              ENUM('pendiente','convertida','cancelada','vencida')
                                  NOT NULL DEFAULT 'pendiente',
    PRIMARY KEY (id_reserva),
    CONSTRAINT fk_reserva_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario (id_usuario) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_reserva_equipo FOREIGN KEY (id_equipo)
        REFERENCES equipo (id_equipo) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_reserva_fechas CHECK (fecha_fin > fecha_inicio),
    INDEX idx_reserva_usuario (id_usuario),
    INDEX idx_reserva_equipo (id_equipo),
    INDEX idx_reserva_estado (estado)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ---------------------------------------------------------------------
-- 4. Tabla PRESTAMO
-- Entidad asociativa que resuelve la relación N:M entre usuario y
-- equipo. "id_admin" identifica al Administrador de Sala que gestionó
-- la operación; "id_reserva" es opcional y solo se completa cuando el
-- préstamo se origina en una reserva previa (CU01).
-- (Funcionalidad PHP implementada: ver reserva_form.php, prestamo_form.php,
-- prestamo_devolucion.php, sancion_form.php y el panel de administración)
-- ---------------------------------------------------------------------
CREATE TABLE prestamo (
    id_prestamo                 INT      NOT NULL AUTO_INCREMENT,
    id_usuario                  INT(8)   NOT NULL,
    id_equipo                   INT      NOT NULL,
    id_admin                    INT(8)   NOT NULL,
    id_reserva                  INT      NULL,
    fecha_solicitud              DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_devolucion_esperada    DATE     NOT NULL,
    fecha_devolucion_real        DATETIME NULL,
    estado                       ENUM('activo','atrasado','devuelto') NOT NULL DEFAULT 'activo',
    PRIMARY KEY (id_prestamo),
    CONSTRAINT fk_prestamo_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario (id_usuario) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_prestamo_equipo FOREIGN KEY (id_equipo)
        REFERENCES equipo (id_equipo) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_prestamo_admin FOREIGN KEY (id_admin)
        REFERENCES usuario (id_usuario) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_prestamo_reserva FOREIGN KEY (id_reserva)
        REFERENCES reserva (id_reserva) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT uq_prestamo_reserva UNIQUE (id_reserva),
    CONSTRAINT ck_prestamo_fechas CHECK (fecha_devolucion_esperada >= DATE(fecha_solicitud)),
    INDEX idx_prestamo_usuario (id_usuario),
    INDEX idx_prestamo_equipo (id_equipo),
    INDEX idx_prestamo_estado (estado)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ---------------------------------------------------------------------
-- 5. Tabla FALLA
-- Registra daños o piezas faltantes detectadas en la inspección técnica
-- del equipo (obligatoria en CU02 - Registrar devolución).
-- (Funcionalidad PHP implementada: ver reserva_form.php, prestamo_form.php,
-- prestamo_devolucion.php, sancion_form.php y el panel de administración)
-- ---------------------------------------------------------------------
CREATE TABLE falla (
    id_falla        INT      NOT NULL AUTO_INCREMENT,
    id_equipo       INT      NOT NULL,
    id_prestamo     INT      NULL,
    descripcion     TEXT     NOT NULL,
    gravedad        ENUM('leve','media','grave') NOT NULL,
    fecha_registro  DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_falla),
    CONSTRAINT fk_falla_equipo FOREIGN KEY (id_equipo)
        REFERENCES equipo (id_equipo) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_falla_prestamo FOREIGN KEY (id_prestamo)
        REFERENCES prestamo (id_prestamo) ON DELETE SET NULL ON UPDATE CASCADE,
    INDEX idx_falla_equipo (id_equipo),
    INDEX idx_falla_prestamo (id_prestamo)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ---------------------------------------------------------------------
-- 6. Tabla SANCION
-- Restricción temporal aplicada a un usuario por devolución atrasada o
-- por daño al equipo (CU08 - Aplicar sanción).
-- (Funcionalidad PHP implementada: ver reserva_form.php, prestamo_form.php,
-- prestamo_devolucion.php, sancion_form.php y el panel de administración)
-- ---------------------------------------------------------------------
CREATE TABLE sancion (
    id_sancion      INT   NOT NULL AUTO_INCREMENT,
    id_usuario      INT(8) NOT NULL,
    id_prestamo     INT   NULL,
    motivo          VARCHAR(200) NOT NULL,
    fecha_inicio    DATE  NOT NULL,
    fecha_fin       DATE  NOT NULL,
    PRIMARY KEY (id_sancion),
    CONSTRAINT fk_sancion_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario (id_usuario) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_sancion_prestamo FOREIGN KEY (id_prestamo)
        REFERENCES prestamo (id_prestamo) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT ck_sancion_fechas CHECK (fecha_fin >= fecha_inicio),
    INDEX idx_sancion_usuario (id_usuario),
    INDEX idx_sancion_vigencia (fecha_fin)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ---------------------------------------------------------------------
-- 7. Tabla NOTIFICACION
-- Avisos automáticos de vencimientos, confirmaciones y sanciones
-- (módulo de alertas y notificaciones, Entrega 3).
-- (Funcionalidad PHP implementada: ver reserva_form.php, prestamo_form.php,
-- prestamo_devolucion.php, sancion_form.php y el panel de administración)
-- ---------------------------------------------------------------------
CREATE TABLE notificacion (
    id_notificacion  INT      NOT NULL AUTO_INCREMENT,
    id_usuario       INT(8)   NOT NULL,
    tipo             ENUM('confirmacion_prestamo','recordatorio_vencimiento','sancion','reserva') NOT NULL,
    mensaje          TEXT     NOT NULL,
    fecha_envio      DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    leida            BOOLEAN  NOT NULL DEFAULT FALSE,
    PRIMARY KEY (id_notificacion),
    CONSTRAINT fk_notificacion_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario (id_usuario) ON DELETE CASCADE ON UPDATE CASCADE,
    INDEX idx_notificacion_usuario (id_usuario),
    INDEX idx_notificacion_leida (leida)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;

-- ---------------------------------------------------------------------
-- 8. Tabla LOG_AUDITORIA
-- Trazabilidad de acciones (usuario, fecha, hora y acción realizada)
-- exigida en "Seguridad y aspectos legales" de la Entrega 3.
-- "id_entidad" referencia de forma genérica al registro afectado según
-- el valor de "entidad" (equipo, prestamo, reserva, etc.); no lleva FK
-- física porque puede apuntar a distintas tablas.
-- (Funcionalidad PHP implementada: ver reserva_form.php, prestamo_form.php,
-- prestamo_devolucion.php, sancion_form.php y el panel de administración)
-- ---------------------------------------------------------------------
CREATE TABLE log_auditoria (
    id_log       INT      NOT NULL AUTO_INCREMENT,
    id_usuario   INT(8)   NOT NULL,
    accion       VARCHAR(80) NOT NULL,
    entidad      VARCHAR(40) NOT NULL,
    id_entidad   INT      NULL,
    fecha_hora   DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id_log),
    CONSTRAINT fk_log_usuario FOREIGN KEY (id_usuario)
        REFERENCES usuario (id_usuario) ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_log_usuario (id_usuario),
    INDEX idx_log_fecha (fecha_hora)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;


-- =====================================================================
-- 9. DATOS DE PRUEBA
-- Contraseña de prueba para TODOS los usuarios: Sgpet2026!
-- (guardada como hash bcrypt en "contrasena_hash", nunca en texto plano)
--
-- id_usuario es AUTO_INCREMENT: lo arrancamos en 10001 para que el
-- ID de acceso (el que se escribe en el login) sea siempre un entero
-- de 5 dígitos, asignado automáticamente por la base de datos.
-- La "cedula" es un dato de perfil aparte (no se usa para loguearse).
-- =====================================================================
ALTER TABLE usuario AUTO_INCREMENT = 10001;

-- ---------- 3 ADMINISTRADORES (id_usuario 10001-10003) ----------
INSERT INTO usuario (nombre, apellido, cedula, email, telefono, contrasena_hash, rol, departamento, grupo) VALUES
('Laura',  'Castro',  '40111222', 'profeinformatica.lauracastro@gmail.com', '099111222', '$2y$10$O55lOEd5GUWgsU98YuBcn.UqxW98MSuQQmzyyuWFhsGY9r7se320i', 'admin', NULL, NULL),
('Analía', 'Sáenz',   '40111223', 'analia.saenz@docente.ceibal.edu.uy',     '099111223', '$2y$10$O55lOEd5GUWgsU98YuBcn.UqxW98MSuQQmzyyuWFhsGY9r7se320i', 'admin', NULL, NULL),
('Malena', 'Sánchez', '40111224', 'malenasf@gmail.com',                     '099111224', '$2y$10$O55lOEd5GUWgsU98YuBcn.UqxW98MSuQQmzyyuWFhsGY9r7se320i', 'admin', NULL, NULL);

-- ---------- 5 DOCENTES (id_usuario 10004-10008) ----------
INSERT INTO usuario (nombre, apellido, cedula, email, telefono, contrasena_hash, rol, departamento, grupo) VALUES
('Rosana',  'Pereyra',  '41222333', 'rosana.pereyra@sgpet-instituto.edu.uy',  '099222333', '$2y$10$O55lOEd5GUWgsU98YuBcn.UqxW98MSuQQmzyyuWFhsGY9r7se320i', 'docente', 'Informática',      NULL),
('Gustavo', 'Techera',  '41222334', 'gustavo.techera@sgpet-instituto.edu.uy', '099222334', '$2y$10$O55lOEd5GUWgsU98YuBcn.UqxW98MSuQQmzyyuWFhsGY9r7se320i', 'docente', 'Robótica',         NULL),
('Valeria', 'Núñez',    '41222335', 'valeria.nunez@sgpet-instituto.edu.uy',   '099222335', '$2y$10$O55lOEd5GUWgsU98YuBcn.UqxW98MSuQQmzyyuWFhsGY9r7se320i', 'docente', 'Ciencias',         NULL),
('Diego',   'Larrosa',  '41222336', 'diego.larrosa@sgpet-instituto.edu.uy',   '099222336', '$2y$10$O55lOEd5GUWgsU98YuBcn.UqxW98MSuQQmzyyuWFhsGY9r7se320i', 'docente', 'Matemática',       NULL),
('Marcela', 'Ferreira', '41222337', 'marcela.ferreira@sgpet-instituto.edu.uy','099222337', '$2y$10$O55lOEd5GUWgsU98YuBcn.UqxW98MSuQQmzyyuWFhsGY9r7se320i', 'docente', 'Informática',      NULL);

-- ---------- 10 ESTUDIANTES (id_usuario 10009-10018) ----------
INSERT INTO usuario (nombre, apellido, cedula, email, telefono, contrasena_hash, rol, departamento, grupo) VALUES
('Bruno',     'Machado',    '50333444', 'bruno.machado@estudiantes.sgpet-instituto.edu.uy',    '098333444', '$2y$10$O55lOEd5GUWgsU98YuBcn.UqxW98MSuQQmzyyuWFhsGY9r7se320i', 'estudiante', NULL, '2do B'),
('Camila',    'Rodríguez',  '50333445', 'camila.rodriguez@estudiantes.sgpet-instituto.edu.uy', '098333445', '$2y$10$O55lOEd5GUWgsU98YuBcn.UqxW98MSuQQmzyyuWFhsGY9r7se320i', 'estudiante', NULL, '2do B'),
('Ignacio',   'Silva',      '50333446', 'ignacio.silva@estudiantes.sgpet-instituto.edu.uy',    '098333446', '$2y$10$O55lOEd5GUWgsU98YuBcn.UqxW98MSuQQmzyyuWFhsGY9r7se320i', 'estudiante', NULL, '3ro A'),
('Sofía',     'Correa',     '50333447', 'sofia.correa@estudiantes.sgpet-instituto.edu.uy',     '098333447', '$2y$10$O55lOEd5GUWgsU98YuBcn.UqxW98MSuQQmzyyuWFhsGY9r7se320i', 'estudiante', NULL, '3ro A'),
('Mateo',     'Acosta',     '50333448', 'mateo.acosta@estudiantes.sgpet-instituto.edu.uy',     '098333448', '$2y$10$O55lOEd5GUWgsU98YuBcn.UqxW98MSuQQmzyyuWFhsGY9r7se320i', 'estudiante', NULL, '1ro C'),
('Valentina', 'Suárez',     '50333449', 'valentina.suarez@estudiantes.sgpet-instituto.edu.uy', '098333449', '$2y$10$O55lOEd5GUWgsU98YuBcn.UqxW98MSuQQmzyyuWFhsGY9r7se320i', 'estudiante', NULL, '1ro C'),
('Joaquín',   'Ramírez',    '50333450', 'joaquin.ramirez@estudiantes.sgpet-instituto.edu.uy',  '098333450', '$2y$10$O55lOEd5GUWgsU98YuBcn.UqxW98MSuQQmzyyuWFhsGY9r7se320i', 'estudiante', NULL, '2do A'),
('Abril',     'Gómez',      '50333451', 'abril.gomez@estudiantes.sgpet-instituto.edu.uy',      '098333451', '$2y$10$O55lOEd5GUWgsU98YuBcn.UqxW98MSuQQmzyyuWFhsGY9r7se320i', 'estudiante', NULL, '2do A'),
('Nicolás',   'Fagúndez',   '50333452', 'nicolas.fagundez@estudiantes.sgpet-instituto.edu.uy', '098333452', '$2y$10$O55lOEd5GUWgsU98YuBcn.UqxW98MSuQQmzyyuWFhsGY9r7se320i', 'estudiante', NULL, '3ro B'),
('Martina',   'Cabrera',    '50333453', 'martina.cabrera@estudiantes.sgpet-instituto.edu.uy',  '098333453', '$2y$10$O55lOEd5GUWgsU98YuBcn.UqxW98MSuQQmzyyuWFhsGY9r7se320i', 'estudiante', NULL, '3ro B');


-- ---------- INVENTARIO DE EQUIPOS (27 unidades, sin préstamos activos) ----------

-- 10 Ceibalitas (identificadas por número de serie de 10 dígitos)
INSERT INTO equipo (numero_serie, tipo, condicion_tecnica, disponibilidad, restriccion_uso) VALUES
('3746317213', 'Ceibalita', 'funcional', 'disponible', NULL),
('9697354961', 'Ceibalita', 'funcional', 'disponible', NULL),
('2181241943', 'Ceibalita', 'funcional', 'disponible', NULL),
('1958682846', 'Ceibalita', 'funcional', 'disponible', NULL),
('4163119785', 'Ceibalita', 'funcional', 'disponible', NULL),
('9963334018', 'Ceibalita', 'funcional', 'disponible', NULL),
('2812140441', 'Ceibalita', 'funcional', 'disponible', NULL),
('1127978094', 'Ceibalita', 'funcional', 'disponible', NULL),
('1939042955', 'Ceibalita', 'funcional', 'disponible', NULL),
('9703905715', 'Ceibalita', 'funcional', 'disponible', NULL);

-- 5 Kits de robótica (identificados del 1 al 5)
INSERT INTO equipo (numero_serie, tipo, condicion_tecnica, disponibilidad, restriccion_uso) VALUES
('ROB-01', 'Kit de robótica', 'funcional',      'disponible',       NULL),
('ROB-02', 'Kit de robótica', 'funcional',      'disponible',       NULL),
('ROB-03', 'Kit de robótica', 'funcional',      'disponible',       NULL),
('ROB-04', 'Kit de robótica', 'kit_incompleto', 'en_mantenimiento', 'Faltan piezas: verificar antes de prestar'),
('ROB-05', 'Kit de robótica', 'funcional',      'disponible',       NULL);

-- 5 Placas Micro:bit (identificadas del 1 al 5)
INSERT INTO equipo (numero_serie, tipo, condicion_tecnica, disponibilidad, restriccion_uso) VALUES
('MB-01', 'Placa Micro:bit', 'funcional', 'disponible', NULL),
('MB-02', 'Placa Micro:bit', 'funcional', 'disponible', NULL),
('MB-03', 'Placa Micro:bit', 'funcional', 'disponible', NULL),
('MB-04', 'Placa Micro:bit', 'funcional', 'disponible', NULL),
('MB-05', 'Placa Micro:bit', 'funcional', 'disponible', NULL);

-- 2 Impresoras 3D (solo por el día, uso exclusivo dentro de la institución)
INSERT INTO equipo (numero_serie, tipo, condicion_tecnica, disponibilidad, restriccion_uso) VALUES
('IMP3D-01', 'Impresora 3D', 'funcional', 'disponible', 'Uso solo por el día, dentro de la institución'),
('IMP3D-02', 'Impresora 3D', 'funcional', 'disponible', 'Uso solo por el día, dentro de la institución');

-- 5 Multisensor Datalogger (identificados del 1 al 5)
INSERT INTO equipo (numero_serie, tipo, condicion_tecnica, disponibilidad, restriccion_uso) VALUES
('MSD-01', 'Multisensor Datalogger', 'funcional',      'disponible',   NULL),
('MSD-02', 'Multisensor Datalogger', 'funcional',      'disponible',   NULL),
('MSD-03', 'Multisensor Datalogger', 'funcional',      'disponible',   NULL),
('MSD-04', 'Multisensor Datalogger', 'dañado',         'dado_de_baja', 'Sensor de temperatura roto: pendiente de baja definitiva'),
('MSD-05', 'Multisensor Datalogger', 'funcional',      'disponible',   NULL);

-- =====================================================================
-- Fin del script inicial de creación de la base de datos - SGPET
-- =====================================================================
