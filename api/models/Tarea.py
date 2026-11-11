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
    Fecha : date = Field(default_factory=date.today)
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
    idUsu : int 
    idResponsable: int | None = None 
    idProyecto : int | None = None
    Prioridad : Literal["Baja" , "Media" , "Alta"]
    Descripcion : str | None = None
    Fecha_Fin : date | None = None
    Completada : bool = False
    categorias: list[int] = Field(min_length=1)
    
