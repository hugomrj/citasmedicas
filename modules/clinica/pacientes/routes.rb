module ClinicaPacientesRoutes
  def self.registered(app)
    # 1. Listado con filtros
    app.get '/pacientes' do
      requiere_login!
      @crumb_here = 'Pacientes'
      
      query = params[:q].to_s.strip
      status_filter = params[:status] || 'activos'
      order_filter = params[:order] || 'default'
      
      ds = Paciente.dataset
      
      # Filtro por pestaña
      case status_filter
      when 'activos' then ds = ds.where(archivado: false)
      when 'inactivos' then ds = ds.where(archivado: true)
      end

      # Filtro por texto
      if query.empty?
        @pacientes = ds
      else
        patron = "%#{query.downcase}%"
        @pacientes = ds.where(
          Sequel.like(Sequel.function(:lower, :nombre), patron) |
          Sequel.like(Sequel.function(:lower, :apellido), patron) |
          Sequel.like(Sequel.function(:lower, :telefono), patron) |
          Sequel.like(Sequel.function(:lower, :cedula), patron)
        )
      end

      # Aplicar orden
      case order_filter
      when 'name'
        @pacientes = @pacientes.order(:apellido, :nombre).all
      when 'recent'
        @pacientes = @pacientes.order(Sequel.desc(:created_at)).all
      else
        @pacientes = @pacientes.order(:apellido, :nombre).all # Default
      end

      @status_actual = status_filter
      @query_actual = query
      
      # Contadores para las pestañas (se calculan sobre TODA la tabla, sin importar el filtro actual)
      @contador_todos = Paciente.count
      @contador_activos = Paciente.where(archivado: false).count
      @contador_inactivos = Paciente.where(archivado: true).count

      if request.xhr?
        erb :'clinica/pacientes/_tabla', layout: false
      else
        erb :'clinica/pacientes/index', layout: :'layout/base'
      end
    end

    # 2. Formulario NUEVO
    app.get '/pacientes/nuevo' do
      requiere_login!
      @crumb_here = 'Nuevo Paciente'
      @paciente = Paciente.new
      erb :'clinica/pacientes/form', layout: :'layout/base'
    end

    # 3. Guardar NUEVO
    app.post '/pacientes' do
      requiere_login!
      begin
        PacienteService.buscar_o_crear(
          telefono: params[:telefono], nombre: params[:nombre], apellido: params[:apellido],
          datos_extras: {
            cedula: params[:cedula].to_s.strip.empty? ? nil : params[:cedula],
            email: params[:email].to_s.strip.empty? ? nil : params[:email],
            archivado: false # Un paciente nuevo siempre nace activo
          }
        )
        flash[:success] = 'Paciente creado correctamente.'
        redirect '/pacientes'
      rescue ArgumentError => e
        flash[:error] = e.message
        @paciente = Paciente.new(params)
        erb :'clinica/pacientes/form', layout: :'layout/base'
      end
    end

    # 4. Formulario EDITAR / VER
    app.get '/pacientes/:id/editar' do
      requiere_login!
      @crumb_here = 'Editar Paciente'
      @paciente = Paciente[params[:id]]
      halt 404, "Paciente no encontrado" unless @paciente
      erb :'clinica/pacientes/form', layout: :'layout/base'
    end

    # 5. Guardar EDICIÓN
    app.put '/pacientes/:id' do
      requiere_login!
      @paciente = Paciente[params[:id]]
      halt 404, "Paciente no encontrado" unless @paciente
      
      begin
        @paciente.update(
          nombre: params[:nombre], apellido: params[:apellido], telefono: params[:telefono],
          cedula: params[:cedula].to_s.strip.empty? ? nil : params[:cedula], 
          email: params[:email].to_s.strip.empty? ? nil : params[:email],
          archivado: params[:activo] != '1' # Si el switch está apagado, se archiva
        )
        flash[:success] = 'Paciente actualizado correctamente.'
        redirect '/pacientes'
      rescue Sequel::ValidationFailed => e
        flash[:error] = e.message
        erb :'clinica/pacientes/form', layout: :'layout/base'
      end
    end

    # 6. Archivar paciente (desde el menú de los 3 puntos)
    app.patch '/pacientes/:id/archivar' do
      requiere_login!
      begin
        PacienteService.archivar(params[:id])
        flash[:success] = 'Paciente archivado correctamente.'
      rescue ArgumentError => e
        flash[:error] = e.message
      end
      redirect '/pacientes'
    end
  end
end