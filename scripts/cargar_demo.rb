#!/usr/bin/env ruby
require_relative 'env_helper'
require_relative '../services'

puts "== Cargando datos de demo MASIVOS =="

# ---------- Admin y Recepción ----------
admin = Usuario.where(rol: 'admin').first
if admin.nil?
  admin = UsuarioService.crear(
    nombre: 'Admin', apellido: 'Sistema',
    username: 'admin', email: 'admin@citasmedicas.local', 
    password: 'admin123', rol: 'admin'
  )
  puts "✓ Admin creado (id: #{admin.id})"
else
  puts "· Admin ya existe"
end

recepcion = Usuario.where(username: 'recepcion').first
if recepcion.nil?
  recepcion = UsuarioService.crear(
    nombre: 'Lucía', apellido: 'Recepción', username: 'recepcion',
    email: 'recepcion@citasmedicas.local', password: 'demo123', rol: 'recepcion'
  )
  puts "✓ Recepción creada (id: #{recepcion.id})"
else
  puts "· Recepción ya existe"
end

# ---------- Especialidades ----------
puts "⏳ Creando especialidades..."
especialidades_lista = ['Clínica Médica', 'Pediatría', 'Cardiología', 'Dermatología', 'Ginecología', 'Traumatología', 'Oftalmología', 'Psicología', 'Nutrición', 'Odontología']
especialidades_creadas = especialidades_lista.map do |nombre|
  Especialidad.where(nombre: nombre).first || Especialidad.create(nombre: nombre)
end
puts "✓ #{especialidades_creadas.size} Especialidades listas"

# ---------- 10 Médicos ----------
nombres_medicos = ['Ana', 'Carlos', 'María', 'José', 'Laura', 'Roberto', 'Carmen', 'Miguel', 'Elena', 'Javier']
apellidos_medicos = ['Gómez', 'Pérez', 'López', 'Rodríguez', 'Fernández', 'Martínez', 'García', 'Sánchez', 'Romero', 'Díaz']

medicos_creados = []

puts "⏳ Creando 10 médicos con sus horarios..."
10.times do |i|
  matricula = "MP-#{1001 + i}"
  m = Medico.where(matricula: matricula).first
  if m.nil?
    m = Medico.create(
      nombre: nombres_medicos[i], apellido: apellidos_medicos[i], 
      especialidad_id: especialidades_creadas[i].id,
      matricula: matricula,
      email: "#{nombres_medicos[i].downcase}.#{apellidos_medicos[i].downcase}@clinica.local",
      telefono: "555-10#{i.to_s.rjust(2, '0')}", horizonte_dias: [30, 60, 90].sample,
      activo: true
    )
  end
  medicos_creados << m
  
  # Cargar disponibilidad (Lunes a Viernes)
  if Disponibilidad.where(medico_id: m.id).count == 0
    bloques = if i.even?
      [{ hora_inicio: '08:00', hora_fin: '12:00', duracion_turno_min: 30 }, { hora_inicio: '15:00', hora_fin: '19:00', duracion_turno_min: 30 }]
    else
      [{ hora_inicio: '09:00', hora_fin: '13:00', duracion_turno_min: 20 }, { hora_inicio: '14:00', hora_fin: '18:00', duracion_turno_min: 20 }]
    end
    
    [1, 2, 3, 4, 5].each do |dia|
      DisponibilidadService.guardar_bloques(medico_id: m.id, dia_semana: dia, bloques: bloques)
    end
  end
end
puts "✓ 10 Médicos listos con sus horarios"

# ---------- 200 Pacientes ----------
nombres_pac = [
  'María', 'Juan', 'Sofía', 'Diego', 'Valeria', 'Andrés', 'Camila', 'Luis', 'Daniela', 'Pablo', 
  'Marta', 'Pedro', 'Lucía', 'Jorge', 'Elena', 'Raúl', 'Silvia', 'Fernando', 'Gabriela', 'Ricardo',
  'Claudia', 'Héctor', 'Rosa', 'Arturo', 'Beatriz', 'Oscar', 'Teresa', 'Alberto', 'Gloria', 'Eduardo',
  'Gladys', 'Derlis', 'Osvaldo', 'Ramona', 'Blanca', 'Néstor', 'Cinthia', 'Rodrigo', 'Verónica', 'Marcelo',
  'Lorena', 'Gustavo', 'Fabiola', 'Hugo', 'Alicia', 'Víctor', 'Griselda', 'Nelson', 'Mirta', 'César'
]

apellidos_pac = [
  'López', 'Martínez', 'Hernández', 'Ramírez', 'Torres', 'Flores', 'Ruiz', 'Mendoza', 'Soto', 'Castro',
  'Vargas', 'Rojas', 'Silva', 'Ortiz', 'Morales', 'Gutiérrez', 'Chávez', 'Ramos', 'Jiménez', 'Álvarez',
  'Benítez', 'Giménez', 'Ayala', 'Villalba', 'Ocampos', 'Cáceres', 'Franco', 'Acosta', 'Bogado', 'Insfrán'
]

puts "⏳ Generando 200 pacientes..."
200.times do |i|
  nombre = nombres_pac.sample
  apellido = apellidos_pac.sample
  telefono = "555-#{rand(1000..9999)}"
  cedula = "#{rand(1000000..9999999)}"
  
  PacienteService.buscar_o_crear(
    telefono: telefono, nombre: nombre, apellido: apellido,
    datos_extras: { cedula: cedula, email: "#{nombre.downcase.gsub(' ', '')}#{i}@correo.com" }
  )
end
puts "✓ 200 Pacientes creados"

# ---------- NUEVO: Citas Históricas (Para llenar el gráfico del Dashboard) ----------
puts "⏳ Generando citas históricas (últimos 7 días)..."
todos_los_pacientes = Paciente.all

7.times do |i|
  dia_pasado = Date.today - i
  
  # Generamos unas 20 citas por día
  20.times do
    medico = medicos_creados.sample
    paciente = todos_los_pacientes.sample
    
    # Hora entre 08:00 y 18:00
    hora = rand(8..17)
    minuto = [0, 30].sample
    fecha_hora = Time.new(dia_pasado.year, dia_pasado.month, dia_pasado.day, hora, minuto, 0)
    
    # Evitamos duplicados en la misma hora con el mismo médico
    next if Cita.where(medico_id: medico.id, fecha_hora: fecha_hora).count > 0
    
    begin
      # Usamos Cita.create directo para saltear la validación de fecha futura
      Cita.create(
        paciente_id: paciente.id,
        medico_id: medico.id,
        fecha_hora: fecha_hora,
        fecha_hora_fin: fecha_hora + (30 * 60),
        duracion_min: 30,
        estado: ['atendida', 'atendida', 'atendida', 'no_asistio', 'cancelada'].sample,
        canal_origen: ['presencial', 'telefono'].sample,
        motivo: ['Control de rutina', 'Dolor agudo', 'Revisión de estudios'].sample,
        creado_por_usuario_id: recepcion.id,
        codigo_confirmacion: SecureRandom.hex(4).upcase
      )
    rescue => e
      # Ignorar si choca
    end
  end
end
puts "✓ Citas históricas creadas"

# ---------- Citas Futuras ----------
puts "⏳ Generando citas médicas futuras..."
manana = Date.today.next_day
hasta  = Date.today + 15
citas_creadas = 0

medicos_creados.each do |medico|
  slots = DisponibilidadService.slots_libres(
    medico_id: medico.id, 
    desde: Time.new(manana.year, manana.month, manana.day, 0, 0, 0),
    hasta: Time.new(hasta.year, hasta.month, hasta.day, 23, 59, 0)
  )
  
  slots.sample(15).each do |slot|
    paciente = todos_los_pacientes.sample
    canal = ['presencial', 'telefono', 'presencial'].sample
    
    begin
      CitaService.crear(
        paciente_id: paciente.id, medico_id: medico.id,
        fecha_hora: slot[:inicio], canal_origen: canal,
        creado_por_usuario_id: recepcion.id,
        motivo: ['Control de rutina', 'Dolor agudo', 'Revisión de estudios', 'Primera consulta'].sample
      )
      citas_creadas += 1
    rescue => e
    end
  end
end
puts "✓ #{citas_creadas} Citas futuras creadas"

# ---------- Bloqueo de vacaciones (para probar ausencias) ----------
if Bloqueo.where(motivo: 'vacaciones').count == 0
  medico_vac = medicos_creados.sample
  inicio_vac = Time.new(hasta.year, hasta.month, hasta.day, 0, 0, 0) + 2 * 86_400
  fin_vac    = inicio_vac + 5 * 86_400
  
  begin
    resultado = BloqueoService.crear(
      medico_id: medico_vac.id, fecha_inicio: inicio_vac, fecha_fin: fin_vac,
      motivo: 'vacaciones', notas: 'Demo: ausencia programada',
      creado_por_usuario_id: admin.id, estrategia: :marcar
    )
    puts "✓ Bloqueo de vacaciones creado para #{medico_vac.nombre_completo}"
    if resultado[:citas_afectadas].any?
      puts "  → #{resultado[:citas_afectadas].size} cita(s) marcadas para reprogramación"
    end
  rescue => e
    puts "· Bloqueo no creado: #{e.message}"
  end
end

# ---------- Avisos de ejemplo extra ----------
puts "⏳ Generando avisos de ejemplo extra..."
unless Medico.where(matricula: 'MP-9999').first
  Medico.create(
    nombre: 'Gregorio', apellido: 'SinHorario',
    especialidad_id: especialidades_creadas.first.id,
    matricula: 'MP-9999', email: 'gregorio@clinica.local', activo: true
  )
end

AvisoService.emitir(
  tipo: 'error_sistema', severidad: 'error', entidad_tipo: 'sistema', entidad_id: nil,
  titulo: 'Error de conexión con el servidor de correos',
  detalle: 'No se pudieron enviar los recordatorios de mañana. Revisá la configuración SMTP.'
)

AvisoService.emitir(
  tipo: 'advertencia_generica', severidad: 'warning', entidad_tipo: 'sistema', entidad_id: nil,
  titulo: 'Pocos turnos disponibles',
  detalle: 'Quedan menos de 5 turnos libres para la próxima semana con los médicos de guardia.'
)

# ---------- Escaneo de avisos ----------
AvisoService.escanear
puts "✓ Escaneo de avisos ejecutado · pendientes: #{AvisoService.pendientes_count}"

puts "== ¡Carga de demo terminada! =="