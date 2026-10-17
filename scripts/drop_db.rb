#!/usr/bin/env ruby
require_relative 'env_helper'

%w[citasmedicas.sqlite3 citasmedicas.sqlite3-wal citasmedicas.sqlite3-shm].each do |f|
  path = File.expand_path("../db/#{f}", __dir__)
  if File.exist?(path)
    File.delete(path)
    puts "Eliminado: #{path}"
  end
end