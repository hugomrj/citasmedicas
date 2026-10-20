module SistemaAvisosRoutes
  def self.registered(app)
    # 1. Listado de Avisos
    app.get '/avisos' do
      requiere_login!
      @crumb_here = 'Avisos'
      
      status_filter = params[:status] || 'pendientes'
      
      case status_filter
      when 'pendientes'
        @avisos = Aviso.where(estado: %w[pendiente visto]).order(Sequel.desc(:created_at)).all
      when 'resueltos'
        @avisos = Aviso.where(estado: 'resuelto').order(Sequel.desc(:resuelto_en)).limit(50).all
      when 'descartados'
        @avisos = Aviso.where(estado: 'descartado').order(Sequel.desc(:descartado_en)).limit(50).all
      end
      
      @status_actual = status_filter
      
      # Contadores para las pestañas
      @contador_pendientes = Aviso.where(estado: %w[pendiente visto]).count
      @contador_resueltos = Aviso.where(estado: 'resuelto').count
      @contador_descartados = Aviso.where(estado: 'descartado').count

      if request.xhr?
        erb :'sistema/avisos/_tabla', layout: false
      else
        erb :'sistema/avisos/index', layout: :'layout/base'
      end
    end

    # 2. Resolver Aviso
    app.post '/avisos/:id/resolver' do
      requiere_login!
      aviso = Aviso[params[:id]]
      if aviso
        aviso.resolver!(usuario_actual.id)
        flash[:success] = 'Aviso marcado como resuelto.'
      end
      redirect '/avisos'
    end

    # 3. Descartar Aviso
    app.post '/avisos/:id/descartar' do
      requiere_login!
      aviso = Aviso[params[:id]]
      if aviso
        aviso.descartar!(usuario_actual.id)
        flash[:success] = 'Aviso descartado.'
      end
      redirect '/avisos'
    end
  end
end