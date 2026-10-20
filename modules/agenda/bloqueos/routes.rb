module AgendaBloqueosRoutes
  def self.registered(app)
    # 1. Listado de Ausencias
    app.get '/bloqueos' do
      requiere_login!
      @crumb_here = 'Ausencias'
      
      # Traemos los bloqueos activos (no cancelados) ordenados por fecha
      @bloqueos = Bloqueo.where(cancelado_en: nil)
                         .order(Sequel.desc(:fecha_inicio))
                         .all
      
      erb :'agenda/bloqueos/index', layout: :'layout/base'
    end

    # 2. Formulario NUEVA Ausencia
    app.get '/bloqueos/nuevo' do
      requiere_login!
      @crumb_here = 'Nueva Ausencia'
      @medicos = Medico.where(activo: true).order(:apellido, :nombre).all
      erb :'agenda/bloqueos/form', layout: :'layout/base'
    end

    # 3. Guardar NUEVA Ausencia
    app.post '/bloqueos' do
      requiere_login!
      begin
        # Parseamos las fechas (asumimos que bloquea todo el día)
        inicio = Time.parse("#{params[:fecha_inicio]} 00:00:00")
        fin    = Time.parse("#{params[:fecha_fin]} 23:59:59")

        # Llamamos al servicio. Usamos :marcar para que las citas afectadas
        # pasen automáticamente a "requiere_reprogramacion"
        resultado = BloqueoService.crear(
          medico_id: params[:medico_id],
          fecha_inicio: inicio,
          fecha_fin: fin,
          motivo: params[:motivo],
          notas: params[:notas],
          creado_por_usuario_id: usuario_actual.id,
          estrategia: :marcar
        )

        if resultado[:citas_afectadas].any?
          flash[:success] = "Ausencia guardada. #{resultado[:citas_afectadas].size} cita(s) pasaron a 'Requiere reprogramación'."
        else
          flash[:success] = 'Ausencia guardada correctamente.'
        end
        
        redirect '/bloqueos'
        
      rescue ArgumentError => e
        flash[:error] = e.message
        @medicos = Medico.where(activo: true).order(:apellido, :nombre).all
        erb :'agenda/bloqueos/form', layout: :'layout/base'
      end
    end

    # 4. Cancelar Ausencia
    app.post '/bloqueos/:id/cancelar' do
      requiere_login!
      begin
        BloqueoService.cancelar(params[:id])
        flash[:success] = 'Ausencia cancelada correctamente. Los días vuelven a estar disponibles.'
      rescue ArgumentError => e
        flash[:error] = e.message
      end
      redirect '/bloqueos'
    end
  end
end