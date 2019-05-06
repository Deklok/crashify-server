struct Admin {

}

struct Dictamen {

}

struct Perito {

}

struct Respuesta {
    1: required i32 respuestaCode;
    2: required string mensaje;
}

struct Reporte {

}

struct Usuario {

}

struct Vehiculo {

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