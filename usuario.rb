require 'sequel'
require 'tiny_tds'
require 'socket'
require 'json'

server = TCPServer.open(77777)

db_connection_params = {
  :adapter => 'tinytds',
  :host => '3.217.0.253', # IP or hostname
  :port => '1433', # Required when using other that 1433 (default)
  :database => 'transito',
  :user => 'sa',
  :password => 'Dba12345'
}

@DB = Sequel.connect(db_connection_params)
@tbl = @DB[:Usuario]

def obtenerUsuarios()
  usersJson = Array.new
  dataset = @tbl.all
  dataset.each do |row|
    usersJson.push(row)
  end
  # print usersJson
  # usersJson.each { |u| print u.nombre, "\n" }
  json = usersJson.to_json
  print json
  return json
end

def iniciarSesion(user,pass)
  user = @tbl.where{(usuario =~ user) & (password =~ pass)}.first
  json = user.to_json
  print json
  return json
end

def registrarUsuario(nombre, usuario, password)
  # consulta a bd para registrar usuario
end


loop do
  print "Iniciado servicio de usuario..."
  Thread.start(server.accept) do |client|
    peticion = client.gets
    jsonP = JSON.parse(peticion)
    print jsonP["peticion"]
    case jsonP["peticion"]
    when "obtenerUsuarios"
      usuarios = obtenerUsuarios()
      client.send(usuarios)
    when "iniciarSesion"
      print "Peticion de inicio de sesion"
      user = iniciarSesion(jsonP["usuario"],jsonP["password"])
      client.send(user)
    when "ping"
      client.send("pong desde service users")
    else
      client.send("Comando no reconocido")
    end
    client.close
  end
end
