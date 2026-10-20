require 'bcrypt'

class Usuario < Sequel::Model(:usuarios)
  ROLES = %w[admin recepcion medico].freeze

  attr_accessor :password_confirmation
  attr_reader   :password

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
    # Obligatorios (sin el email)
    validates_presence [:nombre, :apellido, :username, :rol]
    validates_unique :username
    validates_includes ROLES, :rol, message: 'no es un rol válido'

    # El email es opcional, pero si viene, validamos su formato y unicidad
    if email && !email.strip.empty?
      validates_unique :email
      validates_format(/\A[^@\s]+@[^@\s]+\.[^@\s]+\z/, :email, message: 'no tiene formato válido')
    end

    # Contraseña: obligatoria solo al crear
    if new? && password_digest.nil?
      errors.add(:password, 'es obligatoria para crear el usuario')
    end

    if @password && @password != password_confirmation
      errors.add(:password_confirmation, 'no coincide')
    end
  end

  def nombre_completo
    "#{nombre} #{apellido}"
  end

  def admin?
    rol == 'admin'
  end
end