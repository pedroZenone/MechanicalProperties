# -*- coding: utf-8 -*-
"""
Created on Wed Dec 07 14:45:16 2016

@author: pedzenon
"""
import pandas as pd
from sklearn.preprocessing import Imputer
import numpy as np
#import math

#Cargo el Excel de input en un DataFrame
PropMec = pd.read_excel("/dataset/IBM_BASE_C_V_TI.xlsx", sheetname=0)
#=========================================
# Creo una funcion para quitar outliers
#=================================
    
    
def QuitarOutliers(DF, Columna, CantStdDevs=2, Min=0, Max=1, Fijo=0):

    if Fijo==0:
        Min = DF[Columna].mean()-(DF[Columna].std()*CantStdDevs)
        Max = DF[Columna].mean()+(DF[Columna].std()*CantStdDevs)
    
    #Saco los minimos
    Outliers = DF[Columna].loc[DF[Columna]<Min]
    
    for Indice in Outliers.index:
        DF.loc[Indice, Columna] = Min
    
    #Saco los Maximos
    Outliers = DF[Columna].loc[DF[Columna]>Max]
    
    for Indice in Outliers.index:
        DF.loc[Indice, Columna] = Max

    return
    

#Quito Ouliers de las variables mas notables
QuitarOutliers(PropMec, "Lac Temp Cuerpo en R4")
QuitarOutliers(PropMec, "Lac Grado")
QuitarOutliers(PropMec, "AceCol N2 F1",3,20,100,1) 
QuitarOutliers(PropMec, "Lac Tb")
QuitarOutliers(PropMec, "Lac T B Cola",3,480,750,1)
QuitarOutliers(PropMec, "AceCol C F1")
QuitarOutliers(PropMec, "AceCol Mn F1")
QuitarOutliers(PropMec, "AceCol Ti F1")
QuitarOutliers(PropMec, "AceCol Vanadio F1",3,0,0.06,1)

QuitarOutliers(PropMec, "rep bobina")

#Remuevo las filas con Resistencias desviadas (<280 o >650)
PropMec = PropMec.drop(PropMec[PropMec["LameSn Resistencia"]<280].index)
PropMec = PropMec.drop(PropMec[PropMec["LameSn Resistencia"]>650].index)

#Concateno las variables seleccionadas (de entrada)

#Convierto a Numerico las categorias de Lac gradoProducto
Aux_CategToNum = pd.Categorical.from_array(PropMec["Lac gradoProducto"]).codes
Df_Aux_CategToNum = pd.DataFrame({'Lac gradoProducto-Num':Aux_CategToNum}, index=PropMec.index)

#Vuelvo a poner en NaN los -1 para que despues se puedan reemplazar x el valor mas frecuente
Df_Aux_CategToNum.replace('-1',np.nan,True)

imp = Imputer(missing_values='NaN', strategy='most_frequent', axis=0)

X = Df_Aux_CategToNum.values
Aux_CategToNum = imp.fit_transform(X)
Aux_CategToNum = Aux_CategToNum.ravel()

#Vuelvo a dejarlo en un Dataframe
Df_Aux_CategToNum = pd.DataFrame({'Lac gradoProducto-Num':Aux_CategToNum}, index=Df_Aux_CategToNum.index)

### Continuar con #rep bobina# quitarle los nulos
imp = Imputer(missing_values='NaN', strategy='mean', axis=0)

X = PropMec["rep bobina"].values
Aux_RepBobina = imp.fit_transform(X.reshape(-1,1))
Aux_RepBobina = Aux_RepBobina.ravel()

#Vuelvo a dejarlo en un Dataframe
Df_Aux_RepBobina = pd.DataFrame({'rep bobina':Aux_RepBobina}, index=PropMec.index)


###Filtro los "na" = NULL de Lac gradoProducto
###PropMecFiltrado = PropMec.dropna(subset=["Lac gradoProducto"])

PropMecSalida = pd.concat([PropMec["Lac Espesor"],PropMec["Lac Grado"],PropMec["AceCol C F1"], PropMec["AceCol Mn F1"], PropMec["AceCol N2 F1"]],axis=1)
PropMecSalida = pd.concat([PropMecSalida, PropMec["AceCol Nb F1"],PropMec["AceCol Si F1"],PropMec["AceCol Ti F1"], PropMec["AceCol Vanadio F1"], PropMec["Lac Temp Cuerpo en R4"], PropMec["Lac TFLCuerpo"], PropMec["Lac T B Cola"]],axis=1)
PropMecSalida = pd.concat([PropMecSalida, PropMec["Lac Indice de Dureza"]],axis=1)

#Agrego la columna Lac gradoProducto-Num
PropMecSalida = pd.concat([PropMecSalida, Df_Aux_CategToNum],axis=1)


#Convierto a Numerico las categorias de Lac gradoProducto 
Aux_CategToNum = pd.Categorical.from_array(PropMec["Lac Calidad"]).codes
Df_Aux_CategToNum = pd.DataFrame({'Lac Calidad-Num':Aux_CategToNum}, index=PropMec.index)

PropMecSalida = pd.concat([PropMecSalida, Df_Aux_CategToNum],axis=1)

#Agrego rep Bobina
PropMecSalida = pd.concat([PropMecSalida, Df_Aux_RepBobina],axis=1)

#Tambien las variables de Salida
PropMecSalida = pd.concat([PropMecSalida, PropMec["LameSn Alargamiento"],PropMec["LameSn Fluencia"],PropMec["LameSn Resistencia"]],axis=1)

#Escribo el Dataframe filtrado y procesado a Excel
#PropMecSalida.to_excel("C:\Data Mining\Propiedades Mecanicas AR\IBM BASE C V TI_Filtrado.xlsx")

#Reduzco la muestra por falta de memoria, si fuera necesario
#PropRed = PropMecSalida.sample(frac=0.5)
PropRed = PropMecSalida.sample(frac=1)

#Separo los datos en para entrenar de los que sean para test
msk = np.random.rand(len(PropRed)) < 0.8

PropMecTrain = PropRed[msk] # 80% para entrenar
PropMecTest = PropRed[~msk] # 20% para entrenar

#Convierto a arrays y separo variables de entrada y salida
X = PropMecTrain.values[:,0:16]
Y = PropMecTrain.values[:,18]

#Y2 = np.asarray(Y, dtype="|S6") #convierte a string de 6 posiciones. No va para este caso
Y3 = np.asarray(Y, dtype="int16") #Convierte a int (trunca los decimales)
#Y4 = np.asarray((Y/10).round()*10, dtype="int16") #Convierte a int y redondea de a 10
#Y5 = np.asarray((Y/25).round()*25, dtype="int16") #Convierte a int y redondea de a 25

#################Separo las variables de entrada en un array X y las de salida en Y
from sklearn import preprocessing

X_test = PropMecTest.values[:,0:16]
Y_test = PropMecTest.values[:,18]

#Y2_test = np.asarray(Y_test, dtype="|S6")
Y3_test = np.asarray(Y_test, dtype="int16")
#Y4_test = np.asarray((Y_test/10).round()*10, dtype="int16")
#Y5_test = np.asarray((Y_test/25).round()*25, dtype="int16")

#################Normalizo las variables para los modelos lineales, especialmente
##X_scaled = preprocessing.scale(X)
##X_scaled_test = preprocessing.scale(X_test)

robust_scaler = preprocessing.RobustScaler()
X_scaled = robust_scaler.fit_transform(X)
X_scaled_test = robust_scaler.transform(X_test)


#################Normalizo las variables para los modelos lineales, especialmente

#RandomForest 
from sklearn.ensemble import RandomForestClassifier
from sklearn.linear_model import LinearRegression

clf_RF = LinearRegression()
clf_RF.fit(X_scaled, Y3)                    

##Evaluando los resultados###############

#Veo las diferencias de prediccion de RandomForestClassifier
Predicho = clf_RF.predict(X_scaled_test)

from sklearn.metrics import r2_score
print(r2_score(Y3_test,Predicho))

##########################
#Grabo los modelos entrenados de RandomForest:

import joblib
joblib.dump(clf_RF, '/output/model.pkl')

####Para Cargarlos:
###clf = joblib.load('ModeloPersistido_clf.pkl') 



