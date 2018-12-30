USE [Datos]
GO

--------------------------------------------------------------------------------------------------------
-----------------------------------  Procedures  -------------------------------------------------------
--------------------------------------------------------------------------------------------------------

-- Entreno --

ALTER PROCEDURE [dbo].[TrainTipPredictionModelSciKitPy] (@trained_model varbinary(max) OUTPUT)
AS
BEGIN
  EXEC sp_execute_external_script
  @language = N'Python',
  @script = N'
  
import numpy as np		
import pandas as pd		

# Saco outliers
data = data.loc[data["lamesn resistencia"] > 10] 

data = data.loc[data["acecol nb f1"] < 0.2]
data = data.loc[data["lac indice de dureza"] > 0.75]

from sklearn.preprocessing import StandardScaler
from sklearn.preprocessing import Imputer
from sklearn.pipeline import Pipeline
from sklearn.ensemble import RandomForestRegressor

pipe = Pipeline(steps=[("imputer", Imputer()), ("scale", StandardScaler()),
						("forest", RandomForestRegressor(n_estimators = 38, max_depth = 15,n_jobs = -1))])  							    

X = data[["acecol c f1", "lac tb", "acecol mn f1", "lac t b cola",
			"lac indice de dureza"]]

y = data["lamesn resistencia"]
y = y.dropna()
X = X.loc[y.index,:] 

from sklearn.model_selection import train_test_split
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

pipe.fit(X_train,y_train)

# Scoring

from sklearn.metrics import r2_score
		
# guardo modelo
import pickle

trained_model = pickle.dumps(pipe)		

y_pred= pipe.predict(X_test)
dif = np.abs(y_pred - y_test)
print("Score con +-20Mpa:",sum(dif<20)/y_pred.shape[0])
print("Score con +-15Mpa:",sum(dif<15)/y_pred.shape[0])
print("r2:",r2_score(y_pred=y_pred,y_true=y_test))
  '

 , @input_data_1 = N'select "lac grado", "acecol boro en f1", "acecol c f1" , "acecol mn f1" ,  "acecol nb f1" , "acecol ti f1", "acecol vanadio f1", "lamesn resistencia", "lac tb", "lac t b cola", "lac indice de dureza" from dbo.Datos where [flia] = ''cmn'''
    , @input_data_1_name = N'data'
    , @params = N'@trained_model varbinary(max) OUTPUT'
    , @trained_model = @trained_model OUTPUT;

END;
GO


-- Prediccion --

-- Me Creo una funcion que crea una tabla en base a las filas que le pasas
alter FUNCTION [dbo].[fnTableGen] ( 
@lac_grado float,
@acecol_boro float,
@acecol_c float,
@acecol_mn float,
@acecol_nb float,
@acecol_ti float,
@acecol_vanadio float,
@lac_tb float,
@lac_t_b float,
@lac_dureza float

 ) 
 RETURNS TABLE 
 AS 
   RETURN 
   (  
 	  SELECT 
	    @lac_grado as[lac grado] ,
        @acecol_boro as [acecol boro en f1] ,
		@acecol_c as [acecol c f1]  ,
		@acecol_mn as [acecol mn f1] ,
		@acecol_nb as [acecol nb f1] ,	
		@acecol_ti as [acecol ti f1] ,			
		@acecol_vanadio as [acecol vanadio f1]  ,				
		@lac_tb as [lac tb] ,
		@lac_t_b as [lac t b cola] ,
		@lac_dureza as[lac indice de dureza] 		
   ) 

-- Procedure que predice

alter PROCEDURE [dbo].[Predict_Resistencia_Python]   @model VARCHAR(100), @lac_grado float, @acecol_boro float,@acecol_c float ,@acecol_mn float,@acecol_nb float,@acecol_ti float,@acecol_vanadio float,@lac_tb float,@lac_t_b float,@lac_dureza float
AS
BEGIN
DECLARE @inquery nvarchar(max) = N'SELECT * FROM [dbo].[fnTableGen](@lac_grado, @acecol_boro,@acecol_c ,@acecol_mn,@acecol_nb,@acecol_ti,@acecol_vanadio,@lac_tb,@lac_t_b,@lac_dureza)';
DECLARE @rx_model VARBINARY(MAX) = (SELECT model FROM rental_rx_models_soft WHERE model_name = @model);

EXEC sp_execute_external_script  
	@language = N'Python',
	@script = N'  
		
import pickle
import pandas as pd
import numpy as np

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

InputDataSet["flia"] = np.nan
InputDataSet = InputDataSet.apply(family_type,axis = 1)
InputDataSet = InputDataSet.loc[InputDataSet["flia"] == "cmn"]

rental_model = pickle.loads(rx_model);
InputDataSet = InputDataSet[["acecol c f1", "lac tb", "acecol mn f1", "lac t b cola","lac indice de dureza"]]		
#Call prediction function
rental_predictions = pd.DataFrame(rental_model.predict(InputDataSet));		
	',  
	@input_data_1 = @inquery
	, @output_data_1_name = N'rental_predictions'
	,@params = N' @rx_model varbinary(max), @lac_grado float, @acecol_boro float,@acecol_c float ,@acecol_mn float,@acecol_nb float,@acecol_ti float,@acecol_vanadio float,@lac_tb float,@lac_t_b float,@lac_dureza float', @rx_model = @rx_model, @lac_grado = @lac_grado, @acecol_boro = @acecol_boro,@acecol_c = @acecol_c ,@acecol_mn = @acecol_mn,@acecol_nb = @acecol_nb,@acecol_ti = @acecol_ti,@acecol_vanadio = @acecol_vanadio,@lac_tb = @lac_tb,@lac_t_b = @lac_t_b,@lac_dureza = @lac_dureza  
	WITH RESULT SETS (([Resultado] float not null));
END;

--------------------------------------------------------------------------------------------------------
-----------------------------------  Productivo  -------------------------------------------------------
--------------------------------------------------------------------------------------------------------

-- Entreno

IF not EXISTS (select * from sysobjects where name='rental_rx_models' and xtype='U')
begin
	CREATE TABLE rental_rx_models (
                model_name VARCHAR(30) NOT NULL DEFAULT('default model') PRIMARY KEY,
                model VARBINARY(MAX) NOT NULL)
end	

DECLARE @model VARBINARY(MAX);
EXEC dbo.[TrainTipPredictionModelSciKitPy] @model OUTPUT;

IF NOT EXISTS(select * from rental_rx_models_soft where model_name='soft_model_py')
   INSERT INTO rental_rx_models_soft (model_name, model) VALUES('soft_model_py', @model);
ELSE
	update dbo.rental_rx_models_soft set model=  @model where model_name= 'soft_model_py';

SELECT * FROM rental_rx_models_soft;

-- Predict

exec [Predict_Resistencia_Python] @model = 'soft_model_py', @lac_grado = 7055, @acecol_boro = 1,@acecol_c = 0.16 ,@acecol_mn = 0.8 ,@acecol_ti = 0.0012, @acecol_nb = 0.0015, @acecol_vanadio = 0.0033, @lac_tb = 635,@lac_t_b = 669.5714,@lac_dureza = 1.232346
