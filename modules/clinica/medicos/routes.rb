module ClinicaMedicosRoutes
  def self.registered(app)
    # 1. Listado con filtros
    app.get '/medicos' do
      requiere_login!
      @crumb_here = 'Médicos'
      
      query = params[:q].to_s.strip
      status_filter = params[:status] || 'activos'
      @pagina_actual = (params[:page] || 1).to_i
      limite = 20
      
      ds = Medico.dataset
      
      case status_filter
      when 'activos' then ds = ds.where(activo: true)
      when 'inactivos' then ds = ds.where(activo: false)
      end

      if query.empty?
        @medicos_ds = ds
      else
        patron = "%#{query.downcase}%"
        # CAMBIO ACÁ: Agregamos .select_all(:medicos)
        ds = ds.join(:especialidades, id: :especialidad_id).select_all(:medicos)
        
        @medicos_ds = ds.where(
          Sequel.like(Sequel.function(:lower, Sequel[:medicos][:nombre]), patron) |
          Sequel.like(Sequel.function(:lower, Sequel[:medicos][:apellido]), patron) |
          Sequel.like(Sequel.function(:lower, Sequel[:especialidades][:nombre]), patron) |
          Sequel.like(Sequel.function(:lower, Sequel[:medicos][:matricula]), patron)
        )
      end

      @total_registros = @medicos_ds.count
      @total_paginas = (@total_registros.to_f / limite).ceil
      
      @medicos = @medicos_ds.order(Sequel[:medicos][:apellido], Sequel[:medicos][:nombre])
                            .limit(limite)
                            .offset((@pagina_actual - 1) * limite)
                            .all

      @status_actual = status_filter
      @query_actual = query
      
      @contador_todos = Medico.count
      @contador_activos = Medico.where(activo: true).count
      @contador_inactivos = Medico.where(activo: false).count

      if request.xhr?
        erb :'clinica/medicos/_tabla', layout: false
      else
        erb :'clinica/medicos/index', layout: :'layout/base'
      end
    end

    # 2. Formulario NUEVO
    app.get '/medicos/nuevo' do
      requiere_login!
      @crumb_here = 'Nuevo Médico'
      @medico = Medico.new
      @especialidades = Especialidad.order(:nombre).all
      erb :'clinica/medicos/form', layout: :'layout/base'
    end

    # 3. Guardar NUEVO
    app.post '/medicos' do
      requiere_login!
      begin
        nuevo_medico = Medico.create(
          nombre: params[:nombre],
          apellido: params[:apellido],
          especialidad_id: params[:especialidad_id],
          matricula: params[:matricula],
          email: params[:email].to_s.strip.empty? ? nil : params[:email],
          telefono: params[:telefono].to_s.strip.empty? ? nil : params[:telefono],
          horizonte_dias: params[:horizonte_dias].to_s.strip.empty? ? nil : params[:horizonte_dias].to_i,
          activo: true
        )
        flash[:success] = 'Médico creado correctamente. Ahora configurá sus horarios.'
        redirect "/disponibilidad/#{nuevo_medico.id}" # <-- Redirección directa a sus horarios
      rescue Sequel::ValidationFailed => e
        flash[:error] = e.message
        @medico = Medico.new(params)
        @especialidades = Especialidad.order(:nombre).all
        erb :'clinica/medicos/form', layout: :'layout/base'
      end
    end

    # 4. Formulario EDITAR
    app.get '/medicos/:id/editar' do
      requiere_login!
      @crumb_here = 'Editar Médico'
      @medico = Medico[params[:id]]
      halt 404, "Médico no encontrado" unless @medico
      @especialidades = Especialidad.order(:nombre).all
      erb :'clinica/medicos/form', layout: :'layout/base'
    end

    # 5. Guardar EDICIÓN
    app.put '/medicos/:id' do
      requiere_login!
      @medico = Medico[params[:id]]
      halt 404, "Médico no encontrado" unless @medico
      
      begin
        @medico.update(
          nombre: params[:nombre],
          apellido: params[:apellido],
          especialidad_id: params[:especialidad_id],
          matricula: params[:matricula],
          email: params[:email].to_s.strip.empty? ? nil : params[:email],
          telefono: params[:telefono].to_s.strip.empty? ? nil : params[:telefono],
          horizonte_dias: params[:horizonte_dias].to_s.strip.empty? ? nil : params[:horizonte_dias].to_i,
          activo: params[:activo] == '1'
        )
        flash[:success] = 'Médico actualizado correctamente.'
        redirect '/medicos'
      rescue Sequel::ValidationFailed => e
        flash[:error] = e.message
        @especialidades = Especialidad.order(:nombre).all
        erb :'clinica/medicos/form', layout: :'layout/base'
      end
    end

    # 6. Desactivar (desde el menú de los 3 puntos)
    app.patch '/medicos/:id/desactivar' do
      requiere_login!
      begin
        MedicoService.desactivar(params[:id])
        flash[:success] = 'Médico desactivado correctamente.'
      rescue ArgumentError => e
        flash[:error] = e.message
      end
      redirect '/medicos'
    end
  end
end