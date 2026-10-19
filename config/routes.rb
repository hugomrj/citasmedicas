require_relative '../modules/auth/usuario/routes'
require_relative '../modules/sistema/dashboard/routes'
require_relative '../modules/clinica/pacientes/routes' 

module CitasMedicas
  class App < Sinatra::Base
    register AuthUsuarioRoutes
    register SistemaDashboardRoutes
    register ClinicaPacientesRoutes

    get '/' do
      if autenticado?
        redirect '/dashboard'
      else
        redirect '/login'
      end
    end
  end
end