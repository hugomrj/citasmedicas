module DisponibilidadService
  module_function

  def slots_libres(medico_id:, desde:, hasta:)
    medico = Medico[medico_id]
    return [] unless medico && medico.activo

    ahora         = Time.now
    anticipacion  = ahora + (Configuracion.anticipacion_minima_horas * 3600)
    horizonte_max = ahora + (medico.horizonte_efectivo * 86_400)

    desde = [desde, anticipacion].max
    hasta = [hasta, horizonte_max].min
    return [] if desde > hasta

    citas_ocupadas = Cita.where(medico_id: medico_id)
                         .where(estado: Cita::ESTADOS_QUE_OCUPAN_SLOT)
                         .where { fecha_hora < hasta }
                         .where { fecha_hora_fin > desde }
                         .all

    bloqueos_activos = Bloqueo.where(medico_id: medico_id, cancelado_en: nil)
                              .where { fecha_inicio < hasta }
                              .where { fecha_fin > desde }
                              .all

    slots = []
    fecha_actual = desde.to_date
    fecha_tope   = hasta.to_date

    while fecha_actual <= fecha_tope
      bloques = bloques_del_dia(medico_id, fecha_actual)

      bloques.each do |bloque|
        duracion_seg = bloque.duracion_turno_min * 60

        slots_del_bloque(bloque, fecha_actual).each do |slot_inicio|
          slot_fin = slot_inicio + duracion_seg

          next if slot_inicio < desde
          next if slot_fin    > hasta

          next if bloqueos_activos.any? { |b| solapa?(b.fecha_inicio, b.fecha_fin, slot_inicio, slot_fin) }
          next if citas_ocupadas.any?  { |c| solapa?(c.fecha_hora, c.fecha_hora_fin, slot_inicio, slot_fin) }

          slots << {
            inicio:       slot_inicio,
            fin:          slot_fin,
            medico_id:    medico_id,
            duracion_min: bloque.duracion_turno_min
          }
        end
      end

      fecha_actual += 1
    end

    slots.sort_by { |s| s[:inicio] }
  end

  def bloques_del_dia(medico_id, fecha)
    overrides = Disponibilidad.where(medico_id: medico_id, fecha_especifica: fecha).all
    return overrides if overrides.any?

    Disponibilidad.where(medico_id: medico_id, dia_semana: fecha.wday).all
  end

  def slots_del_bloque(bloque, fecha)
    hi, mi = bloque.hora_inicio.split(':').map(&:to_i)
    hf, mf = bloque.hora_fin.split(':').map(&:to_i)

    inicio_bloque = Time.new(fecha.year, fecha.month, fecha.day, hi, mi, 0)
    fin_bloque    = Time.new(fecha.year, fecha.month, fecha.day, hf, mf, 0)
    dur_seg       = bloque.duracion_turno_min * 60

    slots = []
    cursor = inicio_bloque
    while cursor + dur_seg <= fin_bloque
      slots << cursor
      cursor += dur_seg
    end
    slots
  end

  def duracion_del_slot(medico, fecha_hora)
    fecha   = fecha_hora.to_date
    bloques = bloques_del_dia(medico.id, fecha)

    bloques.each do |bloque|
      hi, mi = bloque.hora_inicio.split(':').map(&:to_i)
      hf, mf = bloque.hora_fin.split(':').map(&:to_i)

      inicio_bloque = Time.new(fecha.year, fecha.month, fecha.day, hi, mi, 0)
      fin_bloque    = Time.new(fecha.year, fecha.month, fecha.day, hf, mf, 0)
      dur_seg       = bloque.duracion_turno_min * 60

      next unless fecha_hora >= inicio_bloque && (fecha_hora + dur_seg) <= fin_bloque

      offset = (fecha_hora - inicio_bloque).to_i
      return bloque.duracion_turno_min if offset % dur_seg == 0
    end

    nil
  end

  def citas_fuera_del_nuevo_horario(medico_id, fecha_desde: Time.now)
    medico = Medico[medico_id]
    return [] unless medico

    citas = Cita.where(medico_id: medico_id)
                .where(estado: Cita::ESTADOS_QUE_OCUPAN_SLOT)
                .where { fecha_hora >= fecha_desde }
                .order(:fecha_hora)
                .all

    citas.reject { |c| duracion_del_slot(medico, c.fecha_hora) }
  end

  def guardar_bloques(medico_id:, fecha_especifica: nil, dia_semana: nil, bloques:)
    raise ArgumentError, 'Debe indicar fecha_especifica O dia_semana, no ambos' if fecha_especifica && !dia_semana.nil?
    raise ArgumentError, 'Debe indicar fecha_especifica O dia_semana, no ninguno' if fecha_especifica.nil? && dia_semana.nil?
    raise ArgumentError, 'Debe enviar al menos un bloque' if bloques.nil? || bloques.empty?

    validar_bloques_sin_solapamiento(bloques)

    DB.transaction do
      if fecha_especifica
        Disponibilidad.where(medico_id: medico_id, fecha_especifica: fecha_especifica).delete
      else
        Disponibilidad.where(medico_id: medico_id, dia_semana: dia_semana).delete
      end

      bloques.map do |b|
        Disponibilidad.create(
          medico_id:          medico_id,
          fecha_especifica:   fecha_especifica,
          dia_semana:         dia_semana,
          hora_inicio:        b[:hora_inicio],
          hora_fin:           b[:hora_fin],
          duracion_turno_min: b[:duracion_turno_min] || 30
        )
      end
    end
  end

  def solapa?(a_inicio, a_fin, b_inicio, b_fin)
    a_inicio < b_fin && a_fin > b_inicio
  end

  def validar_bloques_sin_solapamiento(bloques)
    ordenados = bloques.sort_by { |b| b[:hora_inicio] }
    ordenados.each_cons(2) do |a, b|
      if a[:hora_fin] > b[:hora_inicio]
        raise ArgumentError,
              "Bloques solapados: #{a[:hora_inicio]}-#{a[:hora_fin]} y #{b[:hora_inicio]}-#{b[:hora_fin]}"
      end
    end
  end
end
