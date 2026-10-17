module AuthUsuarioRoutes
  def self.registered(app)
    app.get '/login' do
      redirect '/dashboard' if autenticado?
      erb :'auth/usuario/login'          # ← sin layout
    end

    app.post '/login' do
      usuario = UsuarioService.autenticar(
        email:    params[:email],
        password: params[:password]
      )

      if usuario
        iniciar_sesion!(usuario)
        flash[:success] = "Bienvenido, #{usuario.nombre_completo}"
        redirect '/dashboard'
      else
        flash[:error] = 'Email o contraseña incorrectos'
        redirect '/login'
      end
    end

    app.get '/logout' do
      cerrar_sesion!
      flash[:success] = 'Sesión cerrada'
      redirect '/login'
    end

    app.get '/perfil' do
      requiere_login!
      @crumb_here = 'Mi perfil'
      erb :'auth/usuario/perfil', layout: :'layout/base'
    end
  end
end