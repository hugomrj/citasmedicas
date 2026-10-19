module AvisoService
  module_function

  def emitir(tipo:, severidad:, entidad_tipo:, entidad_id:, titulo:, detalle: nil)
    DB.transaction do
      existente = Aviso.where(
        tipo:         tipo,
        entidad_tipo: entidad_tipo,
        entidad_id:   entidad_id,
        estado:       %w[pendiente visto]
      ).first
      return existente if existente

      Aviso.create(
        tipo:         tipo,
        severidad:    severidad,
        entidad_tipo: entidad_tipo,
        entidad_id:   entidad_id,
        titulo:       titulo,
        detalle:      detalle,
        estado:       'pendiente'
      )
    end
  end

  def auto_resolver_por_entidad(entidad_tipo:, entidad_id:)
    Aviso.where(
      entidad_tipo: entidad_tipo,
      entidad_id:   entidad_id,
      estado:       %w[pendiente visto]
    ).all.each do |a|
      a.update(estado: 'resuelto', resuelto_en: Time.now)
    end
  end

  def pendientes
    Aviso.where(estado: %w[pendiente visto]).order(Sequel.desc(:created_at)).all
  end

  def pendientes_count
    Aviso.where(estado: %w[pendiente visto]).count
  end

  def escanear
    Cita.where(estado: 'requiere_reprogramacion').all.each do |cita|
      emitir(
        tipo:         'cita_requiere_reprogramacion',
        severidad:    'warning',
        entidad_tipo: 'cita',
        entidad_id:   cita.id,
        titulo:       "Cita ##{cita.id} requiere reprogramación",
        detalle:      "Paciente ##{cita.paciente_id} · Médico ##{cita.medico_id} · " \
                      "#{cita.fecha_hora.strftime('%d/%m/%Y %H:%M')}"
      )
    end

    Bloqueo.where(cancelado_en: nil).where { fecha_fin > Time.now }.all.each do |bloqueo|
      afectadas = BloqueoService.citas_dentro_del_rango(
        bloqueo.medico_id, bloqueo.fecha_inicio, bloqueo.fecha_fin
      )
      next if afectadas.empty?

      emitir(
        tipo:         'bloqueo_con_citas_dentro',
        severidad:    'error',
        entidad_tipo: 'bloqueo',
        entidad_id:   bloqueo.id,
        titulo:       "Bloqueo ##{bloqueo.id} tiene citas dentro",
        detalle:      "#{afectadas.size} cita(s) en el rango " \
                      "#{bloqueo.fecha_inicio.strftime('%d/%m/%Y')} – " \
                      "#{bloqueo.fecha_fin.strftime('%d/%m/%Y')}"
      )
    end

    Medico.where(activo: true).all.each do |medico|
      tiene = Disponibilidad.where(medico_id: medico.id).count > 0
      next if tiene

      emitir(
        tipo:         'medico_sin_disponibilidad',
        severidad:    'info',
        entidad_tipo: 'medico',
        entidad_id:   medico.id,
        titulo:       "Médico ##{medico.id} sin horarios configurados",
        detalle:      "#{medico.nombre_completo} no tiene bloques de disponibilidad cargados"
      )
    end

    Aviso.where(tipo: 'cita_requiere_reprogramacion', estado: %w[pendiente visto]).all.each do |aviso|
      cita = Cita[aviso.entidad_id]
      next if cita && cita.estado == 'requiere_reprogramacion'
      aviso.update(estado: 'resuelto', resuelto_en: Time.now)
    end

    Aviso.where(tipo: 'bloqueo_con_citas_dentro', estado: %w[pendiente visto]).all.each do |aviso|
      b = Bloqueo[aviso.entidad_id]
      if b.nil? || b.cancelado_en
        aviso.update(estado: 'resuelto', resuelto_en: Time.now)
        next
      end
      afectadas = BloqueoService.citas_dentro_del_rango(b.medico_id, b.fecha_inicio, b.fecha_fin)
      aviso.update(estado: 'resuelto', resuelto_en: Time.now) if afectadas.empty?
    end

    ConfiguracionService.marcar_escaneo_avisos!
    true
  end

  def escanear_throttled(min_intervalo: 300)
    ultimo = Configuracion.ultimo_escaneo_avisos
    return false if (Time.now - ultimo) < min_intervalo
    escanear
  end
end
