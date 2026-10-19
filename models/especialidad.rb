class Especialidad < Sequel::Model(:especialidades)
  one_to_many :medicos

  def validate
    super
    validates_presence [:nombre]
    validates_unique :nombre
  end
end