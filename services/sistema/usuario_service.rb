module UsuarioService
  module_function

  def autenticar(username:, password:)
    usuario = Usuario.where(username: username.to_s.strip.downcase).first
    return nil unless usuario && usuario.activo
    usuario.authenticate(password) || nil
  end

  def crear(nombre:, apellido:, username:, email:, password:, rol:)
    Usuario.create(
      nombre:                nombre.to_s.strip,
      apellido:              apellido.to_s.strip,
      username:              username.to_s.strip.downcase,
      # Si el email viene vacío, lo guardamos como nil para no chocar con el UNIQUE
      email:                 email.to_s.strip.empty? ? nil : email.to_s.strip.downcase,
      password:              password,
      password_confirmation: password,
      rol:                   rol
    )
  end

  def actualizar(usuario_id, attrs)
    usuario = Usuario[usuario_id]
    raise ArgumentError, 'Usuario no encontrado' unless usuario

    attrs = attrs.dup
    
    # Si el email viene en el hash, lo limpiamos y lo convertimos a nil si está vacío
    if attrs.key?(:email)
      attrs[:email] = attrs[:email].to_s.strip.empty? ? nil : attrs[:email].to_s.strip.downcase
    end

    # Validar la contraseña solo si se envió una nueva
    if attrs[:password]
      if attrs[:password] != attrs[:password_confirmation]
        raise ArgumentError, 'password_confirmation no coincide'
      end
    else
      # Si no se envía contraseña, borramos las llaves del hash para que no se actualicen
      attrs.delete(:password)
      attrs.delete(:password_confirmation)
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