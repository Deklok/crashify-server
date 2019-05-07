struct Dictamen {
    1: required i32 idDictamen;
    2: required string comentario;
    3: required string fecha;
    4: required string hora;
    5: required string ladoCulpable;
}

struct Respuesta {
    1: required i32 respuestaCode;
    2: required string mensaje;
}

struct Reporte {
    1: required i32 idReporte;
    2: required string latitud;
    3: required string longitud;
    4: required string estauts;
    5: required string ladoCulpable;
    6: required list<Vehiculo> implicados;
}

struct Usuario {
    1: required i32 idUsuario;
    2: required string nombre;
    3: required i32 rol;
    4: required string usuario;
    5: required string password;
}

struct Vehiculo {
    1: required i32 idVehiculo;
    2: required string marca;
    3: required string modelo;
    4: required i32 year;
    5: required string color;
    6: required string numPlacas;
    7: required string nombreConductor;
}

exception Error {
    1: required i32 errorCode;
    2: required string mensaje;
}

service IniciarSesion {
    Usuraio iniciarSesion(1: string email, 2: string password) throws (1: Error exp)
}

service RegistrarUsuario {
    Respuesta registrarUsuario(1: Usuario usuario) throws (1: Error exp)
}

service VisualizarReportes {
    list<Reporte> getAllReportes() throws (1: Error exp)
}

service VerReporte {
    Reporte getReporte(1: i32 idReporte) throws (1: Error exp)
}

service DictaminarReporte {
    Respuesta dictaminarReporte(1: Dictamen dictamen, 2: i32 idPerito, 3: i32 idReporte) throws (1: Error exp)
}