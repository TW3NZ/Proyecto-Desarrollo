from pydantic import BaseModel , EmailStr
from datetime import date
from typing import Literal # se usa literal para que un atributo solo pueda tomar una cantidad limitada de valores
 

class User(BaseModel):
    
    idUsu : int 
    name : str 
    lastName : str 
    nickName : str 
    email : EmailStr
    password : str 
    createDate : date 
    genero : Literal["Hombre","Mujer"]
    foto : str | None = None

class createUser(BaseModel):
    name : str 
    lastName : str 
    nickName : str 
    email : EmailStr
    password : str 
    createDate : date 
    genero : Literal["Hombre","Mujer"]
    foto : str | None = None
   
class LoginUser(BaseModel):
    identificador: str  # Email o nickname
    password: str
    
    