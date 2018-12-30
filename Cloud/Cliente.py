import json
import requests
import numpy as np
import pandas as pd

url = "https://www.floydlabs.com/expose/Ch6wKqMyHprNTT8RvcSQyX"
X_test = pd.read_csv('./Test.csv')
X_test = X_test.drop(['Unnamed: 0'],axis = 1)

conv = {'data': np.array(X_test).tolist(), 'topic': 'predict'}
s = json.dumps(conv)
res = requests.post(url, json=s)
resu = res.json()
datos_devueltos = resu['resultado']
print("Status de conexion:", res.status_code)
print("Primer resultado:",datos_devueltos[1])

