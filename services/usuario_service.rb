module UsuarioService
  module_function

  def autenticar(email:, password:)
    usuario = Usuario.where(email: email.to_s.strip.downcase).first
    return nil unless usuario && usuario.activo
    usuario.authenticate(password) || nil
  end

  def crear(nombre:, apellido:, email:, password:, rol:)
    Usuario.create(
      nombre:                nombre.to_s.strip,
      apellido:              apellido.to_s.strip,
      email:                 email.to_s.strip.downcase,
      password:              password,
      password_confirmation: password,
      rol:                   rol
    )
  end

  def actualizar(usuario_id, attrs)
    usuario = Usuario[usuario_id]
    raise ArgumentError, 'Usuario no encontrado' unless usuario

    attrs = attrs.dup
    attrs[:email] = attrs[:email].to_s.strip.downcase if attrs[:email]

    if attrs[:password]
      raise ArgumentError, 'password_confirmation no coincide' if attrs[:password] != attrs[:password_confirmation]
    end

    usuario.update(attrs)
    usuario
  end

  def desactivar(usuario_id, protegiendo_id: nil)
    usuario = Usuario[usuario_id]
    raise ArgumentError, 'Usuario no encontrado' unless usuario
    raise ArgumentError, 'No podés desactivarte a vos mismo' if usuario.id == protegiendo_id

    if usuario.admin?
      admins_activos = Usuario.where(rol: 'admin', activo: true).exclude(id: usuario.id).count
      if admins_activos.zero?
        raise ArgumentError, 'No se puede desactivar al último administrador activo'
      end
    end

    usuario.update(activo: false)
    usuario
  end
end
