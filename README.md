# CitasMédicas

Sistema de gestión de citas médicas construido con Ruby, Sinatra y SQLite (usando Sequel como ORM).

## Requisitos previos

Antes de empezar, asegurate de tener instalado:
- Ruby (versión 3.2 o superior)
- Bundler (`gem install bundler`)
- SQLite3 (`sudo apt install sqlite3 libsqlite3-dev` en Ubuntu/Debian)

## Instalación y Configuración Inicial

1. **Instalar las dependencias del proyecto:**
   ```bash
   bundle install
```

Crear la estructura de la base de datos (tablas y configuración inicial):

```bash
ruby scripts/crear_estructura.rb
```

Esto generará el archivo db/citasmedicas.sqlite3 y las 8 tablas necesarias.

Crear el usuario administrador inicial:

```bash
ruby scripts/crear_admin.rb
```

Cargar datos de prueba (opcional pero recomendado para desarrollo):

```bash
ruby scripts/cargar_demo.rb
```

Esto crea médicos de prueba, pacientes, disponibilidad horaria y algunas citas.

Cómo levantar el servidor
Para iniciar la aplicación en modo desarrollo:

```bash
bundle exec puma -p 4567
```