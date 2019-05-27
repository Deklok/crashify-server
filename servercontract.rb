require 'thrift'
$:.push('gen-rb')
require 'sequel'
require 'tiny_tds'
require 'transito'
require 'socket'

class ServerHandler
    attr_accessor :DB, :tbl

    def initialize()
        #sUsers = TCPSocket.open('localhost', 77777)
        @db_connection_params = {
            :adapter => 'tinytds',
            :host => '3.217.0.253', # IP or hostname
            :port => '1433', # Required when using other that 1433 (default)
            :database => 'transito',
            :user => 'sa',
            :password => 'Dba12345'
        }
        @@DB = Sequel.connect(@db_connection_params)
        @@tbl = @@DB[:Usuario]
    end

    def ping()
        return "pong server"
    end

    def iniciarSesion(user, pwd)
        userF = Usuario.new()
        user = @@tbl.where{(usuario =~ user) & (password =~ pwd)}.first
        print user[:nombre]
        userF.idUsuario =  user[:idUsuario]
        userF.nombre = user[:nombre]
        userF.rol = user[:rol]
        userF.usuario = user[:usuario]
        userF.password = user[:password]
        print userF.nombre
        return userF
    end

    def registrarUsuario()
        # llama al socket de usuarios
        # espera respuesta
        # regresar respuesta
    end

    def obtenerUsuarios()
        msg = { "peticion" => "obtenerUsuarios" }
        msg = msg.to_json
        # llamar al socket de usuarios
        sUsers.send(msg)
        # espera respuesta
        respuesta = sUsers.read
        # regresar respuesta
        hash = JSON.parse(respuesta)
        print hash.class
        hash.each { |u| 
            users.push(
            Usuario.new(
                u["idUsuario"],
                u["nombre"],
                u["rol"],
                u["usuario"],
                u["password"])
            )
        }
        users.each { |u| print u.nombre, "\n" }
        return users
    end

    def visualizarReportes()
        # llama al socket de reportes
        # espera respuesta
        # regresar respuesta
    end

    def verReporte(idReporte)
        # llama al socker de reportes
        # espera respuesta
        # regresar respuesta
    end

    def dictaminarReporte()
        # llama al socker de reportes
        # espera respuesta
        # regresar respuesta
    end

end

handler = ServerHandler.new()
processor = Transito::Processor.new(handler)
transport = Thrift::ServerSocket.new(9090)
transportFactory = Thrift::BufferedTransportFactory.new()
server = Thrift::ThreadedServer.new(processor, transport, transportFactory)

puts "Iniciando skeleton..."
server.serve()
puts "Iniciado skeleton!"