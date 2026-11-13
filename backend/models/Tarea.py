from pydantic import BaseModel , Field
from datetime import date
from typing import Literal

class Tarea(BaseModel):
    Titulo : str 
    idUsu : int 
    idTarea : int 
    idResponsable: int | None = None 
    idProyecto : int | None = None
    Prioridad : Literal["Baja" , "Media" , "Alta"]
    Descripcion : str | None = None
    Fecha : date
    Fecha_Fin : date | None = None
    Completada : bool = False
    

class TareaCategoria(BaseModel):
    idTarea: int
    idCategoria: int
    
class Categoria(BaseModel):
    idCategoria: int
    nombre: str

class tareaCreate(BaseModel):
    Titulo : str 
    idResponsable: int | None = None 
    idProyecto : int | None = None
    Prioridad : Literal["Baja" , "Media" , "Alta"]
    Descripcion : str | None = None
    Fecha : date = Field(default_factory=date.today)
    Fecha_Fin : date | None = None
    Completada : bool = False
    categorias: set[Literal[1, 2, 3, 4]] = Field(min_length=1)
    
