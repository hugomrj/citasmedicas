module AuthHelpers
  def usuario_actual
    return @usuario_actual if defined?(@usuario_actual)
    @usuario_actual = session[:usuario_id] ? Usuario[session[:usuario_id]] : nil
  end

  def autenticado?
    !usuario_actual.nil? && usuario_actual.activo
  end

  def requiere_login!
    return if autenticado?
    flash[:error] = 'Tenés que iniciar sesión'
    redirect '/login'
  end

  def requiere_rol!(*roles)
    requiere_login!
    roles = roles.map(&:to_s)
    return if roles.include?(usuario_actual.rol)
    flash[:error] = 'No tenés permiso para esa acción'
    redirect '/'
  end

  def iniciar_sesion!(usuario)
    session[:usuario_id] = usuario.id
    @usuario_actual = usuario
  end

  def cerrar_sesion!
    session.clear
    @usuario_actual = nil
  end
end