-- Apply after 001. Existing balances remain unchanged.
ALTER TABLE Estadistica
    ALTER inteligencia SET DEFAULT 100,
    ALTER finanzas SET DEFAULT 100,
    ALTER salud SET DEFAULT 100,
    ALTER disciplina SET DEFAULT 100;

CREATE TABLE IF NOT EXISTS EventoPuntuacion (
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
