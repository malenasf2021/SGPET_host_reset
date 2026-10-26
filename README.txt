SGPET - Login con vistas diferenciadas (Administrador / Docente / Estudiante)
================================================================

CÓMO INSTALARLO EN XAMPP (entorno local, para desarrollo/pruebas)
1. Copiá toda la carpeta "sgpet_prototipo_v2" dentro de: C:\xampp\htdocs\
   (podés renombrarla si querés, por ejemplo a "sgpet").
2. Iniciá Apache y MySQL desde el Panel de Control de XAMPP.
3. Abrí phpMyAdmin (http://localhost/phpmyadmin), pestaña "Importar",
   y subí el archivo: sql/sgpet_schema.sql
   (esto crea la base "sgpet_db", carga los usuarios ficticios y el
   inventario de equipos de prueba).
4. Revisá config.php: si tu MySQL de XAMPP usa usuario/contraseña distinto
   a root/(vacío), ajustalo ahí.
5. Entrá desde el navegador a: http://localhost/sgpet_prototipo_v2/index.html


CÓMO SUBIRLO A UN HOSTING GRATUITO (InfinityFree)
A diferencia de XAMPP, en un hosting compartido gratuito NO podés crear
una base de datos con el nombre que quieras: te la crean con un prefijo
fijo (algo como if0_12345678_sgpet), y tampoco podés ejecutar sentencias
CREATE DATABASE / DROP DATABASE desde el script SQL. Por eso, para subir
el proyecto se usa un script aparte: sql/sgpet_schema_hosting.sql (el
mismo schema, pero sin esas líneas iniciales).

1. Crear la cuenta y el sitio
   - Entrá a infinityfree.com y creá una cuenta (Sign Up) con tu email.
   - Creá una cuenta de hosting y elegí un subdominio gratis
     (por ejemplo sgpet-cerp.rf.gd). Esperá a que se active.

2. Crear la base de datos
   - En el panel, abrí "MySQL Databases".
   - Ponele un nombre (por ejemplo "sgpet") y creala. InfinityFree le
     agrega un prefijo automático (if0_12345678_sgpet).
   - Anotá estos 4 datos, que vas a necesitar en el paso 4:
       Host      -> algo como sql123.infinityfree.com (NO es "localhost")
       Usuario   -> algo como if0_12345678
       Contraseña -> la de tu cuenta de hosting/vPanel
       Base      -> el nombre con prefijo, if0_12345678_sgpet

3. Importar el schema
   - Desde "MySQL Databases" abrí phpMyAdmin de tu base.
   - Elegí tu base en la columna izquierda -> pestaña "Importar" ->
     seleccioná sql/sgpet_schema_hosting.sql -> "Continuar".
   - Verificá que aparezcan todas las tablas (usuario, equipo, prestamo,
     reserva, falla, sancion, notificacion, log_auditoria) y que los
     acentos se vean bien (si salen símbolos raros, revisá el punto
     "Acentos raros" más abajo).

4. Editar config.php ANTES de subirlo, con los datos del paso 2:
     define('DB_HOST', 'sql123.infinityfree.com');
     define('DB_USER', 'if0_12345678');
     define('DB_PASS', 'tu_contraseña');
     define('DB_NAME', 'if0_12345678_sgpet');

5. Subir los archivos
   - Usá el "Online File Manager" del panel, o FileZilla por FTP (los
     datos de conexión FTP están en el panel, sección Account/FTP
     Details).
   - El file manager solo deja subir DENTRO de la carpeta htdocs (subir
     fuera de ahí tira el error "Uploads are only allowed to htdocs
     folders"). Entrá primero a htdocs y recién ahí subí los archivos.
   - Subí el CONTENIDO de la carpeta del proyecto (no la carpeta en sí),
     para que index.html y config.php queden directamente dentro de
     htdocs/.
   - No hace falta subir la carpeta sql/: una vez importado el schema
     por phpMyAdmin, dejarla en el servidor público no aporta nada y
     expone la estructura de la base.
   - Borrá el index2.html que InfinityFree crea por defecto en htdocs.

6. Probar
   - Abrí tu subdominio, iniciá sesión con un usuario de prueba (ver
     tabla más abajo) y recorré un flujo completo: reservar equipo ->
     registrar préstamo -> registrar devolución.
   - Para confirmar que un alta se guardó, mirá el panel del sistema
     (por ejemplo "Inventario de equipos (28)") y compará ese número
     contra el total que muestra phpMyAdmin. Si coinciden, se guardó
     bien: en phpMyAdmin por defecto solo se ve la primera página de
     filas (hasta 25), así que un registro nuevo puede no aparecer a
     simple vista aunque sí esté. Usá el campo "Filtrar filas" o
     cambiá el orden por id_usuario/id_equipo descendente para
     encontrarlo rápido.

Problemas típicos en InfinityFree
- "Error de conexión a la base de datos": casi siempre es el host (te
  quedó "localhost" en vez de sql123.infinityfree.com) o una contraseña
  incorrecta en config.php.
- Acentos raros (Ã¡, Ã±): el schema se importó sin forzar utf8mb4, o el
  archivo se subió con otra codificación. Volvé a importar
  sgpet_schema_hosting.sql desde cero.
- Página que pide "activar JavaScript" o instala una cookie al entrar:
  es una verificación anti-bots que InfinityFree agrega en el primer
  acceso a un subdominio nuevo. Es normal, no es un error del proyecto.
- Sesión que no se mantiene entre páginas: activá el SSL gratuito desde
  el panel y entrá siempre por https://, no por http://.
- "Uploads are only allowed to htdocs folders": estás parado en la raíz
  del file manager (donde también están logs/, ssl/, etc.), no dentro
  de htdocs. Entrá a esa carpeta y recién ahí subí los archivos.
- Un alta (usuario, equipo, préstamo) "no aparece": antes de asumir que
  falló, comparé el contador del panel del sistema contra el total de
  filas de phpMyAdmin (ver punto 6). La causa más común es estar
  mirando solo la primera página de resultados en phpMyAdmin, no que
  el insert haya fallado.

CÓMO REINICIAR LA BASE DE DATOS (volver al estado inicial)
Sirve para dejar el sistema limpio antes de una demo, de la defensa o
de una nueva ronda de pruebas. Se usa el script sql/sgpet_reset_hosting.sql:
borra las 8 tablas (usuario, equipo, reserva, prestamo, falla, sancion,
notificacion, log_auditoria) y las vuelve a crear con los datos de prueba
originales.
 
QUÉ SE PIERDE Y QUÉ QUEDA
  · Se pierde TODO lo cargado durante las pruebas: préstamos, reservas,
    fallas, sanciones, notificaciones, auditoría, y los usuarios o
    equipos que hayas agregado a mano.
  · Las contraseñas vuelven a la de prueba (Sgpet2026!), también las que
    hayas cambiado. Si compartís el link del hosting, volvé a cambiar la
    de los administradores.
  · Queda la base inicial: 18 usuarios y 27 equipos ficticios, sin
    préstamos ni reservas.
 
EN EL HOSTING (InfinityFree)
1. Entrá al panel -> "MySQL Databases" -> abrí phpMyAdmin.
2. Elegí TU base (if0_..._sgpet) en la columna izquierda. No hace falta
   vaciarla ni borrarla antes: el script lo hace solo.
3. Pestaña "Importar" -> "Elegir archivo" -> sql/sgpet_reset_hosting.sql
   (desde tu computadora) -> "Continuar".
4. Esperá el mensaje de importación exitosa. Es un script que no usa
   CREATE DATABASE ni USE, por eso funciona en el hosting gratuito.
5. Verificá: cerrá sesión e iniciá con 10001 / Sgpet2026!. El panel
   debe mostrar 27 equipos y 18 usuarios, y ningún préstamo.
 
EN XAMPP (local)
1. En phpMyAdmin (http://localhost/phpmyadmin) creá una base vacía con
   cotejamiento utf8mb4_spanish_ci, o usá la que ya tenías (la que
   figura en DB_NAME de config.php).
2. Elegí esa base -> "Importar" -> sql/sgpet_reset_hosting.sql.
 
IMPORTANTE
  · El archivo sgpet_reset_hosting.sql NO se sube a htdocs: se usa solo
    desde phpMyAdmin, importándolo desde tu computadora. Dejarlo en el
    servidor público expondría la estructura y los datos de la base.
  · No se puede deshacer. Si querés conservar algo (por ejemplo una
    demo cargada), exportá antes la base desde phpMyAdmin -> "Exportar".
  · Después de reiniciar, cualquier sesión que estuviera abierta apunta
    a datos que ya no existen: cerrá sesión y volvé a entrar.
  · Si la importación da error de conexión o de permisos, revisá que
    elegiste tu base en phpMyAdmin antes de importar (y no la raíz del
    servidor).

IDENTIFICADOR DE LOGIN
  · id_usuario: clave primaria interna, autoincremental, de 5 dígitos.
    ES la que se usa para iniciar sesión.

USUARIOS DE PRUEBA
Todos comparten la misma contraseña de prueba: Sgpet2026!
(guardada cifrada con bcrypt en "contrasena_hash", nunca en texto plano)
Antes de compartir el link del hosting públicamente, cambiá al menos la
contraseña de los usuarios administradores.

ADMINISTRADORES
 10001 - Laura Castro    (cédula 40111222)
 10002 - Analía Sáenz    (cédula 40111223)
 10003 - Malena Sánchez  (cédula 40111224)

DOCENTES
 10004 - Rosana Pereyra  (Informática)
 10005 - Gustavo Techera (Robótica)
 10006 - Valeria Núñez   (Ciencias)
 10007 - Diego Larrosa   (Matemática)
 10008 - Marcela Ferreira (Informática)

ESTUDIANTES
 10009 - Bruno Machado     (2do B)
 10010 - Camila Rodríguez  (2do B)
 10011 - Ignacio Silva     (3ro A)
 10012 - Sofía Correa      (3ro A)
 10013 - Mateo Acosta      (1ro C)
 10014 - Valentina Suárez  (1ro C)
 10015 - Joaquín Ramírez   (2do A)
 10016 - Abril Gómez       (2do A)
 10017 - Nicolás Fagúndez  (3ro B)
 10018 - Martina Cabrera   (3ro B)

INVENTARIO CARGADO (27 equipos, sin préstamos activos)
 · 10 Ceibalitas (identificadas por número de serie de 10 dígitos)
 · 5 Kits de robótica (uno con condición "kit_incompleto" / disponibilidad
   "en_mantenimiento", para mostrar que ambos estados son independientes)
 · 5 Placas Micro:bit
 · 2 Impresoras 3D (con restricción de uso: solo por el día, dentro de
   la institución)
 · 5 Multisensor Datalogger (uno "dañado" / "dado_de_baja", como ejemplo
   de equipo retirado del inventario activo)

CÓMO FUNCIONA
- index.html: login estático (HTML puro). Pide id_usuario (5 dígitos) +
  contraseña. Si login_process.php devuelve un error, esta misma página
  lo lee de la URL (?error=...) y lo muestra con JavaScript, porque al
  ser un .html no puede leer variables de sesión de PHP directamente.

- login_process.php: valida contra la tabla "usuario" (contrasena_hash
  con password_verify(), y activo=1) y redirige a
  dashboard_administrador.php / dashboard_docente.php / dashboard_estudiante.php
  según el "rol" (admin / docente / estudiante).

- dashboard_administrador.php: ve TODOS los usuarios y TODO el
  inventario de equipos. Desde acá el administrador puede:
    · Dar de alta o editar usuarios (usuario_form.php)
    · Desactivar/reactivar un usuario (usuario_eliminar.php) — NO se
      borra el registro físicamente, porque las tablas de préstamos,
      reservas y sanciones necesitan conservar el historial (la base
      usa ON DELETE RESTRICT a propósito)
    · Generar una contraseña temporal (usuario_resetear_password.php)
    · Dar de alta, editar o eliminar equipos (equipo_form.php / equipo_eliminar.php)

- dashboard_docente.php: ve el inventario completo, equipo por equipo
  (número de serie, tipo, disponibilidad, restricciones).

- dashboard_estudiante.php: vista más acotada, disponibilidad resumida
  por tipo de equipo (sin el detalle unidad por unidad).

- includes/auth_check.php: si alguien no logueado intenta entrar a un
  dashboard, lo manda al login; si un usuario intenta entrar al panel
  de otro rol, lo redirige automáticamente al suyo.

MÓDULO DE RESERVAS, PRÉSTAMOS, FALLAS, SANCIONES, NOTIFICACIONES Y AUDITORÍA
- reserva (reserva_form.php / reserva_cancelar.php): docentes y
  estudiantes reservan equipos con anticipación. Los estudiantes solo
  pueden reservar ceibalitas (regla de negocio del CU01/CU03). El
  propio usuario puede cancelar una reserva pendiente; el admin puede
  cancelar cualquiera o convertirla en préstamo.
- prestamo (prestamo_form.php / prestamo_devolucion.php): solo el
  administrador registra préstamos (directos o convirtiendo una
  reserva pendiente) y procesa la devolución con inspección técnica
  de la condición del equipo.
- falla (se registra desde prestamo_devolucion.php): daños o piezas
  faltantes detectados en la inspección al devolver un equipo.
- sancion (sancion_form.php / sancion_levantar.php): restricción
  temporal a un usuario. Se aplica automáticamente al devolver con
  atraso o con una falla grave, y también puede aplicarla o
  levantarla manualmente el administrador. Un usuario sancionado no
  puede generar nuevas reservas ni recibir préstamos mientras esté
  vigente.
- notificacion (se ve en cada panel, se marca como leída con
  notificacion_marcar_leida.php): avisos de reservas, préstamos,
  sanciones y vencimientos. El botón "Generar recordatorios de
  vencimiento" del panel admin (generar_recordatorios.php) marca como
  atrasados los préstamos vencidos y avisa los que vencen hoy o
  mañana; reemplaza a una tarea programada (cron) que en un servidor
  propio correría todos los días automáticamente. En InfinityFree los
  cron jobs gratuitos no son confiables, así que este botón hay que
  disparlo a mano (o desde un servicio externo de "cron ping" gratuito
  que abra generar_recordatorios.php una vez al día).
- log_auditoria (se ve en el panel admin): registra usuario, fecha,
  acción y entidad de cada operación relevante del sistema.
