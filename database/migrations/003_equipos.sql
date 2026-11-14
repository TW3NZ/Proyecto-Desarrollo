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
