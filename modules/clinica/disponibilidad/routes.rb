module ClinicaDisponibilidadRoutes
  def self.registered(app)
    # 1. Listado de médicos (CON BUSCADOR)
    app.get '/disponibilidad' do
      requiere_login!
      @crumb_here = 'Horarios'
      
      query = params[:q].to_s.strip
      ds = Medico.where(activo: true)

      if query.empty?
        @medicos = ds.order(:apellido, :nombre).all
      else
        patron = "%#{query.downcase}%"
        ds = ds.join(:especialidades, id: :especialidad_id).select_all(:medicos)
        
        @medicos = ds.where(
          Sequel.like(Sequel.function(:lower, Sequel[:medicos][:nombre]), patron) |
          Sequel.like(Sequel.function(:lower, Sequel[:medicos][:apellido]), patron) |
          Sequel.like(Sequel.function(:lower, Sequel[:especialidades][:nombre]), patron)
        ).order(Sequel[:medicos][:apellido], Sequel[:medicos][:nombre]).all
      end

      @query_actual = query

      if request.xhr?
        erb :'clinica/disponibilidad/_tabla', layout: false
      else
        erb :'clinica/disponibilidad/index', layout: :'layout/base'
      end
    end

    # 2. Editor de horarios de un médico
    app.get '/disponibilidad/:id' do
      requiere_login!
      @medico = Medico[params[:id]]
      halt 404, "Médico no encontrado" unless @medico
      
      @crumb_here = "Horarios: #{@medico.nombre_completo}"
      
      @dias = {
        1 => 'Lunes', 2 => 'Martes', 3 => 'Miércoles', 
        4 => 'Jueves', 5 => 'Viernes', 6 => 'Sábado', 0 => 'Domingo'
      }
      
      @bloques = Disponibilidad.where(medico_id: @medico.id).all
      
      erb :'clinica/disponibilidad/editar', layout: :'layout/base'
    end

    # 3. Guardar horarios (MÚLTIPLES bloques por día con índices)
    app.post '/disponibilidad/:id' do
      requiere_login!
      @medico = Medico[params[:id]]
      halt 404, "Médico no encontrado" unless @medico

      begin
        DB.transaction do
          # Borramos los horarios viejos
          Disponibilidad.where(medico_id: @medico.id).delete
          
          # params[:horarios] es un Hash: { "1" => { "0" => {inicio: "09:00", fin: "13:00"}, "1" => {...} } }
          params[:horarios]&.each do |dia_semana, bloques|
            # bloques es el hash de índices para este día
            bloques.each do |_index, datos|
              # datos es el hash con {inicio: "...", fin: "..."}
              # Usamos datos["inicio"] por si Rack los convierte a string keys
              inicio = datos["inicio"] || datos[:inicio]
              fin = datos["fin"] || datos[:fin]

              if inicio.to_s.strip != "" && fin.to_s.strip != ""
                Disponibilidad.create(
                  medico_id: @medico.id,
                  dia_semana: dia_semana.to_i,
                  hora_inicio: inicio,
                  hora_fin: fin,
                  duracion_turno_min: 30
                )
              end
            end
          end
        end
        
        flash[:success] = 'Horarios actualizados correctamente.'
        redirect '/disponibilidad'
        
      rescue ArgumentError => e
        flash[:error] = e.message
        redirect "/disponibilidad/#{@medico.id}"
      end
    end
  end
end