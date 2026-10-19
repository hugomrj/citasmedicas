PRAGMA foreign_keys = ON;

CREATE TABLE usuarios (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre          VARCHAR(255) NOT NULL,
  apellido        VARCHAR(255) NOT NULL,
  username        VARCHAR(255) NOT NULL UNIQUE, 
  email           VARCHAR(255) NOT NULL UNIQUE,
  password_digest VARCHAR(255) NOT NULL,
  rol             VARCHAR(255) NOT NULL,
  activo          BOOLEAN NOT NULL DEFAULT 1,
  created_at      DATETIME NOT NULL,
  updated_at      DATETIME NOT NULL,
  CONSTRAINT usuarios_rol_valido CHECK (rol IN ('admin', 'recepcion', 'medico'))
);



CREATE TABLE especialidades (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre          VARCHAR(255) NOT NULL UNIQUE,
  created_at      DATETIME NOT NULL,
  updated_at      DATETIME NOT NULL
);




CREATE TABLE medicos (
  id              INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre          VARCHAR(255) NOT NULL,
  apellido        VARCHAR(255) NOT NULL,
  especialidad_id INTEGER NOT NULL, 
  matricula       VARCHAR(255) NOT NULL,
  email           VARCHAR(255),
  telefono        VARCHAR(255),
  usuario_id      INTEGER,
  horizonte_dias  INTEGER,
  activo          BOOLEAN NOT NULL DEFAULT 1,
  created_at      DATETIME NOT NULL,
  updated_at      DATETIME NOT NULL,
  FOREIGN KEY (usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL,
  FOREIGN KEY (especialidad_id) REFERENCES especialidades(id) -- <--- NUEVA FK
);

CREATE TABLE pacientes (
  id               INTEGER PRIMARY KEY AUTOINCREMENT,
  nombre           VARCHAR(255) NOT NULL,
  apellido         VARCHAR(255) NOT NULL,
  cedula           VARCHAR(255) UNIQUE,
  telefono         VARCHAR(255) NOT NULL UNIQUE,
  email            VARCHAR(255),
  fecha_nacimiento DATE,
  notas            TEXT,
  canal_registro   VARCHAR(255) NOT NULL DEFAULT 'presencial',
  archivado        BOOLEAN NOT NULL DEFAULT 0,
  created_at       DATETIME NOT NULL,
  updated_at       DATETIME NOT NULL,
  CONSTRAINT pacientes_canal_valido CHECK (canal_registro IN ('presencial', 'telefono', 'chatbot', 'telegram'))
);

CREATE TABLE disponibilidad (
  id                 INTEGER PRIMARY KEY AUTOINCREMENT,
  medico_id          INTEGER NOT NULL,
  dia_semana         INTEGER,
  fecha_especifica   DATE,
  hora_inicio        VARCHAR(5) NOT NULL,
  hora_fin           VARCHAR(5) NOT NULL,
  duracion_turno_min INTEGER NOT NULL DEFAULT 30,
  created_at         DATETIME NOT NULL,
  updated_at         DATETIME NOT NULL,
  FOREIGN KEY (medico_id) REFERENCES medicos(id) ON DELETE CASCADE,
  CONSTRAINT disponibilidad_molde_o_override CHECK (
    (dia_semana IS NOT NULL AND fecha_especifica IS NULL) OR
    (dia_semana IS NULL AND fecha_especifica IS NOT NULL)
  ),
  CONSTRAINT disponibilidad_dia_semana_rango CHECK (dia_semana IS NULL OR (dia_semana >= 0 AND dia_semana <= 6)),
  CONSTRAINT disponibilidad_hora_rango CHECK (hora_inicio < hora_fin),
  CONSTRAINT disponibilidad_hora_inicio_formato CHECK (hora_inicio LIKE '__:__'),
  CONSTRAINT disponibilidad_hora_fin_formato CHECK (hora_fin LIKE '__:__'),
  CONSTRAINT disponibilidad_duracion_positiva CHECK (duracion_turno_min > 0)
);

CREATE INDEX idx_disponibilidad_medico_dia ON disponibilidad(medico_id, dia_semana);
CREATE INDEX idx_disponibilidad_medico_fecha ON disponibilidad(medico_id, fecha_especifica);

CREATE TABLE bloqueos (
  id                      INTEGER PRIMARY KEY AUTOINCREMENT,
  medico_id               INTEGER NOT NULL,
  fecha_inicio            DATETIME NOT NULL,
  fecha_fin               DATETIME NOT NULL,
  motivo                  VARCHAR(255) NOT NULL,
  notas                   TEXT,
  cancelado_en            DATETIME,
  creado_por_usuario_id   INTEGER,
  created_at              DATETIME NOT NULL,
  updated_at              DATETIME NOT NULL,
  FOREIGN KEY (medico_id) REFERENCES medicos(id) ON DELETE CASCADE,
  FOREIGN KEY (creado_por_usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL,
  CONSTRAINT bloqueos_fechas_validas CHECK (fecha_fin > fecha_inicio),
  CONSTRAINT bloqueos_motivo_valido CHECK (motivo IN ('vacaciones', 'congreso', 'licencia', 'feriado', 'personal'))
);

CREATE INDEX idx_bloqueos_medico_fechas ON bloqueos(medico_id, fecha_inicio, fecha_fin);

CREATE TABLE citas (
  id                      INTEGER PRIMARY KEY AUTOINCREMENT,
  paciente_id             INTEGER NOT NULL,
  medico_id               INTEGER NOT NULL,
  fecha_hora              DATETIME NOT NULL,
  fecha_hora_fin          DATETIME NOT NULL,
  duracion_min            INTEGER NOT NULL,
  estado                  VARCHAR(255) NOT NULL DEFAULT 'pendiente',
  canal_origen            VARCHAR(255) NOT NULL DEFAULT 'presencial',
  motivo                  TEXT,
  notas_internas          TEXT,
  codigo_confirmacion     VARCHAR(255) NOT NULL UNIQUE,
  creado_por_usuario_id   INTEGER,
  cancelada_por           VARCHAR(255),
  motivo_cancelacion      TEXT,
  cancelada_en            DATETIME,
  atendida_en             DATETIME,
  no_asistio_en           DATETIME,
  reprogramada_desde_id   INTEGER,
  created_at              DATETIME NOT NULL,
  updated_at              DATETIME NOT NULL,
  FOREIGN KEY (paciente_id) REFERENCES pacientes(id),
  FOREIGN KEY (medico_id) REFERENCES medicos(id),
  FOREIGN KEY (creado_por_usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL,
  FOREIGN KEY (reprogramada_desde_id) REFERENCES citas(id) ON DELETE SET NULL,
  CONSTRAINT citas_estado_valido CHECK (estado IN ('pendiente', 'confirmada', 'atendida', 'cancelada', 'no_asistio', 'requiere_reprogramacion')),
  CONSTRAINT citas_cancelada_por_valido CHECK (cancelada_por IS NULL OR cancelada_por IN ('paciente', 'medico', 'sistema', 'staff')),
  CONSTRAINT citas_canal_valido CHECK (canal_origen IN ('presencial', 'telefono', 'chatbot', 'telegram')),
  CONSTRAINT citas_rango_valido CHECK (fecha_hora_fin > fecha_hora),
  CONSTRAINT citas_duracion_positiva CHECK (duracion_min > 0)
);

CREATE INDEX idx_citas_medico_rango ON citas(medico_id, fecha_hora, fecha_hora_fin);
CREATE INDEX idx_citas_paciente_fecha ON citas(paciente_id, fecha_hora);
CREATE INDEX idx_citas_estado ON citas(estado);

CREATE TABLE avisos (
  id                        INTEGER PRIMARY KEY AUTOINCREMENT,
  tipo                      VARCHAR(255) NOT NULL,
  severidad                 VARCHAR(255) NOT NULL,
  entidad_tipo              VARCHAR(255) NOT NULL,
  entidad_id                INTEGER,
  titulo                    VARCHAR(255) NOT NULL,
  detalle                   TEXT,
  estado                    VARCHAR(255) NOT NULL DEFAULT 'pendiente',
  visto_por_usuario_id      INTEGER,
  visto_en                  DATETIME,
  resuelto_por_usuario_id   INTEGER,
  resuelto_en               DATETIME,
  descartado_por_usuario_id INTEGER,
  descartado_en             DATETIME,
  created_at                DATETIME NOT NULL,
  updated_at                DATETIME NOT NULL,
  FOREIGN KEY (visto_por_usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL,
  FOREIGN KEY (resuelto_por_usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL,
  FOREIGN KEY (descartado_por_usuario_id) REFERENCES usuarios(id) ON DELETE SET NULL,
  CONSTRAINT avisos_estado_valido CHECK (estado IN ('pendiente', 'visto', 'resuelto', 'descartado')),
  CONSTRAINT avisos_severidad_valida CHECK (severidad IN ('info', 'warning', 'error')),
  CONSTRAINT avisos_entidad_tipo_valido CHECK (entidad_tipo IN ('cita', 'medico', 'bloqueo', 'paciente', 'sistema'))
);

CREATE INDEX idx_avisos_estado_fecha ON avisos(estado, created_at);
CREATE INDEX idx_avisos_entidad ON avisos(entidad_tipo, entidad_id);

CREATE TABLE configuracion (
  clave          VARCHAR(255) PRIMARY KEY,
  valor          VARCHAR(255) NOT NULL,
  actualizado_en DATETIME NOT NULL
);

INSERT INTO configuracion (clave, valor, actualizado_en) VALUES
  ('horizonte_maximo_dias',     '60',                  datetime('now')),
  ('anticipacion_minima_horas', '2',                   datetime('now')),
  ('ultimo_escaneo_avisos',     '1970-01-01T00:00:00', datetime('now')),
  ('version_esquema',           '1',                   datetime('now'));