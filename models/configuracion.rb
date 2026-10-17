class Configuracion < Sequel::Model(:configuracion)
  # La primary key es "clave" (string), no "id"
  unrestrict_primary_key

  def self.set_dataset(ds)
    super
    @dataset = @dataset.with_primary_key(:clave) if @dataset
    @dataset
  end

  def self.obtener(clave, default: nil)
    fila = self[clave: clave.to_s]
    fila ? fila.valor : default
  end

  def self.set(clave, valor)
    clave = clave.to_s
    valor = valor.to_s
    ahora = Time.now
    if self[clave: clave]
      self.where(clave: clave).update(valor: valor, actualizado_en: ahora)
    else
      self.create(clave: clave, valor: valor, actualizado_en: ahora)
    end
  end

  # Atajos tipados
  def self.horizonte_maximo_dias
    obtener('horizonte_maximo_dias', default: '60').to_i
  end

  def self.anticipacion_minima_horas
    obtener('anticipacion_minima_horas', default: '2').to_i
  end

  def self.ultimo_escaneo_avisos
    valor = obtener('ultimo_escaneo_avisos')
    valor ? Time.parse(valor) : Time.at(0)
  rescue ArgumentError
    Time.at(0)
  end

  def self.marcar_escaneo_avisos!(instante = Time.now)
    set('ultimo_escaneo_avisos', instante.iso8601)
  end
end