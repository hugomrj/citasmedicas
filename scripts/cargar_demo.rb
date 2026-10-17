#!/usr/bin/env ruby
require_relative 'env_helper'
require_relative '../services'

puts "== Cargando datos de demo =="

# ---------- Admin ----------
admin = Usuario.where(rol: 'admin').first
if admin.nil?
  admin = UsuarioService.crear(
    nombre: 'Admin', apellido: 'Sistema',
    email: 'admin@citasmedicas.local', password: 'admin123', rol: 'admin'
  )
  puts "✓ Admin creado (id: #{admin.id})"
else
  puts "· Admin ya existe (id: #{admin.id})"
end

# ---------- Usuarios de médicos y recepción ----------
def crear_usuario_si_no_existe(email:, nombre:, apellido:, rol:, password: 'demo123')
  u = Usuario.where(email: email).first
  return [u, false] if u
  [UsuarioService.crear(nombre: nombre, apellido: apellido, email: email,
                        password: password, rol: rol), true]
end

recepcion, creado = crear_usuario_si_no_existe(
  email: 'recepcion@citasmedicas.local',
  nombre: 'Lucía', apellido: 'Recepción', rol: 'recepcion'
)
puts creado ? "✓ Recepción creada (id: #{recepcion.id})" : "· Recepción ya existe"

# ---------- Médicos ----------
def crear_medico_si_no_existe(nombre:, apellido:, especialidad:, matricula:,
                              email:, telefono:, horizonte_dias:)
  m = Medico.where(matricula: matricula).first
  return [m, false] if m
  [Medico.create(
    nombre: nombre, apellido: apellido, especialidad: especialidad,
    matricula: matricula, email: email, telefono: telefono,
    horizonte_dias: horizonte_dias, activo: true
  ), true]
end

medico1, creado = crear_medico_si_no_existe(
  nombre: 'Ana', apellido: 'Gómez', especialidad: 'Clínica Médica',
  matricula: 'MP-1001', email: 'ana.gomez@clinica.local',
  telefono: '555-1001', horizonte_dias: 60
)
puts creado ? "✓ Médico 1 creado (id: #{medico1.id})" : "· Médico 1 ya existe"

medico2, creado = crear_medico_si_no_existe(
  nombre: 'Carlos', apellido: 'Pérez', especialidad: 'Pediatría',
  matricula: 'MP-1002', email: 'carlos.perez@clinica.local',
  telefono: '555-1002', horizonte_dias: 30
)
puts creado ? "✓ Médico 2 creado (id: #{medico2.id})" : "· Médico 2 ya existe"

# ---------- Disponibilidad ----------
def cargar_molde(medico, dias:, bloques:)
  ya_tiene = Disponibilidad.where(medico_id: medico.id).count > 0
  return if ya_tiene

  dias.each do |dia|
    DisponibilidadService.guardar_bloques(
      medico_id: medico.id,
      dia_semana: dia,
      bloques: bloques
    )
  end
end

# Médico 1: lunes a viernes, mañana y tarde, turnos de 30 min
cargar_molde(
  medico1,
  dias: [1, 2, 3, 4, 5],
  bloques: [
    { hora_inicio: '09:00', hora_fin: '13:00', duracion_turno_min: 30 },
    { hora_inicio: '16:00', hora_fin: '20:00', duracion_turno_min: 30 }
  ]
)
puts "✓ Disponibilidad de #{medico1.nombre_completo} cargada" \
  if Disponibilidad.where(medico_id: medico1.id).count > 0

# Médico 2: lunes a viernes, solo mañana, turnos de 20 min
cargar_molde(
  medico2,
  dias: [1, 2, 3, 4, 5],
  bloques: [{ hora_inicio: '10:00', hora_fin: '13:00', duracion_turno_min: 20 }]
)
puts "✓ Disponibilidad de #{medico2.nombre_completo} cargada" \
  if Disponibilidad.where(medico_id: medico2.id).count > 0

# ---------- Pacientes ----------
pacientes_data = [
  { nombre: 'María',   apellido: 'López',    telefono: '555-2001', dni: '11111111' },
  { nombre: 'Juan',    apellido: 'Martínez', telefono: '555-2002', dni: '22222222' },
  { nombre: 'Sofía',   apellido: 'Hernández',telefono: '555-2003', dni: '33333333' },
  { nombre: 'Diego',   apellido: 'Ramírez',  telefono: '555-2004', dni: '44444444' },
  { nombre: 'Valeria', apellido: 'Torres',   telefono: '555-2005', dni: '55555555' },
  { nombre: 'Andrés',  apellido: 'Flores',   telefono: '555-2006', dni: '66666666' },
  { nombre: 'Camila',  apellido: 'Ruiz',     telefono: '555-2007', dni: '77777777' },
  { nombre: 'Luis',    apellido: 'Mendoza',  telefono: '555-2008', dni: '88888888' },
  { nombre: 'Daniela', apellido: 'Soto',     telefono: '555-2009', dni: '99999999' },
  { nombre: 'Pablo',   apellido: 'Castro',   telefono: '555-2010', dni: '10101010' }
]

pacientes = pacientes_data.map do |p|
  pac, creado = PacienteService.buscar_o_crear(
    telefono: p[:telefono], nombre: p[:nombre], apellido: p[:apellido],
    datos_extras: { dni: p[:dni] }
  )
  pac
end
puts "✓ Pacientes disponibles: #{pacientes.size}"

# ---------- Citas de ejemplo ----------
# Buscar los primeros slots libres a partir de mañana y agendar 5 citas
manana = Date.today.next_day
hasta  = Date.today + 14

slots_m1 = DisponibilidadService.slots_libres(medico_id: medico1.id,
                                               desde: Time.new(manana.year, manana.month, manana.day, 0, 0, 0),
                                               hasta: Time.new(hasta.year, hasta.month, hasta.day, 23, 59, 0))
slots_m2 = DisponibilidadService.slots_libres(medico_id: medico2.id,
                                               desde: Time.new(manana.year, manana.month, manana.day, 0, 0, 0),
                                               hasta: Time.new(hasta.year, hasta.month, hasta.day, 23, 59, 0))

puts "· Slots disponibles médico 1: #{slots_m1.size}"
puts "· Slots disponibles médico 2: #{slots_m2.size}"

creadas = 0

# 3 citas con médico 1
pacientes.first(3).each_with_index do |paciente, i|
  slot = slots_m1[i]
  next unless slot
  next if Cita.where(medico_id: medico1.id, fecha_hora: slot[:inicio]).first

  CitaService.crear(
    paciente_id:           paciente.id,
    medico_id:             medico1.id,
    fecha_hora:            slot[:inicio],
    canal_origen:          'presencial',
    creado_por_usuario_id: recepcion.id,
    motivo:                'Consulta general'
  )
  creadas += 1
end

# 2 citas con médico 2
pacientes[3..4].each_with_index do |paciente, i|
  slot = slots_m2[i]
  next unless slot
  next if Cita.where(medico_id: medico2.id, fecha_hora: slot[:inicio]).first

  CitaService.crear(
    paciente_id:           paciente.id,
    medico_id:             medico2.id,
    fecha_hora:            slot[:inicio],
    canal_origen:          'telefono',
    creado_por_usuario_id: recepcion.id,
    motivo:                'Control pediátrico'
  )
  creadas += 1
end

puts "✓ Citas creadas: #{creadas}"

# ---------- Bloqueo de vacaciones de médico 2 ----------
bloqueo_existente = Bloqueo.where(medico_id: medico2.id, motivo: 'vacaciones').first
if bloqueo_existente.nil?
  inicio_vac = Time.new(hasta.year, hasta.month, hasta.day, 0, 0, 0) + 7 * 86_400
  fin_vac    = inicio_vac + 5 * 86_400
  begin
    resultado = BloqueoService.crear(
      medico_id:    medico2.id,
      fecha_inicio: inicio_vac,
      fecha_fin:    fin_vac,
      motivo:       'vacaciones',
      notas:        'Demo: 5 días de vacaciones',
      creado_por_usuario_id: admin.id,
      estrategia:   :marcar
    )
    puts "✓ Bloqueo de vacaciones creado (id: #{resultado[:bloqueo].id})"
    if resultado[:citas_afectadas].any?
      puts "  → #{resultado[:citas_afectadas].size} cita(s) marcadas para reprogramación"
    end
  rescue => e
    puts "· Bloqueo no creado: #{e.message}"
  end
else
  puts "· Bloqueo de vacaciones ya existe"
end

# ---------- Escaneo de avisos ----------
AvisoService.escanear
puts "✓ Escaneo de avisos ejecutado · pendientes: #{AvisoService.pendientes_count}"

puts "== Fin de la carga de demo =="