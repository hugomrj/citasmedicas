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

    # 3. Guardar horarios (CON VALIDACIONES ESTRICTAS)
    app.post '/disponibilidad/:id' do
      requiere_login!
      @medico = Medico[params[:id]]
      halt 404, "Médico no encontrado" unless @medico

      @dias = {
        1 => 'Lunes', 2 => 'Martes', 3 => 'Miércoles', 
        4 => 'Jueves', 5 => 'Viernes', 6 => 'Sábado', 0 => 'Domingo'
      }

      errores = []
      bloques_por_dia = {}

      # 1. Recolectar y validar individualmente
      params[:horarios]&.each do |dia_semana, bloques|
        dia_num = dia_semana.to_i
        bloques_por_dia[dia_num] = []
        
        bloques.each do |_index, datos|
          inicio = (datos["inicio"] || datos[:inicio]).to_s.strip
          fin    = (datos["fin"] || datos[:fin]).to_s.strip

          # Si ambos están vacíos, ignoramos el bloque
          next if inicio.empty? && fin.empty?

          # Si falta uno de los dos, error
          if inicio.empty? || fin.empty?
            errores << "El día #{@dias[dia_num]} tiene un horario incompleto (falta entrada o salida)."
            next
          end

          # Normalizar formato (por si escriben 9:00 en lugar de 09:00)
          unless inicio =~ /\A\d{1,2}:\d{2}\z/ && fin =~ /\A\d{1,2}:\d{2}\z/
            errores << "El día #{@dias[dia_num]} tiene un formato de hora inválido (use HH:MM)."
            next
          end
          
          inicio = format("%02d:%02d", *inicio.split(':').map(&:to_i))
          fin = format("%02d:%02d", *fin.split(':').map(&:to_i))

          # Validar que la salida sea mayor a la entrada
          if fin <= inicio
            errores << "En el día #{@dias[dia_num]}, la hora de salida (#{fin}) debe ser mayor a la de entrada (#{inicio})."
            next
          end

          bloques_por_dia[dia_num] << { inicio: inicio, fin: fin }
        end
      end

      # 2. Validar solapamientos (por médico y por día)
      bloques_por_dia.each do |dia, bloques|
        next if bloques.length <= 1
        # Ordenamos por hora de entrada
        ordenados = bloques.sort_by { |b| b[:inicio] }
        
        ordenados.each_cons(2) do |a, b|
          if b[:inicio] < a[:fin]
            errores << "En el día #{@dias[dia]}, los horarios #{a[:inicio]}-#{a[:fin]} y #{b[:inicio]}-#{b[:fin]} se superponen."
          end
        end
      end

      # 3. Si hay errores, no guardamos nada y volvemos
      if errores.any?
        flash[:error] = errores.join(" ")
        redirect "/disponibilidad/#{@medico.id}"
      end

      # 4. Si todo está OK, guardamos
      begin
        DB.transaction do
          Disponibilidad.where(medico_id: @medico.id).delete
          
          bloques_por_dia.each do |dia_semana, bloques|
            bloques.each do |b|
              Disponibilidad.create(
                medico_id: @medico.id,
                dia_semana: dia_semana,
                hora_inicio: b[:inicio],
                hora_fin: b[:fin],
                duracion_turno_min: 30
              )
            end
          end
        end
        
        flash[:success] = 'Horarios actualizados correctamente.'
        redirect '/disponibilidad'
        
      rescue => e
        flash[:error] = "Error al guardar: #{e.message}"
        redirect "/disponibilidad/#{@medico.id}"
      end
    end
  end
end