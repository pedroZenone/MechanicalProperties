# https://www.floydhub.com/pzenone/datasets/
# ------------------------------------------------
## --data mckay/projects/quick-start/1/output:/models
## --data pzenone/projects/first-test/21/output:/models

#floyd run --data pzenone/projects/first-test/21/output:/models --mode serve



from flask import Flask
from flask import request
import json
import joblib

app = Flask(__name__) 
#
##@app.route('/', methods = ['GET'])
##def funca():
##    print("Anda :D")
#    
@app.route('/<path:path>', methods=['POST'])
def test(path):
    
    jsondata = request.get_json()
    data = json.loads(jsondata)
    model = joblib.load('/models/model.pkl')
#y_predict = model.predict(data['data'])
    y_predict = model.predict(data['data'])
    #stuff happens here that involves data to obtain a result

    result = {'resultado': y_predict.tolist()}
    return json.dumps(result)

if __name__ == '__main__':
    app.run(host='0.0.0.0')

