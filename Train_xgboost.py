#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Created on Fri Dec 29 07:21:50 2017

@author: pedrp
"""
import pandas as pd
import numpy as np

data = pd.read_csv("PropMec_Util.csv",usecols= [5,7,8,9,11,13,14,44,45,38,35])

 # Saco outliers
data = data.loc[data["lamesn resistencia"] > 10] 

data = data.loc[data["acecol nb f1"] < 0.2]
data = data.loc[data["lac indice de dureza"] > 0.75]


def family_type(data):
    
    if(((data["acecol boro en f1"] >= 10) & (data["acecol nb f1"] <= 0.01) & 
          (data["acecol ti f1"] <= 0.01) & (data["acecol vanadio f1"] <= 0.01)) |
          ((data["acecol boro en f1"] >= 10) & (data["acecol nb f1"] <= 0.01) & 
          (data["acecol ti f1"] >= 0.01) & (data["acecol vanadio f1"] <= 0.01)) |
          ((data["lac grado"] == 7153) | (data["lac grado"] == 9153) | 
          (data["lac grado"] == 7001) | (data["lac grado"] == 9001) |
          (data["lac grado"] == 7002))):       
              data["flia"] = "boro"
              
    elif(((data["acecol nb f1"] >= 0.01) & (data["acecol ti f1"] <= 0.01) & 
         (data["acecol boro en f1"] <= 10) & (data["acecol vanadio f1"] <= 0.01)) |
         ((data["acecol nb f1"] >= 0.01) & (data["acecol ti f1"] >= 0.01) & 
         (data["acecol boro en f1"] <= 10) & (data["acecol vanadio f1"] >= 0.01))):              
              data["flia"] = "niobio"
              
    elif(((data["acecol nb f1"] <= 0.01) & (data["acecol ti f1"] <= 0.01) & 
         (data["acecol boro en f1"] <= 10) & (data["acecol vanadio f1"] >= 0.01))):
              data["flia"] = "vanadio"
              
    elif(((data["acecol nb f1"] <= 0.01) & (data["acecol ti f1"] <= 0.01) & 
         (data["acecol boro en f1"] <= 10) & (data["acecol vanadio f1"] <= 0.01)) |
         ((data["acecol nb f1"] <= 0.01) & (data["acecol ti f1"] >= 0.01) & 
         (data["acecol boro en f1"] <= 10) & (data["acecol vanadio f1"] <= 0.01))):              
              data["flia"] = "cmn"
              
    elif(~(np.isnan(data["acecol nb f1"]) | np.isnan(data["acecol ti f1"]) |
        np.isnan(data["acecol boro en f1"]) | np.isnan(data["acecol vanadio f1"]))):
              data["flia"] = "otros"
      
              
    return data

data["flia"] = np.nan

data["acecol boro en f1"].fillna(value = 0,inplace = True)
data = data.apply(family_type,axis = 1)

data = data[data["flia"].notnull()] # me quedo con los casos que puedo saber a que flia pertenecen
data = data.loc[data["flia"] == "cmn"]

#from sklearn.base import BaseEstimator, TransformerMixin
#
#class ColumnSelector(BaseEstimator, TransformerMixin):
#    def __init__(self, columns):
#        self.columns = columns
#    
#    def transform(self, X, *_):
#        if isinstance(X, pd.DataFrame):
#            return data_cuanti = data_cuanti.groupby('flia').transform(lambda x: x.fillna(x.mean()))
#        else:
#            raise TypeError("Este Transformador solo funciona en DF de Pandas")
#    
#    def fit(self, X, *_):
#        return self


from sklearn.preprocessing import StandardScaler
from sklearn.preprocessing import Imputer
from sklearn.pipeline import Pipeline
#from sklearn.ensemble import RandomForestRegressor
from xgboost import XGBRegressor
import scipy.stats as st


pipe = Pipeline(steps=[('imputer', Imputer()), ('scale', StandardScaler()),
                       ('xgoost', XGBRegressor())])    

#params = {"RandomForest__n_estimators": list(range(20,50,3)),
#          "RandomForest__max_depth":list(range(15,50,3))}
 
one_to_left = st.beta(10, 1)  
from_zero_positive = st.expon(0, 50)

params={    
    "xgoost__n_estimators": st.randint(3, 40),
    "xgoost__max_depth": st.randint(3, 40),
    "xgoost__learning_rate": st.uniform(0.05, 0.4),
    "xgoost__colsample_bytree": one_to_left,
    "xgoost__subsample": one_to_left,
    "xgoost__gamma": st.uniform(0, 10),
    'xgoost__reg_alpha': from_zero_positive,
    "xgoost__min_child_weight": from_zero_positive}

X = data[['acecol c f1', 'lac tb', 'acecol mn f1', 'lac t b cola',
          'lac indice de dureza']]

y = data["lamesn resistencia"]
y = y.dropna()
X = X.loc[y.index,:] 

del data

from sklearn.model_selection import train_test_split
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

from sklearn.model_selection import RandomizedSearchCV
model = RandomizedSearchCV(pipe,params,n_jobs  = -1,verbose = 10)

model.fit(X_train,y_train)

# Scoring

from sklearn.metrics import r2_score
import joblib
# guardo modelo
joblib.dump(model, 'model.pkl')

# cargo modelo
model = joblib.load('model.pkl')

y_pred= model.predict(X_test)
dif = np.abs(y_pred - y_test)
print("Score con +-20Mpa:",sum(dif<20)/y_pred.shape[0])
print("Score con +-15Mpa:",sum(dif<15)/y_pred.shape[0])
print("r2:",r2_score(y_pred=y_pred,y_true=y_test))