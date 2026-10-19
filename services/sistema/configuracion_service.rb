module ConfiguracionService
  module_function

  def horizonte_maximo_dias
    Configuracion.horizonte_maximo_dias
  end

  def anticipacion_minima_horas
    Configuracion.anticipacion_minima_horas
  end

  def set(clave, valor)
    Configuracion.set(clave, valor)
  end

  def todas
    Configuracion.order(:clave).all
  end

  def marcar_escaneo_avisos!(instante = Time.now)
    Configuracion.marcar_escaneo_avisos!(instante)
  end
end
