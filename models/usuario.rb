require 'bcrypt'

class Usuario < Sequel::Model(:usuarios)
  ROLES = %w[admin recepcion medico].freeze

  attr_accessor :password_confirmation
  attr_reader   :password

  one_to_many :avisos_vistos,      class: :Aviso, key: :visto_por_usuario_id
  one_to_many :avisos_resueltos,   class: :Aviso, key: :resuelto_por_usuario_id
  one_to_many :avisos_descartados, class: :Aviso, key: :descartado_por_usuario_id

  def password=(value)
    @password = value
    self.password_digest = BCrypt::Password.create(value) if value && !value.to_s.empty?
  end

  def authenticate(password)
    return false unless password_digest
    BCrypt::Password.new(password_digest) == password.to_s ? self : false
  rescue BCrypt::Errors::InvalidHash
    false
  end

  def validate
    super
    validates_presence [:nombre, :apellido, :email, :rol]
    validates_unique :username
    validates_unique :email
    validates_includes ROLES, :rol, message: 'no es un rol válido'
    validates_format(/\A[^@\s]+@[^@\s]+\.[^@\s]+\z/, :email, message: 'no tiene formato válido')

    if @password && @password != password_confirmation
      errors.add(:password_confirmation, 'no coincide con password')
    end

    if new? && password_digest.nil?
      errors.add(:password, 'es obligatorio al crear el usuario')
    end
  end

  def nombre_completo
    "#{nombre} #{apellido}"
  end

  def admin?
    rol == 'admin'
  end

  def recepcion?
    rol == 'recepcion'
  end

  def medico?
    rol == 'medico'
  end
end
