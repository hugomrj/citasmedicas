class Disponibilidad < Sequel::Model(:disponibilidad)
  many_to_one :medico

  DIAS = {
    0 => 'Domingo', 1 => 'Lunes', 2 => 'Martes', 3 => 'Miércoles',
    4 => 'Jueves', 5 => 'Viernes', 6 => 'Sábado'
  }.freeze

  def validate
    super
    validates_presence [:hora_inicio, :hora_fin, :duracion_turno_min]

    # Molde semanal O override puntual — nunca ambos, nunca ninguno
    tiene_dia     = !dia_semana.nil?
    tiene_fecha   = !fecha_especifica.nil?
    unless tiene_dia ^ tiene_fecha
      errors.add(:base, 'debe ser molde semanal (dia_semana) o excepción puntual (fecha_especifica), no ambos ni ninguno')
    end

    if tiene_dia && !(0..6).cover?(dia_semana)
      errors.add(:dia_semana, 'debe estar entre 0 (domingo) y 6 (sábado)')
    end

    if hora_inicio && hora_fin
      if hora_inicio !~ /\A\d{2}:\d{2}\z/ || hora_fin !~ /\A\d{2}:\d{2}\z/
        errors.add(:base, 'las horas deben tener formato HH:MM')
      elsif hora_inicio >= hora_fin
        errors.add(:base, 'hora_inicio debe ser anterior a hora_fin')
      end
    end

    errors.add(:duracion_turno_min, 'debe ser mayor que cero') if duracion_turno_min && duracion_turno_min <= 0
  end

  def es_molde?
    !dia_semana.nil?
  end

  def es_override?
    !fecha_especifica.nil?
  end

  def dia_nombre
    es_molde? ? DIAS[dia_semana] : fecha_especifica.strftime('%A %d/%m/%Y')
  end
end