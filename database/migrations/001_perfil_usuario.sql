-- Run against the existing selected database. No tables or rows are deleted.
-- Repeatable; DDL commits implicitly in MySQL. Apply before deploying the API.
ALTER TABLE Estadistica
    MODIFY inteligencia DECIMAL(8,4) NOT NULL DEFAULT 0,
    MODIFY finanzas DECIMAL(8,4) NOT NULL DEFAULT 0,
    MODIFY salud DECIMAL(8,4) NOT NULL DEFAULT 0,
    MODIFY disciplina DECIMAL(8,4) NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS PerfilUsuario (
    idUsu INT NOT NULL PRIMARY KEY,
    avatar JSON NULL,
    preferencias JSON NULL,
    CONSTRAINT PerfilUsuario_Usuario_fk FOREIGN KEY (idUsu) REFERENCES Usuario(idUsu)
);
