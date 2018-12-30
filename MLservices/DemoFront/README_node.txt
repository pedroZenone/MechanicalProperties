POC SQL con R:
-------------

Abir una terminal.
Para correr el programa primero ejecutar el server: node server.js  esto lo que hace es quedarse escuchando por el
puerto 3000 y cuando recibe un post, hace un predict con los parametros que le envía el cliente y devuelve el 
resultado

Para correr el cliente: node cliente.js  te va a devolver el resultado del predict y se cierra

En caso de requerir instalar paquietes:
npm install express
npm install body-parser
npm i mssql@3.3.0  (si no deja tratar de hacer primero npm install mssql)

--- Una opcion alternativa al cliente, se puede hacer desde el chrome bajando la extension rest web service client
ahi dentro hay que configurarlo segun la foto "rest web service client.png"

{ "model": "soft_model", "lac_grado": 7055.0, "acecol_boro": 1.0, "acecol_c": 0.16, "acecol_mn": 0.8, "acecol_ti": 0.0012, "acecol_nb": 0.0015, "acecol_vanadio": 0.0033, "lac_tb": 635.0, "lac_t_b": 669.5714, "lac_dureza": 1.232346 }