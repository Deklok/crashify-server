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
        @db_connection_params = {
            :adapter => 'tinytds',
            :host => '3.217.0.253', # IP or hostname
            :port => '1433', # Required when using other that 1433 (default)
            :database => 'transito',
            :user => 'sa',
            :password => 'Dba12345'
        }
        @@DB = Sequel.connect(@db_connection_params)
        @@tblUsuario = @@DB[:Usuario]
    end

    def ping(msg, _unusedcall)
        begin
            resultado = 0;
            res = @@DB.call_mssql_sproc(:sp_Prueba, {args: ["wea", [:output, 'int', 'resultado']]})
            print res, "\n"
            Mensaje.new(msg: "pong desde server + respuesta: " + res[:resultado].to_s) 
        rescue => exception
            print exception, "\n"
        end
    end

    def iniciar_sesion(sesion, _call)
        user = @@tblUsuario.where{(usuario =~ sesion.usuario) & (password =~ sesion.password)}.first
        Usuario.new(
            idUsuario: user[:idusuario],
            nombre: user[:nombre],
            rol: user[:rol],
            usuario: user[:usuario],
            password: user[:password],
            idSuperior: user[:idsuperior],
        )
    end

    def registrar_usuario(usuario, _call)
        begin
            res = @@DB.call_mssql_sproc(:sp_registrarUsuario, {args: [
                usuario.nombre,
                usuario.rol,
                usuario.usuario,
                usuario.password,
                usuario.idSuperior,
                [:output, 'int', 'resultado']
            ]}) 
            if res[:resultado] != -1
                Respuesta.new(
                    code: 1,
                    mensaje: "Usuario registrado correctamente"
                )
            else
                Respuesta.new(
                    code: res[:resultado],
                    mensaje: "Usuario ya existe en la BD"
                )
            end
        rescue => exception
            print exception, "\n"
            Respuesta.new(
                code: 99,
                mensaje: exception
            )
        end
    end

    def obtener_usuarios(id, _call)        
        begin
            listaUsusarios = Array.new
            users = @@tblUsuario.where{(idSuperior =~ id.identifier)}
            users.each{ |row| 
                u = Usuario.new(
                    idUsuario: row[:idusuario],
                    nombre: row[:nombre],
                    rol: row[:rol],
                    usuario: row[:usuario],
                    password: row[:password],
                    idSuperior: row[:idsuperior]
                )
                listaUsusarios.push(u)
            } 
            puts listaUsusarios, "\n"
            ListaUsuarios.new(usuarios: listaUsusarios) 
        rescue => exception
            print exception
        end
    end

    def actualizar_usuario(usuario, _call)
        begin
            res = @@DB.call_mssql_sproc(:sp_actualizarUsuario, {args: [
                usuario.idUsuario,
                usuario.nombre,
                usuario.rol,
                usuario.usuario,
                usuario.password,
                usuario.idSuperior,
                [:output, 'int', 'resultado']
            ]}) 
            if res[:resultado] != -1
                Respuesta.new(
                    code: 1,
                    mensaje: "Usuario actualizado correctamente"
                )
            else
                Respuesta.new(
                    code: res[:resultado],
                    mensaje: "Nombre de usuario existente en la BD con el ID proporcionado"
                )
            end
        rescue => exception
            print exception, "\n"
            Respuesta.new(
                code: 99,
                mensaje: exception
            )
        end
    end

    def eliminar_usuario(id, _call)
        begin
            res = @@DB.call_mssql_sproc(:sp_eliminarUsuario, {args: [
                id.identifier,
                [:output, 'int', 'resultado']
            ]})
            if res[:resultado] != -1
                Respuesta.new(
                    code: 1,
                    mensaje: "Usuario eliminado correctamente"
                )
            else
                Respuesta.new(
                    code: res[:resultado],
                    mensaje: "El usuario tiene dependencias en la BD"
                )
            end
        rescue => exception
            print exception, "\n"
            Respuesta.new(
                code: 99,
                mensaje: exception
            )
        end
    end

    def obtener_reportes(_unusedmsg, _call)
        begin
            listaReportes = Array.new
            res = @@DB.call_mssql_sproc(:sp_contarReportes, {args: [[:output, 'int', 'resultado']]})
            reportes = @@DB.call_mssql_sproc(:sp_obtenerReportes)
            if res[:resultado] < 2
                r = ReporteResumido.new(
                    idReporte: reportes[:idreporte],
                    latitud: reportes[:latitud],
                    longitud: reportes[:longitud],
                    hora: reportes[:hora].to_s,
                    idSiniestro: reportes[:idtemp_siniestro]
                )
                listaReportes.push(r)
            else
                reportes.each { |row|
                    print row, "\n"
                    r = ReporteResumido.new(
                        idReporte: row[:idreporte],
                        latitud: row[:latitud],
                        longitud: row[:longitud],
                        hora: row[:hora],
                        idSiniestro: row[:idtemp_siniestro]
                    )
                    listaReportes.push(r)
                }
            end
            ListaReportes.new(reportes: listaReportes)
        rescue => exception
            print exception, "\n"
            #print exception.backtrace.join("\n")
        end
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
    print "Iniciando servidor...", "\n"
    server.run
end

main
