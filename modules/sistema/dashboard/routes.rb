module SistemaDashboardRoutes
  def self.registered(app)
    app.get '/dashboard' do
      requiere_login!
      @crumb_here = 'Dashboard'

      hoy          = Date.today
      inicio_hoy   = Time.new(hoy.year, hoy.month, hoy.day, 0, 0, 0)
      fin_hoy      = inicio_hoy + 86_400

      @citas_hoy   = Cita.where { fecha_hora >= inicio_hoy }
                         .where { fecha_hora <  fin_hoy }
                         .exclude(estado: %w[cancelada no_asistio])
                         .order(:fecha_hora)
                         .all

      @citas_proximas = Cita.where { fecha_hora >= fin_hoy }
                            .where(estado: %w[pendiente confirmada])
                            .order(:fecha_hora)
                            .limit(10)
                            .all

      @avisos_count    = avisos_pendientes_count
      @avisos          = avisos_pendientes_lista
      @pacientes_count = Paciente.where(archivado: false).count
      @medicos_count   = Medico.where(activo: true).count

      erb :'sistema/dashboard/index', layout: :'layout/base'
    end
  end
end