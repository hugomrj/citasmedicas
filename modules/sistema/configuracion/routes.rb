module SistemaConfiguracionRoutes
  def self.registered(app)
    # 1. Mostrar Configuración
    app.get '/configuracion' do
      requiere_rol!(:admin)
      @crumb_here = 'Configuración'
      
      # Leemos los valores actuales de la base de datos
      @horizonte = Configuracion.obtener('horizonte_maximo_dias', default: '60')
      @anticipacion = Configuracion.obtener('anticipacion_minima_horas', default: '2')
      
      erb :'sistema/configuracion/index', layout: :'layout/base'
    end

    # 2. Guardar Configuración
    app.post '/configuracion' do
      requiere_rol!(:admin)
      
      begin
        horizonte = params[:horizonte].to_i
        anticipacion = params[:anticipacion].to_i
        
        raise ArgumentError, "El horizonte debe ser mayor a 0" if horizonte <= 0
        raise ArgumentError, "La anticipación no puede ser negativa" if anticipacion < 0

        Configuracion.set('horizonte_maximo_dias', horizonte)
        Configuracion.set('anticipacion_minima_horas', anticipacion)
        
        flash[:success] = 'Configuración guardada correctamente.'
        redirect '/configuracion'
      rescue ArgumentError => e
        flash[:error] = e.message
        redirect '/configuracion'
      end
    end
  end
end