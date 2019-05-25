$:.push('gen-rb')
$:.unshift '../../lib/rb/lib'

require 'thrift'
require 'socket'
hostname = 'localhost'
portUsers = 7777 # Puerto en donde el socket para el servicio de usuarios esta escuchando



class ServerHandler

    def initialize()
        sUsers = TCPSocket.open(hostname, portUsers)
    end

    def iniciarSesion(correo, pass)
        # llama al socket de usuarios
        # espera respuesta
        # regresar respuesta
    end

    def registrarUsuario()
        # llama al socket de usuarios
        # espera respuesta
        # regresar respuesta
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
#processor = Calculator::Processor.new(handler)
transport = Thrift::ServerSocket.new(9090)
transportFactory = Thrift::BufferedTransportFactory.new()
server = Thrift::SimpleServer.new(processor, transport, transportFactory)

puts "Iniciando skeleton..."
server.serve()
puts "Iniciado skeleton!"