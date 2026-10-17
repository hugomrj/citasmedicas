class Bloqueo < Sequel::Model(:bloqueos)
  many_to_one :medico
  many_to_one :creado_por, class: :Usuario, key: :creado_por_usuario_id

  MOTIVOS = %w[vacaciones congreso licencia feriado personal].freeze

  def validate
    super
    validates_presence [:fecha_inicio, :fecha_fin, :motivo]
    validates_includes MOTIVOS, :motivo, message: 'no es un motivo válido'

    if fecha_inicio && fecha_fin && fecha_fin <= fecha_inicio
      errors.add(:fecha_fin, 'debe ser posterior a fecha_inicio')
    end
  end

  def activo?
    cancelado_en.nil?
  end

  def cubre?(instante)
    activo? && instante >= fecha_inicio && instante < fecha_fin
  end

  def se_solapa_con?(otro_inicio, otro_fin)
    fecha_inicio < otro_fin && fecha_fin > otro_inicio
  end

  def dias
    ((fecha_fin - fecha_inicio) / 86400.0).ceil
  end
end