
create database BD_my_daily_routine;
use BD_my_daily_routine;

CREATE TABLE Usuario (
    idUsu INT NOT NULL,
    email VARCHAR(255) NOT NULL,
    nameUsu VARCHAR(50) NOT NULL,
    lastName VARCHAR(50) NOT NULL,
    nickName VARCHAR(50) NOT NULL,
    passwordUsu VARCHAR(255) NOT NULL,
    createDate DATE NOT NULL,
    genero VARCHAR(10) NOT NULL CHECK (genero IN ('Hombre', 'Mujer')),
    foto VARCHAR(500) NULL,

    CONSTRAINT Usuario_pk PRIMARY KEY (idUsu),
    CONSTRAINT Usuario_Nick_Uk UNIQUE (nickName),
    CONSTRAINT Usuario_Email_Uk UNIQUE (email)
);

CREATE TABLE Estadistica (
    idUsu INT NOT NULL,
    inteligencia DECIMAL(8,4) NOT NULL DEFAULT 100,
    salud DECIMAL(8,4) NOT NULL DEFAULT 100,
    finanzas DECIMAL(8,4) NOT NULL DEFAULT 100,
    disciplina DECIMAL(8,4) NOT NULL DEFAULT 100,

    CONSTRAINT Estadistica_pk PRIMARY KEY (idUsu),
    CONSTRAINT Estadistica_Usuario_fk FOREIGN KEY (idUsu) REFERENCES Usuario(idUsu)
);


CREATE TABLE PerfilUsuario (
    idUsu INT NOT NULL PRIMARY KEY,
    avatar JSON NULL,
    preferencias JSON NULL,
    CONSTRAINT PerfilUsuario_Usuario_fk FOREIGN KEY (idUsu) REFERENCES Usuario(idUsu)
);

CREATE TABLE Equipo (
    idEquipo INT NOT NULL,
    nameEquipo VARCHAR(50) NOT NULL,
    siglasEquipo VARCHAR(2) NOT NULL,
    imagenEquipo VARCHAR(500) NULL,
    idCreador INT NOT NULL,
    CONSTRAINT Equipo_PK PRIMARY KEY (idEquipo),
    CONSTRAINT Equipo_Usuario_FK FOREIGN KEY (idCreador) REFERENCES Usuario (idUsu)
);


CREATE TABLE MiembroEquipo (
    idMiembro INT AUTO_INCREMENT NOT NULL,
    idEquipo INT NOT NULL,
    idUsu INT NOT NULL,

    CONSTRAINT MiembroEquipo_PK
        PRIMARY KEY (idMiembro),

    CONSTRAINT MiembroEquipo_Equipo_FK
        FOREIGN KEY (idEquipo) REFERENCES Equipo(idEquipo),

    CONSTRAINT MiembroEquipo_Usuario_FK
        FOREIGN KEY (idUsu) REFERENCES Usuario(idUsu),

    CONSTRAINT MiembroEquipo_UK
        UNIQUE (idEquipo, idUsu)
);

CREATE TABLE Categoria (
    idCategoria INT NOT NULL,
    nombre VARCHAR(50) NOT NULL,

    CONSTRAINT Categoria_PK PRIMARY KEY (idCategoria),
    CONSTRAINT Categoria_Nombre_UK UNIQUE (nombre)
);

CREATE TABLE Proyecto (
    idProyecto INT NOT NULL,
    idEquipo INT NOT NULL,
    idCategoria INT NOT NULL,
    nombre VARCHAR(100) NOT NULL,
    meta VARCHAR(500) NOT NULL,
    fechaInicio DATE NOT NULL,
    fechaFin DATE NULL,
    imagen VARCHAR(500) NULL,

    CONSTRAINT Proyecto_PK
        PRIMARY KEY (idProyecto),

    CONSTRAINT Proyecto_Equipo_FK
        FOREIGN KEY (idEquipo) REFERENCES Equipo(idEquipo),

    CONSTRAINT Proyecto_Categoria_FK
        FOREIGN KEY (idCategoria) REFERENCES Categoria(idCategoria)
);

CREATE TABLE MiembroProyecto (
    idMiembroProyecto INT AUTO_INCREMENT NOT NULL,
    idProyecto INT NOT NULL,
    idMiembro INT NOT NULL,
    rol VARCHAR(20) NOT NULL,

    CONSTRAINT MiembroProyecto_PK
        PRIMARY KEY (idMiembroProyecto),

    CONSTRAINT MiembroProyecto_Proyecto_FK
        FOREIGN KEY (idProyecto) REFERENCES Proyecto(idProyecto),

    CONSTRAINT MiembroProyecto_Miembro_FK
        FOREIGN KEY (idMiembro) REFERENCES MiembroEquipo(idMiembro),

    CONSTRAINT MiembroProyecto_UK
        UNIQUE (idProyecto, idMiembro)
);


CREATE TABLE Tarea (
    idTarea INT NOT NULL,
    idUsu INT NOT NULL,
    responsable_id INT NULL,
    idProyecto INT NULL,
    titulo VARCHAR(150) NOT NULL,
    prioridad VARCHAR(10) NOT NULL CHECK (prioridad IN ('Baja', 'Media', 'Alta')),
    descripcion TEXT NULL,
    fecha DATE NOT NULL,
    fechaFinalizacion DATE NULL,
    completada BOOLEAN NOT NULL DEFAULT FALSE,

    CONSTRAINT Tarea_PK
        PRIMARY KEY (idTarea),

    CONSTRAINT Tarea_Usuario_FK
        FOREIGN KEY (idUsu) REFERENCES Usuario(idUsu),

    CONSTRAINT Tarea_Responsable_FK
        FOREIGN KEY (responsable_id) REFERENCES MiembroProyecto(idMiembroProyecto),

    CONSTRAINT Tarea_Proyecto_FK
        FOREIGN KEY (idProyecto) REFERENCES Proyecto(idProyecto)
);

CREATE TABLE Actividad_Tarea (
    idActividad INT AUTO_INCREMENT NOT NULL,
    tareaid INT NOT NULL,
    usuarioid INT NOT NULL,
    fecha DATETIME NOT NULL,
    porcentaje INT NOT NULL CHECK (porcentaje BETWEEN 0 AND 100),
    descripcion VARCHAR(500) NULL,

    CONSTRAINT Actividad_Tarea_PK
        PRIMARY KEY (idActividad),

    CONSTRAINT Actividad_Tarea_Tarea_FK
        FOREIGN KEY (tareaid) REFERENCES Tarea(idTarea),

    CONSTRAINT Actividad_Tarea_Usuario_FK
        FOREIGN KEY (usuarioid) REFERENCES Usuario(idUsu)
);

CREATE TABLE TareaCategoria (
    idTareaCategoria INT AUTO_INCREMENT NOT NULL,
    idTarea INT NOT NULL,
    idCategoria INT NOT NULL,

    CONSTRAINT TareaCategoria_PK
        PRIMARY KEY (idTareaCategoria),

    CONSTRAINT TareaCategoria_Tarea_FK
        FOREIGN KEY (idTarea) REFERENCES Tarea(idTarea),

    CONSTRAINT TareaCategoria_Categoria_FK
        FOREIGN KEY (idCategoria) REFERENCES Categoria(idCategoria),

    CONSTRAINT TareaCategoria_UK
        UNIQUE (idTarea, idCategoria)
);



CREATE TABLE EventoPuntuacion (
    idTarea INT NOT NULL,
    tipo VARCHAR(20) NOT NULL,
    idUsu INT NOT NULL,
    fecha DATE NOT NULL,
    pendientes INT NOT NULL,
    delta JSON NOT NULL,
    versionRegla INT NOT NULL,
    PRIMARY KEY (idTarea, tipo),
    CONSTRAINT EventoPuntuacion_Tarea_fk FOREIGN KEY (idTarea) REFERENCES Tarea(idTarea),
    CONSTRAINT EventoPuntuacion_Usuario_fk FOREIGN KEY (idUsu) REFERENCES Usuario(idUsu),
    CONSTRAINT EventoPuntuacion_Tipo_ck CHECK (tipo IN ('completada','vencimiento')),
    CONSTRAINT EventoPuntuacion_Pendientes_ck CHECK (pendientes >= 1)
);


-- Collaborative teams (003), included for fresh installations.
-- Apply once after 002. DDL commits implicitly. Do not rerun the full schema.
CREATE TABLE EquipoInvitacion (
    idEquipo INT NOT NULL PRIMARY KEY,
    codigo CHAR(8) CHARACTER SET ascii COLLATE ascii_bin NOT NULL UNIQUE,
    FOREIGN KEY (idEquipo) REFERENCES Equipo(idEquipo)
);

ALTER TABLE Proyecto ADD UNIQUE KEY Proyecto_Equipo_UK (idProyecto,idEquipo);
ALTER TABLE MiembroEquipo ADD UNIQUE KEY MiembroEquipo_Equipo_UK (idMiembro,idEquipo);
ALTER TABLE MiembroProyecto ADD COLUMN idEquipo INT NULL;
UPDATE MiembroProyecto mp JOIN Proyecto p ON p.idProyecto=mp.idProyecto SET mp.idEquipo=p.idEquipo;
ALTER TABLE MiembroProyecto
    MODIFY idEquipo INT NOT NULL,
    ADD UNIQUE KEY MiembroProyecto_Proyecto_UK (idMiembroProyecto,idProyecto),
    ADD CONSTRAINT MP_ProyectoEquipo_FK FOREIGN KEY (idProyecto,idEquipo) REFERENCES Proyecto(idProyecto,idEquipo),
    ADD CONSTRAINT MP_MiembroEquipo_FK FOREIGN KEY (idMiembro,idEquipo) REFERENCES MiembroEquipo(idMiembro,idEquipo);
ALTER TABLE Tarea ADD UNIQUE KEY Tarea_Proyecto_UK (idTarea,idProyecto);

CREATE TABLE ParticipanteTarea (
    idTarea INT NOT NULL,
    idProyecto INT NOT NULL,
    idMiembroProyecto INT NOT NULL,
    completada BOOLEAN NOT NULL DEFAULT FALSE,
    completadaEn DATETIME NULL,
    PRIMARY KEY (idTarea,idMiembroProyecto),
    CONSTRAINT PT_TareaProyecto_FK FOREIGN KEY (idTarea,idProyecto) REFERENCES Tarea(idTarea,idProyecto),
    CONSTRAINT PT_MiembroProyecto_FK FOREIGN KEY (idMiembroProyecto,idProyecto) REFERENCES MiembroProyecto(idMiembroProyecto,idProyecto)
);

ALTER TABLE EventoPuntuacion DROP PRIMARY KEY, ADD PRIMARY KEY (idTarea,tipo,idUsu);
