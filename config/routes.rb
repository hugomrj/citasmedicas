require_relative '../modules/auth/usuario/routes'
require_relative '../modules/sistema/dashboard/routes'

module CitasMedicas
  class App < Sinatra::Base
    register AuthUsuarioRoutes
    register SistemaDashboardRoutes

    get '/' do
      if autenticado?
        redirect '/dashboard'
      else
        redirect '/login'
      end
    end
  end
end