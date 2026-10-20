module AuthUsuarioRoutes
  def self.registered(app)
    
    app.get '/login' do
      redirect '/dashboard' if autenticado?
      erb :'auth/usuario/login' # ← sin layout, página independiente
    end

    app.post '/login' do
      content_type :json
      
      usuario = UsuarioService.autenticar(
        username: params[:username],
        password: params[:password]
      )
    
      if usuario
        iniciar_sesion!(usuario)
        { ok: true, redirect: '/dashboard' }.to_json
      else
        status 401
        { ok: false, message: 'Usuario o contraseña incorrectos' }.to_json
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