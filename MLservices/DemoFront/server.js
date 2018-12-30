/////// npm i mssql@3.3.0

var express = require("express");
var bodyParser = require("body-parser");
var app = express();
//Here we are configuring express to use body-parser as middle-ware.
app.use(bodyParser.urlencoded({ extended: true }));
app.use(bodyParser.json());

// Seteo conexion al server
var sql = require('mssql')

var config = {
    user: 'PRIVATE',
    password: 'PRIVATE',
    server: 'PRIVATE',
    database: 'datos'
};

// Esperando que le posteen data
app.post('/', function (req, res) {
    
    var ip = (req.headers['x-forwarded-for'] ||
     req.connection.remoteAddress ||
     req.socket.remoteAddress ||
     req.connection.socket.remoteAddress).split(",")[0];
    
    console.log(ip)

    var model = req.body.model;
    var lac_grado = req.body.lac_grado;
    var acecol_boro = req.body.acecol_boro;
    var acecol_c = req.body.acecol_c;
    var acecol_mn = req.body.acecol_mn;
    var acecol_ti = req.body.acecol_ti;
    var acecol_nb = req.body.acecol_nb;
    var acecol_vanadio = req.body.acecol_vanadio;
    var lac_tb = req.body.lac_tb;
    var lac_t_b = req.body.lac_t_b;
    var lac_dureza = req.body.lac_dureza;

    var resu
    var connection = new sql.Connection(config, function (err) {

        var request = new sql.Request(connection)

        request.input('model', sql.NVarChar, model);
        request.input('lac_grado', sql.Float, lac_grado);
        request.input('acecol_boro', sql.Float, acecol_boro);
        request.input('acecol_c', sql.Float, acecol_c);
        request.input('acecol_mn', sql.Float, acecol_mn);
        request.input('acecol_ti', sql.Float, acecol_ti);
        request.input('acecol_nb', sql.Float, acecol_nb);
        request.input('acecol_vanadio', sql.Float, acecol_vanadio);
        request.input('lac_tb', sql.Float, lac_tb);
        request.input('lac_t_b', sql.Float, lac_t_b);
        request.input('lac_dureza', sql.Float, lac_dureza);

        request.execute('Predict_Resistencia', function (err, recordsets, returnValue, affected) {
            if (err) console.log(err);   
            resu = recordsets[0][0];
            var string = JSON.stringify(resu);
            var json = JSON.parse(string);    
            console.log(json.Resultado.toString())
            res.send(json.Resultado.toString())
            connection.close();
        });
    });

    
});

app.listen(3000, function () {
    console.log("Started on PORT 3000");
})
