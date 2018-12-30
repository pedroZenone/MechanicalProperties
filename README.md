# Mechanical Properties

This was a very funny project, It remaindes my of my machine learning classes where you only had to just transform a little your dataset and apply a model. The funny thing here was the use case, predict the mechanical properties of iron coils at the end of the industrial process, and the problem was the deployment of the model.

- Train_xgboost.py: After feature engineering this script takes it as input and train the xgboost model. The pipeline is servered for the deployment.

- ML_Services2017: In the deplyment stage, one possible aproach could be use DB servers to deploy the model (I recommend this one, train stage isn't the best) and load the result to a table, it's all there!

- Cloud: Another possibility would be to train and serve the model in the cloud. In this folder you will find a readme that explains the steps to train and then deploy the model with flask. The cloud is Floydhub, it's in the middle of PaaS and SaaS because it has a EC2 allready configurated.
