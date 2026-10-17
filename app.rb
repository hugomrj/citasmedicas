require 'sinatra/base'
require 'sinatra/json'
require 'json'

require_relative 'services'
require_relative 'helpers/auth_helpers'
require_relative 'helpers/flash_helpers'
require_relative 'helpers/avisos_helper'
require_relative 'config/routes'

module CitasMedicas
  class App < Sinatra::Base
    
    set :root, __dir__
    set :views, File.join(root, 'views')
    set :public_folder, File.join(root, 'public')

    set :sessions, true
    set :session_secret, ENV.fetch(
      'SESSION_SECRET',
      'citasmedicas-dev-secret-cambiar-en-produccion-0123456789abcdef0123456789abcdef'
    )

    helpers AuthHelpers
    helpers FlashHelpers
    helpers AvisosHelper

    configure :development do
      set :show_exceptions, false
      set :raise_errors,    false
    end

    before do
      if session[:usuario_id]
        begin
          AvisoService.escanear_throttled(min_intervalo: 300)
        rescue => e
          warn "[avisos/escanear] #{e.message}"
        end
      end
    end

    not_found do
      erb :'sistema/404', layout: :'layout/base'
    end

    error do
      e = env['sinatra.error']
      warn "[error] #{e.class}: #{e.message}"
      warn e.backtrace.first(10).join("\n")
      @error = e
      erb :'sistema/500', layout: :'layout/base'
    end
  end
end