module SistemaUsuariosRoutes
  def self.registered(app)
    # 1. Listado de Usuarios
    app.get '/usuarios' do
      requiere_rol!(:admin) # <--- SOLO ADMIN
      @crumb_here = 'Usuarios'
      
      query = params[:q].to_s.strip
      status_filter = params[:status] || 'activos'

      ds = Usuario.dataset

      case status_filter
      when 'activos' then ds = ds.where(activo: true)
      when 'inactivos' then ds = ds.where(activo: false)
      end

      if query.empty?
        @usuarios_ds = ds
      else
        patron = "%#{query.downcase}%"
        @usuarios_ds = ds.where(
          Sequel.like(Sequel.function(:lower, :nombre), patron) |
          Sequel.like(Sequel.function(:lower, :apellido), patron) |
          Sequel.like(Sequel.function(:lower, :username), patron) |
          Sequel.like(Sequel.function(:lower, :email), patron)
        )
      end

      @usuarios = @usuarios_ds.order(:apellido, :nombre).all
      @status_actual = status_filter
      @query_actual = query

      @contador_todos = Usuario.count
      @contador_activos = Usuario.where(activo: true).count
      @contador_inactivos = Usuario.where(activo: false).count

      if request.xhr?
        erb :'sistema/usuarios/_tabla', layout: false
      else
        erb :'sistema/usuarios/index', layout: :'layout/base'
      end
    end

    # 2. Formulario NUEVO Usuario
    app.get '/usuarios/nuevo' do
      requiere_rol!(:admin)
      @crumb_here = 'Nuevo Usuario'
      @usuario = Usuario.new
      erb :'sistema/usuarios/form', layout: :'layout/base'
    end



    
    # 3. Guardar NUEVO Usuario
    app.post '/usuarios' do
      requiere_rol!(:admin)
      begin
        UsuarioService.crear(
          nombre: params[:nombre],
          apellido: params[:apellido],
          username: params[:username],
          email: params[:email],
          password: params[:password],
          rol: params[:rol]
        )
        flash[:success] = 'Usuario creado correctamente.'
        redirect '/usuarios'
      rescue Sequel::ValidationFailed => e
        # Esto muestra el error exacto en el toast
        flash[:error] = "No se pudo guardar: #{e.message}"
        @usuario = Usuario.new(params)
        erb :'sistema/usuarios/form', layout: :'layout/base'
      rescue ArgumentError => e
        flash[:error] = e.message
        @usuario = Usuario.new(params)
        erb :'sistema/usuarios/form', layout: :'layout/base'
      end
    end




    # 4. Formulario EDITAR Usuario
    app.get '/usuarios/:id/editar' do
      requiere_rol!(:admin)
      @crumb_here = 'Editar Usuario'
      @usuario = Usuario[params[:id]]
      halt 404, "Usuario no encontrado" unless @usuario
      erb :'sistema/usuarios/form', layout: :'layout/base'
    end

    # 5. Guardar EDICIÓN de Usuario
    app.post '/usuarios/:id/actualizar' do
      requiere_rol!(:admin)
      @usuario = Usuario[params[:id]]
      halt 404, "Usuario no encontrado" unless @usuario
      
      begin
        UsuarioService.actualizar(@usuario.id, {
          nombre: params[:nombre],
          apellido: params[:apellido],
          username: params[:username],
          email: params[:email],
          rol: params[:rol],
          password: params[:password].to_s.strip.empty? ? nil : params[:password],
          password_confirmation: params[:password_confirmation],
          activo: params[:activo] == '1'
        })
        flash[:success] = 'Usuario actualizado correctamente.'
        redirect '/usuarios'
      rescue ArgumentError => e
        flash[:error] = e.message
        erb :'sistema/usuarios/form', layout: :'layout/base'
      rescue Sequel::ValidationFailed => e
        # CAMBIO ACÁ: Mostramos el error real
        flash[:error] = "Error de validación: #{e.message}"
        erb :'sistema/usuarios/form', layout: :'layout/base'
      end
    end

    # 6. Desactivar Usuario
    app.post '/usuarios/:id/desactivar' do
      requiere_rol!(:admin)
      begin
        UsuarioService.desactivar(params[:id], protegiendo_id: usuario_actual.id)
        flash[:success] = 'Usuario desactivado correctamente.'
      rescue ArgumentError => e
        flash[:error] = e.message
      end
      redirect '/usuarios'
    end
  end
end