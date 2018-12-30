use [datos]

-------  Procedures  --------
--------------------------

-- Entreno --

alter PROCEDURE [dbo].[Train_Resistencia_Revo] (@trained_model varbinary(max) OUTPUT)
AS
BEGIN
    EXECUTE sp_execute_external_script
      @language = N'R'
    , @script = N'	

		data = as.data.frame(data)
		colnames(data) <- gsub(" ", ".", colnames(data), fixed = TRUE)		
		
		# data = data[data$`lamesn.resistencia` > 10,]  
		data = subset(data,data$`lamesn.resistencia` > 10)  
		data = subset(data,data$`acecol.nb.f1` < 0.2)  
		#data = data[data$`acecol.nb.f1` < 0.2,]
		data = subset(data,data$`lac.indice.de.dureza` > 0.75)
		
		data = data[c("acecol.c.f1", "lac.tb", "acecol.mn.f1", "lac.t.b.cola","lac.indice.de.dureza","lamesn.resistencia")]
				
		# Split
		set.seed(80)
		n <- nrow(data)
		shuffled_df <- data[sample(n), ]   # aca hago el shuffle
		train_indices <- 1:round(0.8 * n)
		train <- shuffled_df[train_indices, ]
		test_indices <- (round(0.8 * n) + 1):n
		test <- shuffled_df[test_indices, ]

		## Imputo
		
		library(imputeMissings)
		
		values<-compute(train)
		train<- impute(train)
		test<- impute(test,object = values)   # imputo con lo que aprendio
		

		## Escalo

		y_train = train$lamesn.resistencia
		y_test = test$lamesn.resistencia
		train = subset(train,select = -c(lamesn.resistencia))
		test = subset(test,select = -c(lamesn.resistencia))
		
		train = scale(train)
		

		#attr(,"scaled:center")
		#acecol.c.f1               lac.tb         acecol.mn.f1 
		#0.08425913         600.83163861           0.40327056 
		#lac.t.b.cola lac.indice.de.dureza 
		#606.91030519           1.19632975 
		#attr(,"scaled:scale")
		#acecol.c.f1               lac.tb         acecol.mn.f1 
		#0.04875744          37.04583384           0.24288377 
		#lac.t.b.cola lac.indice.de.dureza 
		#51.78397914           0.08968122 

		test = scale(test,center = c(0.08425913,600.83163861,0.40327056,606.91030519,1.19632975),scale = c(0.04875744,37.04583384,0.24288377,51.78397914,0.08968122))

		library("RevoScaleR")		
		
		train = as.data.frame(cbind(train,y_train))
		colnames(train)<- c( "acecol.c.f1","lac.tb","acecol.mn.f1","lac.t.b.cola", "lac.indice.de.dureza", "lamesn.resistencia")	

		#print(colnames(train))

		#model<- rxDForest( lamen~ acecol_c_f1 + lac_tb + acecol_mn_f1 + lac_t_b_cola + lac_indice_de_dureza, 
        #                  data = train)

		print("termino2")

		model<- rxDForest( lamesn.resistencia ~ acecol.c.f1 + lac.tb + acecol.mn.f1 + lac.t.b.cola + lac.indice.de.dureza, 
                          verbose = 0, data = train, reportProgress = 0)

		print("termino")
		
		trained_model<- as.raw(serialize(model, connection=NULL));
		pred<- rxPredict(model,as.data.frame(test),verbose = 0)

		dif = abs(pred-y_test)
		print(sum(dif < 20)/length(y_test))

'

    , @input_data_1 = N'select "lac grado", "acecol boro en f1", "acecol c f1" , "acecol mn f1" ,  "acecol nb f1" , "acecol ti f1", "acecol vanadio f1", "lamesn resistencia", "lac tb", "lac t b cola", "lac indice de dureza" from dbo.Datos where flia = ''cmn'''
    , @input_data_1_name = N'data'
    , @params = N'@trained_model varbinary(max) OUTPUT'
    , @trained_model = @trained_model OUTPUT;
END;


DECLARE @model VARBINARY(MAX);
EXEC dbo.Train_Resistencia_Revo @model OUTPUT;

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

create PROCEDURE [dbo].[Predict_Resistencia]   @model VARCHAR(100), @lac_grado float, @acecol_boro float,@acecol_c float ,@acecol_mn float,@acecol_nb float,@acecol_ti float,@acecol_vanadio float,@lac_tb float,@lac_t_b float,@lac_dureza float
AS
BEGIN
DECLARE @inquery nvarchar(max) = N'SELECT * FROM [dbo].[fnTableGen](@lac_grado, @acecol_boro,@acecol_c ,@acecol_mn,@acecol_nb,@acecol_ti,@acecol_vanadio,@lac_tb,@lac_t_b,@lac_dureza)';
DECLARE @rx_model VARBINARY(MAX) = (SELECT model FROM rental_rx_models_soft WHERE model_name = @model);

EXEC sp_execute_external_script  
	@language = N'R',
	@script = N'  
		require("RevoScaleR");
		data = InputDataSet;		
		data = as.data.frame(data)
		colnames(data) <- gsub(" ", ".", colnames(data), fixed = TRUE)	
	  
		data = subset(data,data$`acecol.nb.f1` < 0.2)  
		#data = data[data$`acecol.nb.f1` < 0.2,]
		data = subset(data,data$`lac.indice.de.dureza` > 0.75)
		
		family_type <- function(data){
  
		  if(((data["acecol.boro.en.f1"] >= 10) & (data["acecol.nb.f1"] <= 0.01) & 
			  (data["acecol.ti.f1"] <= 0.01) & (data["acecol.vanadio.f1"] <= 0.01)) |
			 ((data["acecol.boro.en.f1"] >= 10) & (data["acecol.nb.f1"] <= 0.01) & 
			  (data["acecol.ti.f1"] >= 0.01) & (data["acecol.vanadio.f1"] <= 0.01)) |
			 ((data["lac.grado"] == 7153) | (data["lac.grado"] == 9153) | 
			  (data["lac.grado"] == 7001) | (data["lac.grado"] == 9001) |
			  (data["lac.grado"] == 7002)))
			#{data["flia"] = "boro" }
			{out = "boro"}
		  else if(((data["acecol.nb.f1"] >= 0.01) & (data["acecol.ti.f1"] <= 0.01) & 
				(data["acecol.boro.en.f1"] <= 10) & (data["acecol.vanadio.f1"] <= 0.01)) ||
			   ((data["acecol.nb.f1"] >= 0.01) & (data["acecol.ti.f1"] >= 0.01) & 
				  (data["acecol.boro.en.f1"] <= 10) & (data["acecol.vanadio.f1"] >= 0.01)))
		  #{data["flia"] = "niobio"}
		  {out = "niobio"}

		  else if(((data["acecol.nb.f1"] <= 0.01) & (data["acecol.ti.f1"] <= 0.01) & 
				(data["acecol.boro.en.f1"] <= 10) & (data["acecol.vanadio.f1"] >= 0.01)))
		  #{data["flia"] = "vanadio"}
		  {out = "vanadio"}

		  else if(((data["acecol.nb.f1"] <= 0.01) & (data["acecol.ti.f1"] <= 0.01) & 
				(data["acecol.boro.en.f1"] <= 10) & (data["acecol.vanadio.f1"] <= 0.01)) |
			   ((data["acecol.nb.f1"] <= 0.01) & (data["acecol.ti.f1"] >= 0.01) & 
				  (data["acecol.boro.en.f1"] <= 10) & (data["acecol.vanadio.f1"] <= 0.01)))              
		  #{data["flia"] = "cmn"}
		  {out = "cmn"}

		  else if(!(is.na(data["acecol.nb.f1"]) | is.na(data["acecol.ti.f1"]) |
				 is.na(data["acecol.boro.en.f1"]) | is.na(data["acecol.vanadio.f1"])))
		  #{data["flia"] = "otros"}
		  {out = "otros"}

		return(out)
		#return (data)

		}

		data["flia"] = NaN
		data["flia"] = apply(data,1,family_type)		

		data = subset(data,data["flia"] == "cmn")
		data = data[c("acecol.c.f1", "lac.tb", "acecol.mn.f1", "lac.t.b.cola","lac.indice.de.dureza")]

		library(imputeMissings)
		data = scale(data,center = c(0.08425913,600.83163861,0.40327056,606.91030519,1.19632975),scale = c(0.04875744,37.04583384,0.24288377,51.78397914,0.08968122))
		library("xgboost")
		test = xgb.DMatrix(data = data)		
		
		rental_model = unserialize(rx_model);
		
        #Call prediction function
        rental_predictions = as.data.frame(predict(rental_model, test));		
	',  
	@input_data_1 = @inquery
	, @output_data_1_name = N'rental_predictions'
	,@params = N' @rx_model varbinary(max), @lac_grado float, @acecol_boro float,@acecol_c float ,@acecol_mn float,@acecol_nb float,@acecol_ti float,@acecol_vanadio float,@lac_tb float,@lac_t_b float,@lac_dureza float', @rx_model = @rx_model, @lac_grado = @lac_grado, @acecol_boro = @acecol_boro,@acecol_c = @acecol_c ,@acecol_mn = @acecol_mn,@acecol_nb = @acecol_nb,@acecol_ti = @acecol_ti,@acecol_vanadio = @acecol_vanadio,@lac_tb = @lac_tb,@lac_t_b = @lac_t_b,@lac_dureza = @lac_dureza  
	WITH RESULT SETS (([Resultado] float not null));
END;

-------  Productivo  --------
--------------------------

-- Entreno --

IF not EXISTS (select * from sysobjects where name='rental_rx_models_soft' and xtype='U')
begin
	CREATE TABLE rental_rx_models_soft (
                model_name VARCHAR(30) NOT NULL DEFAULT('default model') PRIMARY KEY,
                model VARBINARY(MAX) NOT NULL)
end	

-- Save model to table   

DECLARE @model VARBINARY(MAX);
EXEC dbo.Train_Resistencia_Revo @model OUTPUT;

IF NOT EXISTS(select * from rental_rx_models_soft where model_name='soft_model')
   INSERT INTO rental_rx_models_soft (model_name, model) VALUES('soft_model', @model);
ELSE
	update dbo.rental_rx_models_soft set model=  @model where model_name= 'soft_model';

SELECT * FROM rental_rx_models_soft;

-- Predict
exec [Predict_Resistencia] @model = 'soft_model', @lac_grado = 7055, @acecol_boro = 1,@acecol_c = 0.16 ,@acecol_mn = 0.8 ,@acecol_ti = 0.0012, @acecol_nb = 0.0015, @acecol_vanadio = 0.0033, @lac_tb = 635,@lac_t_b = 669.5714,@lac_dureza = 1.232346
