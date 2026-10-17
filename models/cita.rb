class Cita < Sequel::Model(:citas)
  many_to_one :paciente
  many_to_one :medico
  many_to_one :creado_por, class: :Usuario, key: :creado_por_usuario_id
  many_to_one :cita_original, class: :Cita, key: :reprogramada_desde_id
  one_to_many  :reprogramaciones, class: :Cita, key: :reprogramada_desde_id

  ESTADOS = %w[pendiente confirmada atendida cancelada no_asistio requiere_reprogramacion].freeze
  ESTADOS_QUE_OCUPAN_SLOT = %w[pendiente confirmada].freeze
  CANALES = %w[presencial telefono chatbot telegram].freeze
  CANCELADA_POR = %w[paciente medico sistema staff].freeze

  def validate
    super
    validates_presence [:fecha_hora, :fecha_hora_fin, :duracion_min, :codigo_confirmacion]
    validates_unique :codigo_confirmacion
    validates_includes ESTADOS, :estado, message: 'no es un estado válido'
    validates_includes CANALES, :canal_origen, message: 'no es un canal válido'

    if cancelada_por && !CANCELADA_POR.include?(cancelada_por)
      errors.add(:cancelada_por, 'no es un valor válido')
    end

    if fecha_hora && fecha_hora_fin && fecha_hora_fin <= fecha_hora
      errors.add(:fecha_hora_fin, 'debe ser posterior a fecha_hora')
    end

    errors.add(:duracion_min, 'debe ser mayor que cero') if duracion_min && duracion_min <= 0
  end

  def ocupa_slot?
    ESTADOS_QUE_OCUPAN_SLOT.include?(estado)
  end

  def cancelada?
    estado == 'cancelada'
  end

  def requiere_reprogramacion?
    estado == 'requiere_reprogramacion'
  end

  def futura?
    fecha_hora > Time.now
  end

  def pasada?
    fecha_hora < Time.now
  end

  def en_curso?
    ahora = Time.now
    fecha_hora <= ahora && ahora < fecha_hora_fin
  end
end