# Carga temprana del entorno. Debe requerirse antes que lib/db.rb.
ENV['RACK_ENV'] ||= 'development'
ENV['TZ']       ||= 'America/Mexico_City'