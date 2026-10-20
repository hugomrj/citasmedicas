  module AgendaCitasRoutes
  def self.registered(app)
    # 1. Listado de Citas del día con filtros
    app.get '/agenda' do
      requiere_login!
      @crumb_here = 'Agenda'
      
      fecha_str = params[:fecha].to_s.strip
      fecha_str = Date.today.to_s if fecha_str.empty?
      
      begin
        fecha_date = Date.parse(fecha_str)
      rescue ArgumentError
        fecha_date = Date.today
      end

      @fecha_actual = fecha_date.to_s
      
      inicio_dia = Time.new(fecha_date.year, fecha_date.month, fecha_date.day, 0, 0, 0)
      fin_dia = inicio_dia + 86_400

      ds = Cita.where { fecha_hora >= inicio_dia }.where { fecha_hora < fin_dia }

      # Filtro por pestaña
      status_filter = params[:status] || 'todas'
      case status_filter
      when 'pendientes' then ds = ds.where(estado: %w[pendiente confirmada])
      when 'atendidas'  then ds = ds.where(estado: 'atendida')
      when 'no_asistio' then ds = ds.where(estado: 'no_asistio')
      when 'canceladas' then ds = ds.where(estado: 'cancelada')
      end
      @status_actual = status_filter


      # Filtros
      paciente_id = params[:paciente_id]
      medico_id = params[:medico_id]
      ds = ds.where(paciente_id: paciente_id) if paciente_id && !paciente_id.empty?
      ds = ds.where(medico_id: medico_id) if medico_id && !medico_id.empty?

      @citas = ds.order(:fecha_hora).all

      # Contadores
      citas_del_dia = Cita.where { fecha_hora >= inicio_dia }.where { fecha_hora < fin_dia }
      @contador_todas = citas_del_dia.count
      @contador_pendientes = citas_del_dia.where(estado: %w[pendiente confirmada]).count
      @contador_atendidas = citas_del_dia.where(estado: 'atendida').count
      @contador_no_asistio = citas_del_dia.where(estado: 'no_asistio').count
      @contador_canceladas = citas_del_dia.where(estado: 'cancelada').count

      # Datos para los selects
      @pacientes_filtro = Paciente.where(archivado: false).order(:apellido, :nombre).all
      @medicos_filtro = Medico.where(activo: true).order(:apellido, :nombre).all
      @paciente_actual = paciente_id
      @medico_actual = medico_id

      erb :'agenda/citas/index', layout: :'layout/base'
    end

    # 2. Formulario NUEVA Cita
    app.get '/agenda/nueva' do
      requiere_login!
      @crumb_here = 'Nueva Cita'
      @pacientes = Paciente.where(archivado: false).order(:apellido, :nombre).all
      @medicos = Medico.where(activo: true).order(:apellido, :nombre).all
      erb :'agenda/citas/form', layout: :'layout/base'
    end

    # 3. API interna para pedir turnos (Muestra ocupados y libres)
    app.get '/agenda/slots' do
      content_type :json
      medico_id = params[:medico_id]
      fecha_str = params[:fecha]

      return [].to_json if medico_id.nil? || fecha_str.nil?

      begin
        fecha_date = Date.parse(fecha_str)
        
        # 1. Obtenemos todos los bloques teóricos de ese día
        bloques = DisponibilidadService.bloques_del_dia(medico_id.to_i, fecha_date)
        todos_los_slots = []
        
        bloques.each do |bloque|
          todos_los_slots += DisponibilidadService.slots_del_bloque(bloque, fecha_date)
        end

        # 2. Obtenemos los que realmente están libres
        inicio = Time.new(fecha_date.year, fecha_date.month, fecha_date.day, 0, 0, 0)
        fin = inicio + 86_400
        slots_libres = DisponibilidadService.slots_libres(medico_id: medico_id.to_i, desde: inicio, hasta: fin)
        
        # Extraemos solo los tiempos de inicio de los libres
        tiempos_libres = slots_libres.map { |s| s[:inicio] }

        # 3. Armamos la respuesta comparando
        respuesta = todos_los_slots.map do |slot_inicio|
          {
            hora: slot_inicio.strftime('%H:%M'),
            datetime: slot_inicio.to_s,
            disponible: tiempos_libres.include?(slot_inicio)
          }
        end

        respuesta.to_json
      rescue => e
        [].to_json
      end
    end

    # 4. Guardar NUEVA Cita
    app.post '/agenda' do
      requiere_login!
      begin
        CitaService.crear(
          paciente_id: params[:paciente_id],
          medico_id: params[:medico_id],
          fecha_hora: Time.parse(params[:fecha_hora]),
          canal_origen: 'presencial',
          creado_por_usuario_id: usuario_actual.id,
          motivo: params[:motivo]
        )
        flash[:success] = 'Cita agendada correctamente.'
        redirect '/agenda'
      rescue ArgumentError => e
        flash[:error] = e.message
        @pacientes = Paciente.where(archivado: false).order(:apellido, :nombre).all
        @medicos = Medico.where(activo: true).order(:apellido, :nombre).all
        erb :'agenda/citas/form', layout: :'layout/base'
      end
    end

    # 5. Cancelar Cita (Ruta rápida)
    app.post '/agenda/:id/cancelar' do
      requiere_login!
      begin
        CitaService.cambiar_estado(
          cita_id: params[:id],
          nuevo_estado: 'cancelada',
          usuario_id: usuario_actual.id,
          motivo: 'Cancelada desde agenda',
          cancelada_por: 'staff'
        )
        flash[:success] = 'Cita cancelada correctamente.'
      rescue ArgumentError => e
        flash[:error] = e.message
      end
      redirect '/agenda'
    end

    # 6. Formulario EDITAR Cita
    app.get '/agenda/:id/editar' do
      requiere_login!
      @crumb_here = 'Editar Cita'
      @cita = Cita[params[:id]]
      halt 404, "Cita no encontrada" unless @cita
      
      @pacientes = Paciente.where(archivado: false).order(:apellido, :nombre).all
      @medicos = Medico.where(activo: true).order(:apellido, :nombre).all
      erb :'agenda/citas/form', layout: :'layout/base'
    end

    # 7. Guardar EDICIÓN de Cita
    app.post '/agenda/:id/actualizar' do
      requiere_login!
      @cita = Cita[params[:id]]
      halt 404, "Cita no encontrada" unless @cita
      
      begin
        nueva_fecha = Time.parse(params[:fecha_hora])
        medico = Medico[params[:medico_id]]
        
        # 1. Validar que el horario no esté ocupado por OTRA cita del mismo médico
        if Cita.where(medico_id: medico.id, fecha_hora: nueva_fecha)
               .exclude(id: @cita.id)
               .where(estado: %w[pendiente confirmada]).count > 0
          raise ArgumentError, "El horario ya está ocupado por otro paciente."
        end

        # 2. Validar que el paciente no tenga otra cita a la misma hora
        if Cita.where(paciente_id: params[:paciente_id], fecha_hora: nueva_fecha)
               .exclude(id: @cita.id)
               .where(estado: %w[pendiente confirmada]).count > 0
          raise ArgumentError, "El paciente ya tiene otra cita en ese horario."
        end

        # 3. Validar que la hora coincida con la disponibilidad del médico
        duracion = DisponibilidadService.duracion_del_slot(medico, nueva_fecha)
        raise ArgumentError, "El horario no coincide con la disponibilidad del médico." unless duracion

        @cita.update(
          paciente_id: params[:paciente_id],
          medico_id: params[:medico_id],
          fecha_hora: nueva_fecha,
          fecha_hora_fin: nueva_fecha + (duracion * 60),
          duracion_min: duracion,
          motivo: params[:motivo]
        )
        flash[:success] = 'Cita actualizada correctamente.'
        redirect '/agenda'
      rescue ArgumentError => e
        flash[:error] = e.message
        @pacientes = Paciente.where(archivado: false).order(:apellido, :nombre).all
        @medicos = Medico.where(activo: true).order(:apellido, :nombre).all
        erb :'agenda/citas/form', layout: :'layout/base'
      end
    end

    # 8. Cambiar estado rápido (Confirmar, Atender, No asistió)
    app.post '/agenda/:id/estado' do
      requiere_login!
      begin
        # Si se cancela desde el menú, guardamos el motivo por defecto
        motivo = params[:nuevo_estado] == 'cancelada' ? 'Cancelada desde agenda' : nil
        
        CitaService.cambiar_estado(
          cita_id: params[:id],
          nuevo_estado: params[:nuevo_estado],
          usuario_id: usuario_actual.id,
          motivo: motivo,
          cancelada_por: params[:nuevo_estado] == 'cancelada' ? 'staff' : nil
        )
        flash[:success] = "Cita actualizada a: #{params[:nuevo_estado].gsub('_', ' ')}."
      rescue ArgumentError => e
        flash[:error] = e.message
      end
      redirect '/agenda'
    end
  end
end