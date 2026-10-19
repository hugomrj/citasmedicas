#!/usr/bin/env ruby
require_relative 'env_helper'
require_relative '../services'

EMAIL    = 'admin@citasmedicas.local'
PASSWORD = 'admin123'
NOMBRE   = 'Admin'
APELLIDO = 'Sistema'

existente = Usuario.where(email: EMAIL).first
if existente
  puts "✓ El admin ya existe (id: #{existente.id}, email: #{EMAIL})"
  exit 0
end

admin = UsuarioService.crear(
  nombre:   NOMBRE,
  apellido: APELLIDO,
  username: 'admin', 
  email:    EMAIL,
  password: PASSWORD,
  rol:      'admin'
)

puts "✓ Admin creado:"
puts "  id:       #{admin.id}"
puts "  email:    #{admin.email}"
puts "  password: #{PASSWORD}  ← CAMBIAR EN PRODUCCIÓN"
puts "  rol:      #{admin.rol}"