require 'sequel'
require 'tiny_tds'
require 'socket'
require 'json'

server = TCPServer.open(7777)

db_connection_params = {
  :adapter => 'tinytds',
  :host => '3.217.0.253', # IP or hostname
  :port => '1433', # Required when using other that 1433 (default)
  :database => 'transito',
  :user => 'sa',
  :password => 'Dba12345'
}

DB = Sequel.connect(db_connection_params)
@tbl = DB[:Usuario]

def obtenerUsuarios()
  usersJson = Array.new
  dataset = @tbl.all
  dataset.each do |row|
    usersJson.push(row)
  end
  users.each { |u| print u.nombre, "\n" }
  json = usersJson.to_json
  puts json
  return json
end

def registrarUsuario(nombre, usuario, password)
  # consulta a bd para registrar usuario
end

begin
loop {
  Thread.start(server.accept) do |client|
  peticion = client.gets
  case peticion
  when "obtenerUsuarios"
    usuarios = obtenerUsuarios()
    client.send(usuarios)
  else
    client.send("Comando no reconocido")
  end
  client.close
end
}