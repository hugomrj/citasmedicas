namespace :db do
    desc "Reinicia la base de datos completa (drop, crear tablas, admin y demo)"
    task :reset do
      puts "⏳ 1. Borrando base de datos..."
      sh "ruby scripts/drop_db.rb"
      
      puts "\n⏳ 2. Creando estructura..."
      sh "ruby scripts/crear_estructura.rb"
      
      puts "\n⏳ 3. Creando usuario admin..."
      sh "ruby scripts/crear_admin.rb"
      
      puts "\n⏳ 4. Cargando datos de prueba..."
      sh "ruby scripts/cargar_demo.rb"
      
      puts "\n✅ ¡Base de datos lista para usar!"
    end
  end

  # rake db:reset