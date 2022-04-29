# XGBoost  sabor tradicional ,  cambiando algunos de los parametros

#limpio la memoria
rm( list=ls() )  #remove all objects
gc()             #garbage collection

require("data.table")
require("xgboost")
require("yaml")

PARAM <- real_yaml(archivo)

# PARAM$ambiente$CARPETA_TRABAJO <- "C:\\Users\\Julieta\\OneDrive\\MCD\\segundo_año\\Laboratorio_de_Implementacion_I"
# PARAM$problema$POSITIVOS <- c("BAJA+1","BAJA+2")
# PARAM$kaggle$PROBCORTE <- 0.0160870076191375
# 
# PARAM$xgboost$NROUNDS <- 40
# PARAM$xgboost$MIN_CHILD_WEIGHT <- 20

#Aqui se debe poner la carpeta de la computadora local
setwd(CARPETA_TRABAJO)   #Establezco el Working Directory

#cargo el dataset donde voy a entrenar
dataset  <- fread("./datasets/paquete_premium_202011.csv", stringsAsFactors= TRUE)


#paso la clase a binaria que tome valores {0,1}  enteros
dataset[ , clase01 := ifelse( clase_ternaria %in% POSITIVOS, 1L, 0L) ]

#los campos que se van a utilizar
campos_buenos  <- setdiff( colnames(dataset), c("clase_ternaria","clase01") )


#dejo los datos en el formato que necesita XGBoost
dtrain  <- xgb.DMatrix( data= data.matrix(  dataset[ , campos_buenos, with=FALSE]),
                        label= dataset$clase01 )

#genero el modelo con los parametros por default
modelo  <- xgb.train( data= dtrain,
                      param= list( objective=       "binary:logistic",
                                   max_depth=           4,
                                   min_child_weight=    MIN_CHILD_WEIGHT),
                      nrounds= NROUNDS
                    )

#aplico el modelo a los datos sin clase
dapply  <- fread("./datasets/paquete_premium_202101.csv")

#aplico el modelo a los datos nuevos
prediccion  <- predict( modelo, 
                        data.matrix( dapply[, campos_buenos, with=FALSE ]) )


#Genero la entrega para Kaggle
entrega  <- as.data.table( list( "numero_de_cliente"= dapply[  , numero_de_cliente],
                                 "Predicted"= prediccion > PROBCORTE)  ) #genero la salida

# entrega  <- as.data.table( list( "numero_de_cliente"= dapply[  , numero_de_cliente],
#                                  "Predicted"= prediccion)  ) #genero la salida
# 
# setorder(entrega, -Predicted) #ordeno por probabilidad
# 
# entrega[,Predicted:= 0]
# entrega[1:14000, Predicted:= 1]     

dir.create( "./labo/exp/",  showWarnings = FALSE ) 
dir.create( "./labo/exp/KA2552/", showWarnings = FALSE )
archivo_salida  <- "./labo/exp/KA2552/KA_552_003.csv"

#genero el archivo para Kaggle
fwrite( entrega, 
        file= archivo_salida, 
        sep= "," )
