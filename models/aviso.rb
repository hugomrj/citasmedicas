class Aviso < Sequel::Model(:avisos)
  many_to_one :visto_por,      class: :Usuario, key: :visto_por_usuario_id
  many_to_one :resuelto_por,   class: :Usuario, key: :resuelto_por_usuario_id
  many_to_one :descartado_por, class: :Usuario, key: :descartado_por_usuario_id

  ESTADOS = %w[pendiente visto resuelto descartado].freeze
  SEVERIDADES = %w[info warning error].freeze
  ENTIDADES = %w[cita medico bloqueo paciente sistema].freeze

  def validate
    super
    validates_presence [:tipo, :severidad, :entidad_tipo, :titulo]
    validates_includes ESTADOS, :estado, message: 'no es un estado válido'
    validates_includes SEVERIDADES, :severidad, message: 'no es una severidad válida'
    validates_includes ENTIDADES, :entidad_tipo, message: 'no es un tipo de entidad válido'

    if entidad_tipo != 'sistema' && entidad_id.nil?
      errors.add(:entidad_id, 'es requerido cuando entidad_tipo no es "sistema"')
    end
  end

  def abierto?
    %w[pendiente visto].include?(estado)
  end

  def pendiente?
    estado == 'pendiente'
  end

  def marcar_visto!(usuario_id)
    return if visto_en
    update(estado: 'visto', visto_por_usuario_id: usuario_id, visto_en: Time.now)
  end

  def resolver!(usuario_id = nil)
    update(estado: 'resuelto', resuelto_por_usuario_id: usuario_id, resuelto_en: Time.now)
  end

  def descartar!(usuario_id)
    update(estado: 'descartado', descartado_por_usuario_id: usuario_id, descartado_en: Time.now)
  end
end