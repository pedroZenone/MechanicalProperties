
var rest = require('restler');

rest.post('http://localhost:3000', {
    data: { model: "soft_model", lac_grado: 7055.0, acecol_boro: 1.0, acecol_c: 0.16, acecol_mn: .8, acecol_ti: 0.0012, acecol_nb: 0.0015, acecol_vanadio: 0.0033, lac_tb: 635.0, lac_t_b: 669.5714, lac_dureza: 1.232346 },
}).on('complete', function (data, response) {


    if (response.statusCode == 200) {        
        
        console.log("El resultado fue:",response.rawEncoded);
    }
});

// { "model": "soft_model", "lac_grado": 7055.0, "acecol_boro": 1.0, "acecol_c": 0.16, "acecol_mn": .8, "acecol_ti": 0.0012, "acecol_nb": 0.0015, "acecol_vanadio": 0.0033, "lac_tb": 635.0, "lac_t_b": 669.5714, "lac_dureza": 1.232346 }