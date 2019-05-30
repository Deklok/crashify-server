this_dir = File.expand_path(File.dirname(__FILE__))
lib_dir = File.join(this_dir, 'lib')
$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)

require 'sequel'
require 'tiny_tds'
require 'grpc'
require 'socket'
require 'crashify_services_pb'
require 'json'
include Crashify

class ServerHandler < Transito::Service
    attr_accessor :DB, :tbl

    def initialize()
        #@sUsers = TCPSocket.open('localhost', 77777)
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

    def ping(msg, _unusedcall)
        Mensaje.new(msg: "pong desde server")
    end

    def iniciar_sesion(sesion, _call)
        user = @@tbl.where{(usuario =~ sesion.usuario) & (password =~ sesion.password)}.first
        #print user[:nombre], "\n"
        Usuario.new(
            idUsuario: user[:idUsuario],
            nombre: user[:nombre],
            rol: user[:rol],
            usuario: user[:usuario],
            password: user[:password]
        )
    end

    def registrarUsuario()
        # llama al socket de usuarios
        # espera respuesta
        # regresar respuesta
    end

    def obtenerUsuarios()        
        # llamar al socket de usuarios
        #sUsers.send(msg)
        # espera respuesta
        #respuesta = sUsers.read
        # regresar respuesta
        #return users
    end

    def visualizarReportes()
        # llama al socket de reportes
        # espera respuesta
        # regresar respuesta
    end

    def verReporte(idReporte, _call)
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

def main
    server = GRPC::RpcServer.new
    server.add_http2_port('localhost:14586', :this_port_is_insecure)
    GRPC.logger.info("Corriendo skeleton en puerto inseguro");
    server.handle(ServerHandler)
    print "Iniciando servidor..."
    server.run
end

main
