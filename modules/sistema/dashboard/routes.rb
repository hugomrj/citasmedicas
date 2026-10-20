module SistemaDashboardRoutes
  def self.registered(app)
    app.get '/dashboard' do
      requiere_login!
      @crumb_here = 'Dashboard'

      hoy          = Date.today
      inicio_hoy   = Time.new(hoy.year, hoy.month, hoy.day, 0, 0, 0)
      fin_hoy      = inicio_hoy + 86_400

      @pacientes_count = Paciente.where(archivado: false).count
      @medicos_count   = Medico.where(activo: true).count
      @avisos_count    = Aviso.where(estado: %w[pendiente visto]).count
      
      @citas_hoy = Cita.where { fecha_hora >= inicio_hoy }
                       .where { fecha_hora < fin_hoy }
                       .order(:fecha_hora)
                       .all
      
      @citas_hoy_total = @citas_hoy.count
      @citas_hoy_pendientes = @citas_hoy.count { |c| %w[pendiente confirmada].include?(c.estado) }
      
      ahora = Time.now
      @proximas_citas = @citas_hoy.select { |c| c.fecha_hora >= ahora && %w[pendiente confirmada].include?(c.estado) }.first(5)
      @avisos_recientes = Aviso.where(estado: %w[pendiente visto]).order(Sequel.desc(:created_at)).limit(3).all




      # Datos para el gráfico (Últimos 7 días)
      @chart_labels = []
      @chart_data = []
      dias_semana = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb']
      
      6.downto(0) do |i|
        dia = hoy - i
        inicio_dia = Time.new(dia.year, dia.month, dia.day, 0, 0, 0)
        fin_dia = inicio_dia + 86_400
        
        # Formateamos como "Lun 20", "Mar 21", etc. usando nuestro array en español
        @chart_labels << "#{dias_semana[dia.wday]} #{dia.strftime('%d')}"
        @chart_data << Cita.where { fecha_hora >= inicio_dia }.where { fecha_hora < fin_dia }.count
      end

      erb :'sistema/dashboard/index', layout: :'layout/base'
    end
  end
end