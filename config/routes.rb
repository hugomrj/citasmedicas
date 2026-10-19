require_relative '../modules/auth/usuario/routes'
require_relative '../modules/sistema/dashboard/routes'
require_relative '../modules/clinica/pacientes/routes' 
require_relative '../modules/clinica/medicos/routes'
require_relative '../modules/clinica/disponibilidad/routes'
require_relative '../modules/clinica/especialidades/routes'
require_relative '../modules/agenda/citas/routes'


module CitasMedicas
  class App < Sinatra::Base
    register AuthUsuarioRoutes
    register SistemaDashboardRoutes
    register ClinicaPacientesRoutes
    register ClinicaMedicosRoutes
    register ClinicaDisponibilidadRoutes
    register ClinicaEspecialidadesRoutes
    register AgendaCitasRoutes

    get '/' do
      if autenticado?
        redirect '/dashboard'
      else
        redirect '/login'
      end
    end
  end
end