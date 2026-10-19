module FormatHelpers
  # Para facturas, precios, montos exactos
  def numero_con_puntos(numero)
    numero.to_s.reverse.gsub(/(\d{3})(?=\d)/, '\\1.').reverse
  end

  # Para contadores visuales (K y M)
  def numero_abreviado(numero)
    numero = numero.to_i
    if numero >= 1_000_000
      "#{(numero / 1_000_000.0).round(1)}M".gsub('.0M', 'M')
    elsif numero >= 1_000
      "#{(numero / 1_000.0).round(1)}K".gsub('.0K', 'K')
    else
      numero.to_s
    end
  end

  # Genera las opciones de hora (de 07:00 a 22:00) para los selectores
  def opciones_de_hora(hora_seleccionada = nil)
    opciones = []
    (7..22).each do |h|
      [0, 30].each do |m|
        hora_str = format('%02d:%02d', h, m)
        selected = (hora_seleccionada == hora_str) ? 'selected' : ''
        opciones << "<option value=\"#{hora_str}\" #{selected}>#{hora_str}</option>"
      end
    end
    opciones.join
  end
end