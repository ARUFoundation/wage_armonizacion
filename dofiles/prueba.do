clear all 

********************************************************************************
************* 			INDICADORES GINI Y POBREZA                 *************
********************************************************************************

use "D:\Encuestas Hogares\Encuesta de Hogares 2021\EH2021_Persona.dta"
*use "D:\Encuestas Hogares\Encuesta de Hogares 2020\EH2020_Persona.dta"


*Pobreza por departamento: 
bys depto: sum p0 [w=factor]

*Gini por departamento:
ineqdeco yhogpc [w=factor], by(depto)
ineqdeco yhogpc [w=factor]
