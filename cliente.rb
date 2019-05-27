this_dir = File.expand_path(File.dirname(__FILE__))
lib_dir = File.join(this_dir, 'lib')
$LOAD_PATH.unshift(lib_dir) unless $LOAD_PATH.include?(lib_dir)

require 'grpc'
require 'freeway_services_pb'
include Freeway

def main
    stub = Transito::Stub.new('localhost:9090', :this_channel_is_insecure)
    response = stub.ping(Mensaje.new(msg: "something"))
    print response.msg, "\n"
    response = stub.iniciar_sesion(Sesion.new(usuario: "deklok",password: "123456"))
    print response.nombre, "\n"
end

main