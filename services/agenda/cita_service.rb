module CitaService
  module_function

  TRANSICIONES = {
    'pendiente'                => %w[confirmada cancelada atendida no_asistio requiere_reprogramacion],
    'confirmada'               => %w[cancelada atendida no_asistio requiere_reprogramacion],
    'requiere_reprogramacion'  => %w[pendiente confirmada cancelada],
    'cancelada'                => %w[pendiente],
    'atendida'                 => [],
    'no_asistio'               => []
  }.freeze

  def crear(paciente_id:, medico_id:, fecha_hora:, canal_origen: 'presencial',
            creado_por_usuario_id: nil, motivo: nil, notas_internas: nil,
            reprogramada_desde_id: nil)
    paciente = Paciente[paciente_id]
    raise ArgumentError, 'Paciente no encontrado' unless paciente
    raise ArgumentError, 'Paciente archivado' if paciente.archivado

    medico = Medico[medico_id]
    raise ArgumentError, 'Médico no encontrado' unless medico
    raise ArgumentError, 'Médico inactivo' unless medico.activo

    duracion = DisponibilidadService.duracion_del_slot(medico, fecha_hora)
    raise ArgumentError, 'El horario no coincide con la disponibilidad del médico' unless duracion

    validar_anticipacion(fecha_hora)
    validar_horizonte(medico, fecha_hora)

    fecha_hora_fin = fecha_hora + (duracion * 60)

    validar_sin_bloqueo(medico_id, fecha_hora, fecha_hora_fin)

    DB.transaction do
      validar_sin_solapamiento_medico(medico_id, fecha_hora, fecha_hora_fin)
      validar_sin_solapamiento_paciente(paciente_id, fecha_hora, fecha_hora_fin)

      Cita.create(
        paciente_id:           paciente_id,
        medico_id:             medico_id,
        fecha_hora:            fecha_hora,
        fecha_hora_fin:        fecha_hora_fin,
        duracion_min:          duracion,
        estado:                'pendiente',
        canal_origen:          canal_origen,
        motivo:                motivo,
        notas_internas:        notas_internas,
        codigo_confirmacion:   generar_codigo_unico,
        creado_por_usuario_id: creado_por_usuario_id,
        reprogramada_desde_id: reprogramada_desde_id
      )
    end
  end

  def reprogramar(cita_id:, nueva_fecha_hora:, reprogramado_por: 'staff',
                  motivo_cancelacion: nil, creado_por_usuario_id: nil)
    original = Cita[cita_id]
    raise ArgumentError, 'Cita no encontrada' unless original
    raise ArgumentError, 'Solo se pueden reprogramar citas pendientes o confirmadas' unless original.ocupa_slot?

    nueva = crear(
      paciente_id:           original.paciente_id,
      medico_id:             original.medico_id,
      fecha_hora:            nueva_fecha_hora,
      canal_origen:          original.canal_origen,
      creado_por_usuario_id: creado_por_usuario_id,
      motivo:                original.motivo,
      notas_internas:        original.notas_internas,
      reprogramada_desde_id: original.id
    )

    DB.transaction do
      original.update(
        estado:             'requiere_reprogramacion',
        cancelada_por:      reprogramado_por,
        motivo_cancelacion: motivo_cancelacion,
        cancelada_en:       Time.now
      )
    end

    nueva
  end

  def cambiar_estado(cita_id:, nuevo_estado:, usuario_id: nil, motivo: nil, cancelada_por: nil)
    cita = Cita[cita_id]
    raise ArgumentError, 'Cita no encontrada' unless cita

    permitidos = TRANSICIONES[cita.estado] || []
    unless permitidos.include?(nuevo_estado)
      raise ArgumentError, "Transición no permitida: #{cita.estado} → #{nuevo_estado}"
    end

    attrs = { estado: nuevo_estado }

    case nuevo_estado
    when 'cancelada'
      raise ArgumentError, 'cancelada_por es obligatorio al cancelar' unless cancelada_por
      attrs[:cancelada_por]      = cancelada_por
      attrs[:motivo_cancelacion] = motivo
      attrs[:cancelada_en]       = Time.now
    when 'atendida'
      attrs[:atendida_en] = Time.now
    when 'no_asistio'
      attrs[:no_asistio_en] = Time.now
    end

    DB.transaction do
      if nuevo_estado == 'pendiente' && cita.estado == 'cancelada'
        validar_sin_solapamiento_medico(cita.medico_id, cita.fecha_hora, cita.fecha_hora_fin, excluir_id: cita.id)
        validar_sin_solapamiento_paciente(cita.paciente_id, cita.fecha_hora, cita.fecha_hora_fin, excluir_id: cita.id)
        attrs[:cancelada_por]      = nil
        attrs[:motivo_cancelacion] = nil
        attrs[:cancelada_en]       = nil
      end

      cita.update(attrs)
    end

    cita
  end

  def cancelar_por_codigo(codigo:, cancelada_por: 'paciente', motivo: nil, usuario_id: nil)
    cita = Cita.where(codigo_confirmacion: codigo).first
    raise ArgumentError, 'Código de cita no encontrado' unless cita
    raise ArgumentError, 'La cita ya está cancelada' if cita.estado == 'cancelada'
    raise ArgumentError, 'No se puede cancelar una cita pasada' if cita.pasada?

    cambiar_estado(
      cita_id:       cita.id,
      nuevo_estado:  'cancelada',
      usuario_id:    usuario_id,
      motivo:        motivo,
      cancelada_por: cancelada_por
    )
  end

  def validar_anticipacion(fecha_hora)
    min_horas = Configuracion.anticipacion_minima_horas
    limite    = Time.now + (min_horas * 3600)
    return if fecha_hora >= limite
    raise ArgumentError, "Debe agendarse con al menos #{min_horas} hora(s) de anticipación"
  end

  def validar_horizonte(medico, fecha_hora)
    max_dias = medico.horizonte_efectivo
    limite   = Time.now + (max_dias * 86_400)
    return if fecha_hora <= limite
    raise ArgumentError, "No se puede agendar con más de #{max_dias} día(s) de anticipación"
  end

  def validar_sin_bloqueo(medico_id, inicio, fin)
    cruza = Bloqueo.where(medico_id: medico_id, cancelado_en: nil)
                   .where { fecha_inicio < fin }
                   .where { fecha_fin > inicio }
                   .count
    return if cruza.zero?
    raise ArgumentError, 'El médico no atiende en esa fecha (ausencia programada)'
  end

  def validar_sin_solapamiento_medico(medico_id, inicio, fin, excluir_id: nil)
    ds = Cita.where(medico_id: medico_id)
             .where(estado: Cita::ESTADOS_QUE_OCUPAN_SLOT)
             .where { fecha_hora < fin }
             .where { fecha_hora_fin > inicio }
    ds = ds.exclude(id: excluir_id) if excluir_id
    return if ds.count.zero?
    raise ArgumentError, 'El horario ya está ocupado para este médico'
  end

  def validar_sin_solapamiento_paciente(paciente_id, inicio, fin, excluir_id: nil)
    ds = Cita.where(paciente_id: paciente_id)
             .where(estado: Cita::ESTADOS_QUE_OCUPAN_SLOT)
             .where { fecha_hora < fin }
             .where { fecha_hora_fin > inicio }
    ds = ds.exclude(id: excluir_id) if excluir_id
    return if ds.count.zero?
    raise ArgumentError, 'El paciente ya tiene otra cita en ese horario'
  end

  def generar_codigo_unico
    5.times do
      codigo = SecureRandom.hex(4).upcase
      return codigo unless Cita.where(codigo_confirmacion: codigo).first
    end
    raise 'No se pudo generar un código de confirmación único'
  end
end
