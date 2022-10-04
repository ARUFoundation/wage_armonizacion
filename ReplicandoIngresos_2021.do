clear all 

********************************************************************************
************* 			REPLICANDO INDICADORES INE                 *************
********************************************************************************

use "D:\Encuestas Hogares\Encuesta de Hogares 2021\EH2021_Persona.dta"
global year 2021
global do "D:\ARU\Armonización EH\Replica_2021\Replica_y_INE\do"
global temp "D:\ARU\Armonización EH\Replica_2021\Replica_y_INE\temp"

*******************************************************************

gen year="$year"

*UPM
capture drop iupm
rename upm iupm

*HOUSEHOLD ID 
preserve
keep  folio iupm
capture drop _aux
bysort iupm folio:  gen _aux = _n
drop if _aux>1
gen _count = _n
tempfile temp1
save "`temp1'"
restore

merge m:m folio using "`temp1'"  

tostring _count, replace
replace _count="0000"+_count if length(_count)==1
replace _count="000"+_count if length(_count)==2
replace _count="00"+_count if length(_count)==3
replace _count="0"+_count if length(_count)==4

capture drop id_hh
gen id_hh = year+ _count+ "0" +string(depto)+ estrato
destring year, replace

*WEIGHTS
capture drop factor_ine
rename factor factor_ine

* NRO DE PERSONAS
capture drop noper
bysort folio: gen noper=_N

* EDAD
capture drop edad
gen edad= s01a_03

* PARENTCO: Relacion jefe del hogar
capture drop parentco
gen parentco =s01a_05 
recode parentco 1=1 2=2 3=3 4/9=4 10=5 11/12=9 *=.					

* HOUSEHOLD MEMBER  
note: No considera empleados o parientes de empleados como miembros del hogar
capture drop hhmember
gen byte hhmember=(parentco>=1 & parentco<=5)
				
* FAMILY SIZE //tamaño del hogar, 
note: hhtotal no contabiliza a personas del servicio domestico dentro de la vivienda
capture drop hhtotal
egen hhtotal=sum(hhmember), by(folio)

* PERSON ID - within the household
capture drop id_person
gen id_person=nro

* RURAL==1
capture drop rural
gen rural=(area==2)	


******************************************************************
 capture drop aa
 gen aa=s04a_01		//Q: durante la semana pasada, ¿trabajó al menos una hora?
 capture drop bb
 gen bb=s04a_02		//Q. durante la semana pasada, dedicó al menos una hora a: otros trabajos remunerados
 recode bb 			1/2=1 3=2 4=3 5=4 6=5 7=6 8=7
 capture drop ccc
 gen ccc=s04a_03	//Q. ¿la semana pasada, tuvo algún empleo, negocio o empresa propia al cual no asistio por enfermedad, u otro.		
 
*** PO
*** EMPLOYED                                                             	       
 capture drop emppri
 gen byte emppri=0 				
 replace  emppri=1 if aa==1
 replace  emppri=1 if aa==2 & (bb>=1 & bb<=6)					
 replace  emppri=1 if aa==2 &  bb==7 & (ccc>=1 & ccc<=9)

*** Asalariado
 capture drop salaried
 gen     salaried=0
 replace salaried=1   if emppri==1 & (s04b_12==1 | s04b_12==2  | s04b_12==7)
 **recode** **************************************************************
 recode  salaried *=. if emppri~=1

 
******************************************************************
*		INGRESOS
******************************************************************

*-----------------------------
*INGRESOS ACTIVIDAD PRINCIPAL
*-----------------------------

*ASALARIADOS
note: f(income) controls for "days worked in last week" but asumes full employment in other freqs.
do "$do/fincome.do"	

*Ingreso liquido en horario normal
fincome s04c_17b, by(s04b_15)
capture drop ysal1net
gen ysal1net=.
replace ysal1net=s04c_17a*freq

*----------------------
*INGRESOS EXTRAS - ASALARIADO- ACTIVIDAD PRINCIPAL
*----------------------

*1. Prima de producción mensualizado
capture drop ysal1ben_1
gen ysal1ben_1=s04c_18a/12

*2. Aguinaldo mensualizado
capture drop ysal1ben_2
gen ysal1ben_2=s04c_18b/12

*3. Comisiones
fincome s04c_19ab,  by(s04b_15)	
capture drop ysal1ben_3
gen ysal1ben_3=.
replace ysal1ben_3=s04c_19aa*freq

*4. Horas Extra
fincome s04c_19bb, by(s04b_15)
capture drop ysal1ben_4
gen ysal1ben_4=.
replace ysal1ben_4=s04c_19ba*freq

*5. Subsidio de lactancia mensualizado
capture drop ysal1ben_5
gen ysal1ben_5=(2000*s04c_20a2)/12 if s04c_20a1==1	

*Salario mínimo 2021
gen salmin=2164 

*6. Bono de natalidad
capture drop ysal1ben_6
gen ysal1ben_6=salmin/12 if s04c_20b==1

*Sumatoria de ingresos extra
*egen ysal1ben=rsum(ysal1ben_1 ysal1ben_2 ysal1ben_3 ysal1ben_4 ysal1ben_5 ysal1ben_6),m
*Prueba:
egen ysal1ben=rsum(ysal1ben_1 ysal1ben_2 ysal1ben_4 ysal1ben_5 ysal1ben_6),m

*----------------------
* INGRESOS EN ESPECIE - ASALARIADO - ACTIVIDAD PRINCIPAL
*----------------------			

*1. Alimentos
fincome s04c_21a1, by(s04b_15)	
gen  ysal1esp_1=s04c_21a2*freq

*2. Transporte
fincome s04c_21b1, by(s04b_15)		
gen ysal1esp_2=s04c_21b2*freq

*3. Vestidos y Calzado
fincome s04c_21c1, by(s04b_15)	
gen ysal1esp_3=s04c_21c2*freq

*4. Vivienda
fincome s04c_21d1, by(s04b_15)	
gen ysal1esp_4=s04c_21d2*freq

*5. Otros
fincome s04c_21e1, by(s04b_15)	
gen ysal1esp_5=s04c_21e2*freq

*Sumatoria de ingresos en especie
egen ysal1esp=rsum(ysal1esp_1 ysal1esp_2 ysal1esp_3 ysal1esp_4 ysal1esp_5),m

*----------------------
* INGRESOS CUENTA PROPIA (TRABAJADOR INDEPENDIENTE)- ACTIVIDAD PRINCIPAL
*----------------------

*Total Ingresos
fincome s04d_22b, by(s04b_15)
capture drop yind1tot
gen yind1tot=.
replace  yind1tot=s04d_22a*freq

* Ingreso Neto T.I.
fincome s04d_24b, by(s04b_15)		
capture drop yind1net
gen yind1net=.
replace yind1net=s04d_24a*freq

*----------------------
* INGRESO LABORAL - ACTIVIDAD PRINCIPAL
*----------------------

capture drop yprijb
egen yprijb=rsum(ysal1net ysal1ben ysal1esp), m

replace yprijb=yind1net					if s04b_12==3 | s04b_12==4 | s04b_12==5
replace yprijb=0						if s04b_12==6

*twoway (kdensity yprijb_2) (kdensity yprilab)

*-----------------------------
*INGRESOS ACTIVIDAD SECUNDARIA
*-----------------------------

*ASALARIADO
* Ingreso liquido en horario normal
fincome s04f_31b, by(s04e_29)							
capture drop ysal2net
gen ysal2net=.
replace ysal2net=s04f_31a*freq

* Ingreso extra 
gen ysal2ben=s04f_32a1/12

* Ingreso en especie

*1. Alimentos/Transporte/Vestidos y calzados
gen ysal2esp_a=s04f_32b1/12

*2. Vivienda/Otros
gen ysal2esp_b=s04f_32c1/12

* INGRESO EN ESPECIE TOTAL
egen ysal2esp=rsum(ysal2esp_a ysal2esp_b),m

*CUENTA PROPIA

*Ingreso Total
fincome s04f_33b, by(s04e_29)	
recode s04f_33a *=. if s04f_33a>=880000 | s04d_25~=1	
capture drop yind2tot
gen yind2tot=.
replace  yind2tot=s04f_33a*freq

*Ingreso Neto
fincome s04f_34b  , by(s04e_29)
recode s04f_34a *=. if s04f_34a>=880000
capture drop yind2net
gen yind2net=s04f_34a*freq

*----------------------
* INGRESO LABORAL - ACTIVIDAD SECUNDARIA
*----------------------
capture drop ysecjb
egen ysecjb=rsum(ysal2net ysal2ben ysal2esp),m 

replace ysecjb=yind2net		if s04e_27==3 | s04e_27==4 | s04e_27==5
replace ysecjb=0			if s04e_27==6

*PARA CONCUASAR CON EL INE:
*Lidiando con 0s:
replace yprijb=. if yprijb==0
replace ysecjb=. if ysecjb==0 

*twoway (kdensity ysecjb_2) (kdensity yseclab)

*-----------------------------
*INGRESOS LABORAL TOTAL
*-----------------------------
egen yalljb=rsum(yprijb ysecjb),m
*egen yalljb_2=rsum(yprijb_2 ysecjb_2),m

*-----------------------------
* HOUSEHOLD TOTAL LABOR INCOME
*-----------------------------
capture drop hhyjb*
egen hhyjb=sum(yalljb) if hhmember==1, by (folio)
*egen hhyjb_2=sum(yalljb_2) if hhmember==1, by (folio)

*-------------------------------
* TOTAL LABOR INCOME PER-CAPITA
*-------------------------------
capture drop ypcjb*
gen ypcjb=hhyjb/hhtotal
*gen ypcjb_2=hhyjb_2/hhtotal

*-----------------------------
*INGRESOS NO-LABORALES
*-----------------------------

*Bono Indigencia por Ceguera (IBC):
cap drop spibc spibc_monto
gen spibc=s02a_15
gen spibc_monto=s02a_15a
replace spibc_monto=s02a_15a/12  if s02a_15b==8


*Bono Contra el Hambre
capture drop bhambre
gen bhambre=1000 if s05b_06a==1

*Recodes para errores
for varlist s05a_01a s05a_01b s05a_01c s05a_01d s05a_01e0: 		recode X *=. if X>=880000  				/*jubila, etc*/	
for varlist s05a_02a s05a_02b s05a_02c: 				recode X *=. if X>=880000          				/*rentas*/		
for varlist s05a_03a s05a_03b s05a_03c: 				recode X *=. if X>=880000          				/*renta capi*/ 	
for varlist s05a_04a s05a_04b s05a_04c s05a_04d: 				recode X *=. if X>=880000  				/*ing.extraor*/ 
for varlist s05b_05aa s05b_05ba s05b_05ca s05b_07aa s05b_07ba:	recode X *=. if X>=880000               /*tranf.o.h*/	
for varlist s05c_10a:			 			recode X *=. if X>=880000          				/*remesas*/		

capture drop aux*
fincome s05b_05ab
gen aux33=s05b_05aa*freq

fincome s05b_05bb
gen aux55=s05b_05ba*freq

fincome s05b_05cb
gen aux66=s05b_05ca*freq

fincome s05b_07ab
gen aux67=s05b_07aa*freq

fincome s05b_07bb
gen aux68=s05b_07ba*freq

capture drop aux69
gen aux69=bhambre/12

*** Mensualizando                                                     				
for varlist s05a_03a s05a_03b s05a_03c: replace X =X/12                   	
for varlist s05a_04a s05a_04b s05a_04c s05a_04d: replace X =X/12

*ADO de Tipo de cambio 
do "$do/exchange_rate.do"
fincome s05c_09
capture drop aux77 aux88
gen aux77=s05c_10a*freq     if s05c_10b==1    /*remesas*/		
gen aux88=s05c_12*freq  /*en especie*/

replace aux77=s05c_10a*freq*tc  if s05c_10b==3	//$us
replace aux77=s05c_10a*freq*tc2 if s05c_10b==2  //euros
replace aux77=s05c_10a*freq*tc3 if s05c_10b==4	//pesos argentinos
replace aux77=s05c_10a*freq*tc4 if s05c_10b==5	//reales
replace aux77=s05c_10a*freq*tc5 if s05c_10b==6	//pesos chilenos
replace aux77=s05c_10a*freq*tc6 if s05c_10b==7 & s05c_10e=="SOLES"  //soles

* Income from social security *
note: sin renta dignidad
capture drop ysstot
egen ysstot=rsum(s05a_01a s05a_01b s05a_01c s05a_01d),m

* Income from property *
capture drop yprotot
egen yprotot=rsum(s05a_02a s05a_02b s05a_02c s05a_03a s05a_03b s05a_03c),m

* Intra-household transfers *
capture drop ytrh_*
gen ytrh_1=aux33
gen ytrh_2=aux55 
gen ytrh_4=aux66
gen ytrh_5=aux67
gen ytrh_6=aux68
egen ytrh_3=rowtotal(aux77 aux88), m 
gen ytrh_7=aux69 // Solo para 2021 por el Bono contra el hambre

capture drop ytrhtot
capture drop ytrhtot_2021
egen ytrhtot=rsum(ytrh_1 ytrh_2 ytrh_3 ytrh_4 ytrh_5 ytrh_6),m
egen ytrhtot_2021=rsum(ytrh_1 ytrh_2 ytrh_3 ytrh_4 ytrh_5 ytrh_6 ytrh_7),m

* Goverment transfers *
capture drop ytrgtot
egen ytrgtot=rsum(s05a_01e0),m // only renta dignidad in this case

*invalidez (mensual)
capture drop spdis /*Q: Recibe usted ingresos (rentas) mensuales por: Invalidez? */
gen spdis = (s05a_01c > 1 ) if s05a_01c != .
capture drop spdis_monto
gen spdis_monto = s05a_01c

*----------------------------
*BJA < controles prenatales >
*-----------------------------
capture drop spbja /* BJA: su ultimo se inscribio... ? */
gen spbja =  (s02b_23 == 1) if s02b_23 != .

capture drop spbja_monto
capture drop aux1
gen aux1 = s02b_24a2 * 50
capture drop aux2
gen aux2 = 125 if s02b_24b == 1
egen spbja_monto = rowtotal(aux1 aux2) /* S4 16. En los �ltimos 12 meses, cu�nto dinero ha cobrado �por los controles real */

*					-  postnatal  -
*BJA < controles post parto "bimestrales" >

capture drop spbja_b /*BJA: controles bimestrales */
gen spbja_b = (s02c_29 ==1 ) if s02c_29 !=.

capture drop spbja_bmonto
gen spbja_bmonto = s02c_30a * 125   /* 125 bs por cada control post parto */
replace spbja_bmonto = 0 if spbja_bmonto ==. & spbja_b == 0

*Subsidio (300)
capture drop spprenat_q
gen sppren_q = s02b_26a*300

*BONO JUANCITO PINTO

capture drop spbjp
gen spbjp = (s03a_08 == 1) if  s03a_08 !=.

*Total BJA:
egen bja_tot=rsum(spbja_bmonto spbja_monto sppren_q)
gen bja_m=bja_tot/12

* Other non labor income *
capture drop yothtot
egen yothtot=rsum(s05a_04a s05a_04b s05a_04c s05a_04d),m

* TOTAL
capture drop ynonjb
capture drop ynonjb_2021
*egen ynonjb=rsum(yprotot ysstot ytrhtot ytrgtot yothtot),m
*egen ynonjb_2021=rsum(yprotot ysstot ytrhtot_2021 ytrgtot yothtot),m

*Prueba 1:
egen ynonjb=rsum(yprotot ysstot ytrhtot_2021 ytrgtot bja_m),m
*egen ynonjb_3=rsum(yprotot ysstot ytrhtot_2021 ytrgtot yothtot bja_m),m


*** HOUSEHOLD TOTAL OTHER NON LABOR INCOME (not dependent of the nonresponse)
local varnames "yprotot ysstot ytrhtot ytrgtot yothtot ynonjb"
foreach x of local varnames {
capture drop hh`x'
egen hh`x'=sum(`x') if hhmember==1, by (folio)
}
	
*** TOTAL OTHER NON-LABOR INCOME PER-CAPITA
capture drop ypcnonjb
gen ypcnonjb=hhynonjb/hhtotal


*-----------------------------
*INGRESOS TOTALES
*-----------------------------

capture drop hhytot*
egen hhytot=rsum(hhyjb hhynonjb) if hhmember==1,m
*egen hhytot=rsum(hhyjb_2 hhynonjb_2) if hhmember==1,m


*Total per-cápita
capture drop ypctot*
gen ypctot=hhytot/hhtotal

*RENAMING VARIABLES
rename yprilab ine_yprilab
rename yseclab ine_yseclab
rename ylab ine_ylab
rename ynolab ine_ynolab
rename yper ine_yper
rename yhog ine_yhog
rename yhogpc ine_yhogpc
rename z z
rename zext zext
rename p0 ine_p0
rename p1 ine_p1
rename p2 ine_p2
rename pext0 ine_pext0
rename pext1 ine_pext1
rename pext2 ine_pext2

keep ine_* y* hh* z* folio factor_ine noper edad parentco rural id_person sp* bja_m id_hh
save "$temp\eh$year(per)income.dta", replace