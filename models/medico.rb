class Medico < Sequel::Model(:medicos)
  many_to_one :usuario
  one_to_many :disponibilidades, class: :Disponibilidad
  one_to_many :bloqueos
  one_to_many :citas

  def validate
    super
    validates_presence [:nombre, :apellido, :especialidad, :matricula]
    validates_unique :matricula
    validates_integer :horizonte_dias, allow_nil: true
    if horizonte_dias && horizonte_dias <= 0
      errors.add(:horizonte_dias, 'debe ser mayor que cero')
    end
  end

  def nombre_completo
    "#{nombre} #{apellido}"
  end

  def horizonte_efectivo
    horizonte_dias || Configuracion.horizonte_maximo_dias
  end

  def citas_futuras
    Cita.where(medico_id: id)
        .where { fecha_hora >= Time.now }
        .where(estado: %w[pendiente confirmada requiere_reprogramacion])
  end

  def tiene_citas_futuras?
    citas_futuras.count > 0
  end
end