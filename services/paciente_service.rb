module PacienteService
  module_function

  def buscar_o_crear(telefono:, nombre:, apellido:, datos_extras: {})
    telefono = telefono.to_s.strip
    raise ArgumentError, 'teléfono es obligatorio' if telefono.empty?

    DB.transaction do
      existente = Paciente.where(telefono: telefono).first
      return [existente, :existente] if existente

      paciente = Paciente.create({
        telefono:       telefono,
        nombre:         nombre.to_s.strip,
        apellido:       apellido.to_s.strip,
        canal_registro: 'presencial'
      }.merge(datos_extras))

      [paciente, :creado]
    end
  end

  def buscar(termino, incluir_archivados: false)
    termino = termino.to_s.strip
    ds = Paciente.dataset
    ds = ds.where(archivado: false) unless incluir_archivados
    return ds.order(:apellido, :nombre).all if termino.empty?

    patron = "%#{termino.downcase}%"
    ds.where(
      Sequel.ilike(:nombre,   patron) |
      Sequel.ilike(:apellido, patron) |
      Sequel.ilike(:telefono, patron) |
      Sequel.ilike(:dni,      patron)
    ).order(:apellido, :nombre).all
  end

  def activos
    Paciente.where(archivado: false).order(:apellido, :nombre).all
  end

  def archivar(paciente_id)
    paciente = Paciente[paciente_id]
    raise ArgumentError, 'Paciente no encontrado' unless paciente

    futuras = paciente.citas_futuras
    if futuras.any?
      raise ArgumentError,
            "No se puede archivar: el paciente tiene #{futuras.size} cita(s) futura(s) pendiente(s)"
    end

    paciente.update(archivado: true)
    paciente
  end

  def reactivar(paciente_id)
    paciente = Paciente[paciente_id]
    raise ArgumentError, 'Paciente no encontrado' unless paciente
    paciente.update(archivado: false)
    paciente
  end
end
