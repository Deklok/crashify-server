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
                mensaje: exception.to_s
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
                mensaje: exception.to_s
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
                mensaje: exception.to_s
            )
        end
    end

    def obtener_reportes(_unusedmsg, _call)
        begin
            listaReportes = Array.new
            res = @@DB.call_mssql_sproc(:sp_contarReportes, {args: [[:output, 'int', 'resultado']]})
            print res, "\n"
            reportes = @@DB["EXEC sp_obtenerReportes"]
            print reportes, "\n"
            if res[:resultado] < 2
                r = ReporteResumido.new(
                    idReporte: reportes[:idreporte],
                    latitud: reportes[:latitud],
                    longitud: reportes[:longitud],
                    hora: reportes[:hora].to_s,
                    idSiniestro: reportes[:idtemp_siniestro],
                    nombreConductor: reportes[:nombre],
                    idSiniestroUnificado: reportes[:idsiniestro],
                    estado: reportes[:estado]
                )
                listaReportes.push(r)
            else
                reportes.each { |row|
                    print row, "\n"
                    r = ReporteResumido.new(
                        idReporte: row[:idreporte],
                        latitud: row[:latitud],
                        longitud: row[:longitud],
                        hora: row[:hora].to_s,
                        idSiniestro: row[:idtemp_siniestro],
                        nombreConductor: row[:nombre],
                        idSiniestroUnificado: row[:idsiniestro],
                        estado: row[:estado]
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

    def obtener_fotos_reporte(id, _call)
        begin
            countFotos = @@DB.call_mssql_sproc(:sp_contarFotosReporte, {args: [
                id.identifier,
                [:output, 'int', 'resultado']
            ]})
            fotos = @@DB["EXEC sp_obtenerFotosReporte " + id.identifier.to_s]
            print fotos,"\n"
            listaFotos = Array.new
            if countFotos[:resultado] > 2
                print "Más de 2 fotos"
                fotos.each { |row|
                    f = Foto.new(
                        foto: row[:foto]
                    )
                }
            else
                print "Menos de 2 fotos"
            end
        rescue => exception
            print exception, "\n"
        end
    end

    def obtener_detalle_reporte(id, _call)
        begin
            res = @@DB.call_mssql_sproc(:sp_obtenerDetalleReporte, {args: [
                id.identifier
            ]})
            listaVehiculos = Array.new
            countRegistrados = @@DB.call_mssql_sproc(:sp_contarVehiculosReporte, {args: [
                id.identifier,
                [:output, 'int', 'resultado']
            ]})
            countAnonimos = @@DB.call_mssql_sproc(:sp_contarVehiculosAnonimoReportes, {args: [
                id.identifier,
                [:output, 'int', 'resultado']
            ]})
            autosRegistrados = @@DB.call_mssql_sproc(:sp_obtenerVehiculosReporte, {args: [
                id.identifier
            ]})
            autosAnonimos = @@DB.call_mssql_sproc(:sp_obtenerVehiculosAnonimosReporte, {args: [
                id.identifier
            ]})

            if countRegistrados[:resultado] < 2
                print autosRegistrados,"\n"
                v = Vehiculo.new(
                    numPlacas: autosRegistrados[:numplacas],
                    modelo: autosRegistrados[:modelo],
                    marca: autosRegistrados[:marca],
                    year: autosRegistrados[:año],
                    color: autosRegistrados[:color],
                    numPoliza: autosRegistrados[:numpoliza],
                    aseguradora: autosRegistrados[:aseguradora]
                )
                listaVehiculos.push(v)
            else
               autosRegistrados.each { |row|
                print row, "\n"
                v = ReporteResumido.new(
                    numPlacas: row[:numplacas],
                    modelo: row[:modelo],
                    marca: row[:marca],
                    year: row[:año],
                    color: row[:color],
                    numPoliza: row[:numpoliza],
                    aseguradora: row[:aseguradora]
                )
                listaVehiculos.push(v)
            }
            end


            if countAnonimos[:resultado] < 2
                print autosAnonimos,"\n"
                if autosAnonimos[:numplacas]!= nil
                    v = Vehiculo.new(
                        numPlacas: autosAnonimos[:numPlacas],
                        modelo: autosAnonimos[:modelo],
                        marca: autosAnonimos[:marca],
                        year: autosAnonimos[:año],
                        color: autosAnonimos[:color],
                        numPoliza: autosAnonimos[:numPoliza],
                        aseguradora: autosAnonimos[:aseguradora]
                    )
                    listaVehiculos.push(v)
                end
            else
                if countAnonimos > 0
                    autosAnonimos.each { |row|
                        print row, "\n"
                        v = ReporteResumido.new(
                            numPlacas: row[:numPlacas],
                            modelo: row[:modelo],
                            marca: row[:field3],
                            year: row[:año],
                            color: row[:color],
                            numPoliza: row[:numPoliza],
                            aseguradora: row[:field7]
                        )
                        listaVehiculos.push(v)
                    }
                end
            end

            Reporte.new(
                idReporte: res[:idreporte],
                latitud: res[:latitud],
                longitud: res[:longitud],
                hora: res[:hora].to_s,
                vehiculos: listaVehiculos,
                idSiniestro: res[:idtemp_siniestro],
                estado: res[:estado]
            )
        rescue => exception
            print exception, "\n"
            print exception.backtrace.join("\n")
        end
    end

    def unificar_reportes(listaIDs, _call)
        begin
            ids = listaIDs.listaID
            idReporte = ids.first
            print idReporte, "\n"
            res = @@DB.call_mssql_sproc(:sp_siniestroUnificado, {args: [
                idReporte,
                [:output, 'int', 'resultado']
            ]})
            errorActualizacion = false
            idSiniestroUnificado = res[:resultado]
            ids.each { |id|
                res = @@DB.call_mssql_sproc(:sp_asignarSiniestroUnificado, {args: [
                    idSiniestroUnificado,
                    id,
                    [:output, 'int', 'resultado']
                ]})
                if res[:resultado] == -1
                    errorActualizacion = true
                end
            }
            if !errorActualizacion
                Respuesta.new(
                    code: 1,
                    mensaje: "Reportes unificados correctamente"
                )
            else
                Respuesta.new(
                    code: -1,
                    mensaje: "Error al unificar reportes"
                )
            end
        rescue => exception
            #print exception.backtrace.join("\n")
            print exception, "\n"
            Respuesta.new(
                code: 99,
                mensaje: exception.to_s
            )
        end
    end

    def dictaminar_reporte(dictamen, _call)
        begin
            res = @@DB.call_mssql_sproc(:sp_dictaminarReporte, {args: [
                dictamen.dictamen,
                dictamen.idSiniestro,
                dictamen.idUsuario,
                dictamen.idReporte,
                [:output, 'int', 'resultado']
            ]})
            if res[:resultado] != -1
                Respuesta.new(
                    code: 1,
                    mensaje: "Reporte dictaminado correctamente"
                )
            else
                Respuesta.new(
                    code: res[:resultado],
                    mensaje: "Error al dictaminar el reporte"
                )
            end
        rescue => exception
            print exception, "\n"
            Respuesta.new(
                code: 99,
                mensaje: exception.to_s
            )
        end
    end
end

def main
    server = GRPC::RpcServer.new
    server.add_http2_port('127.0.0.1:14586', :this_port_is_insecure)
    GRPC.logger.info("Corriendo skeleton en puerto inseguro");
    server.handle(ServerHandler)
    print "Iniciando servidor...", "\n"
    server.run
end

main
