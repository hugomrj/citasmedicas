module ClinicaEspecialidadesRoutes
  def self.registered(app)
    # 1. Listado
    app.get '/especialidades' do
      requiere_login!
      @crumb_here = 'Especialidades'
      
      query = params[:q].to_s.strip
      @pagina_actual = (params[:page] || 1).to_i
      limite = 20
      
      ds = Especialidad.dataset
      
      if query.empty?
        @especialidades_ds = ds
      else
        patron = "%#{query.downcase}%"
        @especialidades_ds = ds.where(
          Sequel.like(Sequel.function(:lower, :nombre), patron)
        )
      end

      @total_registros = @especialidades_ds.count
      @total_paginas = (@total_registros.to_f / limite).ceil
      
      @especialidades = @especialidades_ds.order(:nombre)
                                          .limit(limite)
                                          .offset((@pagina_actual - 1) * limite)
                                          .all

      @query_actual = query

      if request.xhr?
        erb :'clinica/especialidades/_tabla', layout: false
      else
        erb :'clinica/especialidades/index', layout: :'layout/base'
      end
    end

    # 2. Formulario NUEVO
    app.get '/especialidades/nuevo' do
      requiere_login!
      @crumb_here = 'Nueva Especialidad'
      @especialidad = Especialidad.new
      erb :'clinica/especialidades/form', layout: :'layout/base'
    end

    # 3. Guardar NUEVO
    app.post '/especialidades' do
      requiere_login!
      begin
        Especialidad.create(nombre: params[:nombre])
        flash[:success] = 'Especialidad creada correctamente.'
        redirect '/especialidades'
      rescue Sequel::ValidationFailed => e
        flash[:error] = 'La especialidad ya existe o el nombre está vacío.'
        @especialidad = Especialidad.new(params)
        erb :'clinica/especialidades/form', layout: :'layout/base'
      end
    end

    # 4. Formulario EDITAR
    app.get '/especialidades/:id/editar' do
      requiere_login!
      @crumb_here = 'Editar Especialidad'
      @especialidad = Especialidad[params[:id]]
      halt 404, "Especialidad no encontrada" unless @especialidad
      erb :'clinica/especialidades/form', layout: :'layout/base'
    end

    # 5. Guardar EDICIÓN
    app.put '/especialidades/:id' do
      requiere_login!
      @especialidad = Especialidad[params[:id]]
      halt 404, "Especialidad no encontrada" unless @especialidad
      
      begin
        @especialidad.update(nombre: params[:nombre])
        flash[:success] = 'Especialidad actualizada correctamente.'
        redirect '/especialidades'
      rescue Sequel::ValidationFailed => e
        flash[:error] = 'La especialidad ya existe o el nombre está vacío.'
        erb :'clinica/especialidades/form', layout: :'layout/base'
      end
    end

    # 6. Eliminar Especialidad (Usando POST para evitar el error 404)
    app.post '/especialidades/:id/eliminar' do
      requiere_login!
      @especialidad = Especialidad[params[:id]]
      halt 404, "Especialidad no encontrada" unless @especialidad

      if @especialidad.medicos.count > 0
        flash[:error] = 'No se puede eliminar: hay médicos asignados a esta especialidad.'
      else
        @especialidad.destroy
        flash[:success] = 'Especialidad eliminada correctamente.'
      end
      
      redirect '/especialidades'
    end
  end
end