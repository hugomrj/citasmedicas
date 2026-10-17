#!/usr/bin/env ruby
require_relative 'env_helper'
require_relative '../lib/db'

SCHEMA_SQL = File.expand_path('schema.sql', __dir__)

sql = File.read(SCHEMA_SQL)

DB.run "PRAGMA foreign_keys = OFF"
DB.tables.each { |t| DB.run "DROP TABLE IF EXISTS #{t}" }
DB.run "PRAGMA foreign_keys = ON"

DB.run sql

puts "✓ Estructura creada en #{CitasMedicas::DB_PATH}"
puts "✓ Tablas: #{DB.tables.sort.join(', ')}"