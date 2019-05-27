require 'thrift'
$:.push('gen-rb')
require 'transito'

transport = Thrift::BufferedTransport.new(Thrift::Socket.new('localhost', 9090))
protocol = Thrift::BinaryProtocol.new(transport)
client = Transito::Client.new(protocol)

transport.open()

response = client.ping()
print response
response = client.iniciarSesion("deklok","123456")
#print response["nombre"]
#print response
#response.each { |u| print u.nombre, "\n" }