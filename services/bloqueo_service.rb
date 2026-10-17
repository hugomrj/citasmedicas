module BloqueoService
  module_function

  def crear(medico_id:, fecha_inicio:, fecha_fin:, motivo:, notas: nil,
            creado_por_usuario_id: nil, estrategia: :rechazar)
    medico = Medico[medico_id]
    raise ArgumentError, 'Médico no encontrado' unless medico

    if fecha_fin <= fecha_inicio
      raise ArgumentError, 'fecha_fin debe ser posterior a fecha_inicio'
    end
    if fecha_fin <= Time.now
      raise ArgumentError, 'No se puede crear un bloqueo en el pasado'
    end

    DB.transaction do
      validar_sin_solapamiento(medico_id, fecha_inicio, fecha_fin)

      afectadas = citas_dentro_del_rango(medico_id, fecha_inicio, fecha_fin)

      if afectadas.any? && estrategia == :rechazar
        raise ArgumentError,
              "Hay #{afectadas.size} cita(s) agendada(s) en ese rango. " \
              "Reprogramalas o cancelalas antes de crear el bloqueo."
      end

      bloqueo = Bloqueo.create(
        medico_id:             medico_id,
        fecha_inicio:          fecha_inicio,
        fecha_fin:             fecha_fin,
        motivo:                motivo,
        notas:                 notas,
        creado_por_usuario_id: creado_por_usuario_id
      )

      afectadas.each do |cita|
        cita.update(
          estado:             'requiere_reprogramacion',
          cancelada_por:      'sistema',
          motivo_cancelacion: "Ausencia del médico: #{motivo}",
          cancelada_en:       Time.now
        )
      end

      { bloqueo: bloqueo, citas_afectadas: afectadas }
    end
  end

  def cancelar(bloqueo_id)
    bloqueo = Bloqueo[bloqueo_id]
    raise ArgumentError, 'Bloqueo no encontrado' unless bloqueo
    bloqueo.update(cancelado_en: Time.now)
    bloqueo
  end

  def citas_dentro_del_rango(medico_id, inicio, fin)
    Cita.where(medico_id: medico_id)
        .where(estado: Cita::ESTADOS_QUE_OCUPAN_SLOT)
        .where { fecha_hora < fin }
        .where { fecha_hora_fin > inicio }
        .order(:fecha_hora)
        .all
  end

  def activos(medico_id)
    Bloqueo.where(medico_id: medico_id, cancelado_en: nil)
           .where { fecha_fin > Time.now }
           .order(:fecha_inicio)
           .all
  end

  def validar_sin_solapamiento(medico_id, inicio, fin)
    cruza = Bloqueo.where(medico_id: medico_id, cancelado_en: nil)
                   .where { fecha_inicio < fin }
                   .where { fecha_fin > inicio }
                   .count
    return if cruza.zero?
    raise ArgumentError, 'Ya existe un bloqueo que se solapa con esas fechas'
  end
end
