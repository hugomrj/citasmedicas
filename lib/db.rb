require_relative '../scripts/env_helper'
require 'sequel'
require 'fileutils'

module CitasMedicas
  ROOT    = File.expand_path('..', __dir__)
  DB_PATH = File.join(ROOT, 'db', 'citasmedicas.sqlite3')
end

FileUtils.mkdir_p(File.dirname(CitasMedicas::DB_PATH))

# Timestamps naive en hora local de México (sin conversión a UTC)
Sequel.default_timezone = :local

DB = Sequel.connect(
  "sqlite://#{CitasMedicas::DB_PATH}",
  max_connections: 5,
  timeout: 5000
)

# Pragmas críticos para SQLite
DB.run "PRAGMA journal_mode = WAL"
DB.run "PRAGMA foreign_keys = ON"
DB.run "PRAGMA busy_timeout = 5000"

# Plugins globales para todos los modelos
Sequel::Model.plugin :timestamps, update_on_create: true
Sequel::Model.plugin :validation_helpers