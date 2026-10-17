class Paciente < Sequel::Model(:pacientes)
  one_to_many :citas

  CANALES = %w[presencial telefono chatbot telegram].freeze

  def validate
    super
    validates_presence [:nombre, :apellido, :telefono]
    validates_unique :telefono
    validates_unique :dni, allow_nil: true
    validates_includes CANALES, :canal_registro, message: 'no es un canal válido'
  end

  def nombre_completo
    "#{nombre} #{apellido}"
  end

  def citas_futuras
    Cita.where(paciente_id: id)
        .where { fecha_hora >= Time.now }
        .where(estado: %w[pendiente confirmada])
        .order(:fecha_hora)
        .all
  end

  def citas_pasadas
    Cita.where(paciente_id: id)
        .where { fecha_hora < Time.now }
        .order(Sequel.desc(:fecha_hora))
        .all
  end

  def historial
    Cita.where(paciente_id: id).order(Sequel.desc(:fecha_hora)).all
  end

  def activo?
    !archivado
  end
end