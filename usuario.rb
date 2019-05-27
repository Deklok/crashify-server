require 'sequel'
require 'tiny_tds'
require 'socket'
require 'json'

server = TCPServer.open(77777)

class Usuario
  attr_accessor :idUsuario, :nombre, :rol, :usuario, :password

  def initialize(id,nombre,rol,usuario,password)
      @idUsuario = usuario
      @nombre = nombre
      @rol = rol
      @usuario = usuario
      @password = password
  end

end

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
  print user[:nombre]
end

def registrarUsuario(nombre, usuario, password)
  # consulta a bd para registrar usuario
end

iniciarSesion("deklok","123456")

=begin
loop do
  Thread.start(server.accept) do |client|
    peticion = client.gets
    jsonP = JSON.parse(peticion)
    case jsonP["peticion"]
    when "obtenerUsuarios"
      usuarios = obtenerUsuarios()
      client.send(usuarios)
    when "iniciarSesion"
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

=end