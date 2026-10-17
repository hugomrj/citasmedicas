module MedicoService
  module_function

  def activos
    Medico.where(activo: true).order(:apellido, :nombre).all
  end

  def todos
    Medico.order(:apellido, :nombre).all
  end

  def por_especialidad(especialidad)
    Medico.where(activo: true, especialidad: especialidad).order(:apellido, :nombre).all
  end

  def especialidades
    Medico.where(activo: true).distinct.select_map(:especialidad).sort
  end

  def desactivar(medico_id)
    medico = Medico[medico_id]
    raise ArgumentError, 'Médico no encontrado' unless medico

    pendientes = medico.citas_futuras.count
    if pendientes > 0
      raise ArgumentError,
            "No se puede desactivar: tiene #{pendientes} cita(s) futura(s) pendiente(s)"
    end

    medico.update(activo: false)
    medico
  end

  def reactivar(medico_id)
    medico = Medico[medico_id]
    raise ArgumentError, 'Médico no encontrado' unless medico
    medico.update(activo: true)
    medico
  end
end
