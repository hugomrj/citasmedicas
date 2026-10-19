module AgendaCitasRoutes
  def self.registered(app)
    # 1. Listado de Citas (Con filtros)
    app.get '/agenda' do
      requiere_login!
      @crumb_here = 'Agenda'
      
      fecha = params[:fecha] || Date.today.to_s
      @fecha_actual = fecha
      
      inicio_dia = Time.parse("#{fecha} 00:00:00")
      fin_dia = inicio_dia + 86_400

      @citas = Cita.where { fecha_hora >= inicio_dia }
                   .where { fecha_hora < fin_dia }
                   .order(:fecha_hora)
                   .all

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

    # 3. API interna para pedir turnos libres (AJAX)
    app.get '/agenda/slots' do
      content_type :json
      medico_id = params[:medico_id]
      fecha = params[:fecha]

      return [].to_json if medico_id.nil? || fecha.nil?

      inicio = Time.parse("#{fecha} 00:00:00")
      fin = inicio + 86_400

      begin
        slots = DisponibilidadService.slots_libres(medico_id: medico_id.to_i, desde: inicio, hasta: fin)
        # Devolvemos solo la hora formateada para el select
        slots.map { |s| { hora: s[:inicio].strftime('%H:%M'), datetime: s[:inicio].to_s } }.to_json
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

    # 5. Cancelar Cita
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
  end
end