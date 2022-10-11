clear all 

********************************************************************************
*************		REPLICANDO INDICADORES INE 2013                *************
********************************************************************************

use "D:\Encuestas Hogares\Encuesta de Hogares 2013\eh_2013_persona.dta"
global year 2013
global do "D:\ARU\Armonización EH\Replica_2021\Replica_y_INE\do"
global temp "D:\ARU\Armonización EH\Replica_2021\Replica_y_INE\temp"

*******************************************************************

gen year="$year"

*UPM
capture drop iupm
rename upm iupm

* DEPARTAMENTO
capture drop idep
gen idep = id01 
destring idep, replace

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
gen id_hh = year+ _count+ "0" +string(idep)+ estrato
destring year, replace

*WEIGHTS
capture drop factor_ine
rename FACTOR factor_ine

* NRO DE PERSONAS
capture drop noper
bysort folio: gen noper=_N

* EDAD
capture drop edad
gen edad= s2_03

* PARENTCO: Relacion jefe del hogar
capture drop parentco
gen parentco =s2_05 
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

*-----------------------
*** BONO JUANA AZURDUY
*-----------------------

*					-  prenatal  -
*BJA < controles prenatales >
capture drop spbja /* BJA: su ultimo se inscribio... ? */
gen spbja =  (s4_17a == 1) if s4_17a  != .

capture drop spbja_monto
gen spbja_monto = s4_17b /* S4 16. En los �ltimos 12 meses, cu�nto dinero ha cobrado �por los controles real */

capture drop spbja_b /*BJA: controles bimestrales */
gen spbja_b = (s4_08a ==1 ) if s4_08a !=.

capture drop spbja_bmonto
gen spbja_bmonto = s4_08b    /* 125 bs por cada control post parto */

*subsidio
capture drop spprenat_q
gen sppren_q = . // A partir de 2015


*BONO JUANCITO PINTO

capture drop spbjp
gen spbjp = (s5_08 == 1) if  s5_08 !=.
replace spbjp = . if s5_08 == 9 


******************************************************************
 capture drop aa
 gen aa=s6_01	//Q: durante la semana pasada, ¿trabajó al menos una hora?
 capture drop bb
 gen bb=s6_02	//Q. durante la semana pasada, dedicó al menos una hora a: otros trabajos remunerados
 capture drop ccc
 gen ccc=s6_03	//Q. ¿la semana pasada, tuvo algún empleo, negocio o empresa propia al cual no asistio por enfermedad, u otro.		
 
*** PO
*** EMPLOYED                                                             	       
 capture drop emppri
 gen byte emppri=0 				
 replace  emppri=1 if aa==1
 replace  emppri=1 if aa==2 & (bb>=1 & bb<=6)					
 replace  emppri=1 if aa==2 &  bb==7 & (ccc>=1 & ccc<=7)

*** Asalariado
 capture drop salaried
 gen     salaried=0
 replace salaried=1   if emppri==1 & (s6_16==1 | s6_16==2 | s6_16==4  | s6_16==8)
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
fincome s6_25b, by(s6_22)	
recode  s6_25a *=. if s6_25a>=880000
capture drop ysal1net
gen ysal1net=.
replace ysal1net=s6_25a*freq

*----------------------
*INGRESOS EXTRAS - ASALARIADO- ACTIVIDAD PRINCIPAL
*----------------------

*1. Prima de producción mensualizado
recode s6_26a *=. if s6_26a>=880000	
capture drop ysal1ben_1
gen ysal1ben_1=s6_26a/12

*2. Aguinaldo mensualizado
recode s6_26b *=. if s6_26b>=880000				
capture drop ysal1ben_2
gen ysal1ben_2=s6_26b/12

*3. Comisiones
fincome s6_27a2, by(s6_22)				
recode s6_27a1 *=. if s6_27a1>=880000	
capture drop ysal1ben_3
gen ysal1ben_3=.
replace ysal1ben_3=s6_27a1*freq  

*4. Horas Extra
fincome s6_27b2, by(s6_22)	
recode s6_27b1 *=. if s6_27b1>=880000		
capture drop ysal1ben_4
gen ysal1ben_4=.
replace ysal1ben_4=s6_27b1*freq

***SALARIO MINIMO
do "$do\salario_minimo.do"

*5. Subsidio de lactancia mensualizado
capture drop ysal1ben_5
gen ysal1ben_5=(salmin*s6_28a2)/12

*6. Bono de natalidad
capture drop ysal1ben_6
gen ysal1ben_6=salmin/12 		if s6_28b==1

*Sumatoria de ingresos extra
egen ysal1ben=rsum(ysal1ben_1 ysal1ben_2 ysal1ben_4 ysal1ben_5 ysal1ben_6),m
*egen ysal1ben=rsum(ysal1ben_1 ysal1ben_2 ysal1ben_3 ysal1ben_4 ysal1ben_5 ysal1ben_6),m

*----------------------
* INGRESOS EN ESPECIE - ASALARIADO - ACTIVIDAD PRINCIPAL
*----------------------			

*1. Alimentos
fincome s6_30a2, by(s6_22)	
recode s6_30a3 *=. if s6_30a3>=880000 
gen  ysal1esp_1=s6_30a3*freq

*2. Transporte
fincome s6_30b2, by(s6_22)
recode s6_30b3 *=. if s6_30b3>=880000
gen ysal1esp_2=s6_30b3*freq

*3. Vestidos y Calzado
fincome s6_30c2, by(s6_22)
recode s6_30c3 *=. if s6_30c3>=880000
gen ysal1esp_3=s6_30c3*freq

*4. Vivienda
fincome s6_30d2, by(s6_22)
recode s6_30d3 *=. if s6_30d3>=880000
gen ysal1esp_4=s6_30d3*freq

*5. Otros
fincome s6_30e2, by(s6_22)
recode s6_30e3 *=. if s6_30e3>=880000
gen ysal1esp_5=s6_30e3*freq

*Sumatoria de ingresos en especie
egen ysal1esp=rsum(ysal1esp_1 ysal1esp_2 ysal1esp_3 ysal1esp_4 ysal1esp_5),m

*----------------------
* INGRESOS CUENTA PROPIA (TRABAJADOR INDEPENDIENTE)- ACTIVIDAD PRINCIPAL
*----------------------

*Total Ingresos
fincome s6_31b, by(s6_22)				
recode s6_31a *=. if s6_31a>=880000
capture drop yind1tot
gen yind1tot=.
replace  yind1tot=s6_31a*freq

* Ingreso Neto T.I.
fincome s6_33b, by(s6_22)
recode s6_33a *=. if s6_33a>=880000
capture drop yind1net
gen yind1net=.
replace yind1net=s6_33a*freq

capture drop yind1fin
gen yind1fin=yind1net  	

*----------------------
* INGRESO LABORAL - ACTIVIDAD PRINCIPAL
*----------------------

capture drop yprijb
egen yprijb=rsum(ysal1net ysal1ben ysal1esp), m

replace yprijb=yind1net					if s6_16==3 | s6_16==5 | s6_16==6
replace yprijb=0						if s6_16==7

*-----------------------------
*INGRESOS ACTIVIDAD SECUNDARIA
*-----------------------------

*ASALARIADO
* Ingreso liquido en horario normal
fincome s6_41b, by(s6_39a)				
recode  s6_41a *=. if s6_41a>=80000
capture drop ysal2net
gen ysal2net=.
replace ysal2net=s6_41a*freq

* Ingreso extra 
*a* Ingreso por horas extras/ bono/ aguinaldo
recode s6_42a2 *=. if s6_42a2>=880000											
capture drop ysal2ben_a
gen ysal2ben_a=s6_42a2/12

*b* subsidio de lactancia/bono de natalidad
capture drop ysal2ben_b
gen ysal2ben_b=.

egen ysal2ben=rsum(ysal2ben_a ysal2ben_b),m

* Ingreso en especie

*1. Alimentos/Transporte/Vestidos y calzados
recode s6_42b2 *=. if s6_42b2>=880000
gen ysal2esp_a=s6_42b2/12

*2. Vivienda/Otros
recode s6_42c2 *=. if s6_42c2>=880000
gen ysal2esp_b=s6_42c2/12

* INGRESO EN ESPECIE TOTAL
egen ysal2esp=rsum(ysal2esp_a ysal2esp_b),m

*CUENTA PROPIA

*Ingreso Total
fincome s6_43b, by(s6_39a)
recode s6_43a *=. if s6_43a>=880000
capture drop yind2tot
gen yind2tot=.
replace  yind2tot=s6_43a*freq

*Ingreso Neto
fincome s6_45b, by(s6_39a)
recode s6_45a *=. if s6_45a>=880000
capture drop yind2net
gen yind2net=s6_45a*freq

capture drop yindfin
gen yindfin=yind2net  

*----------------------
* INGRESO LABORAL - ACTIVIDAD SECUNDARIA
*----------------------
capture drop ysecjb
egen ysecjb=rsum(ysal2net ysal2ben ysal2esp),m 

replace ysecjb=yindfin		if s6_36==3 | s6_36==5 | s6_36==6
replace ysecjb=0			if s6_36==7

*Lidiando con 0s:
replace yprijb=. if yprijb==0
replace ysecjb=. if ysecjb==0 

*-----------------------------
*INGRESOS LABORAL TOTAL
*-----------------------------
egen yalljb=rsum(yprijb ysecjb),m

*-----------------------------
* HOUSEHOLD TOTAL LABOR INCOME
*-----------------------------
capture drop hhyjb*
egen hhyjb=sum(yalljb) if hhmember==1, by (folio)

*-------------------------------
* TOTAL LABOR INCOME PER-CAPITA
*-------------------------------
capture drop ypcjb
gen ypcjb=hhyjb/hhtotal

*-----------------------------
*INGRESOS NO-LABORALES
*-----------------------------
cap drop spibc spibc_monto
gen spibc=.
gen spibc_monto=.

*** OTHER MONETARY NON LABOR INCOME
for varlist s7_01a s7_01b s7_01c s7_01d s7_01eb: 		recode X *=. if X>=880000   /*jubila, etc*/	
for varlist s7_02a s7_02b s7_02c: 				recode X *=. if X>=880000           /*rentas*/		
for varlist s7_03a s7_03b s7_03c: 				recode X *=. if X>=880000           /*renta capi*/ 	
for varlist s7_04a s7_04b s7_04c: 				recode X *=. if X>=880000           /*ing.extraor*/ 
for varlist s7_05a1 s7_05b1 :		 			recode X *=. if X>=880000           /*tranf.o.h*/	
for varlist s7_09a s7_10:			 			recode X *=. if X>=880000 	//	            /*remesas*/		
                                                                                    				
*** Annualizing and converting to Bs.                                               				
for varlist s7_03a s7_03b s7_03c: 		replace X =X/12                             /*remesas*/		
for varlist s7_04a s7_04b s7_04c:	 	replace X =X/12 

capture drop aux*
fincome s7_05a2
gen aux33=s7_05a1*freq

fincome s7_05b2
gen aux55=s7_05b1*freq

fincome s7_07
capture drop aux77 aux88
gen aux77=s7_09a*freq     if s7_09b=="A"  /*remesas*/		
gen aux88=s7_10*freq                      /*en especie*/	
		

do "$do/exchange_rate"


replace aux77=s7_09a*freq*tc  if s7_09b=="C"	//$us
replace aux77=s7_09a*freq*tc2 if s7_09b=="B"	//euros
replace aux77=s7_09a*freq*tc3 if s7_09b=="D"	//pesos argentinos
replace aux77=s7_09a*freq*tc4 if s7_09b=="E"	//reales
replace aux77=s7_09a*freq*tc5 if s7_09b=="F"	//pesos chilenos
*replace aux77=s7_09a*freq*tc6 if  s7_09b=="G" & s7_08e=="PERU"	//soles
				
* Income from social security *
note: sin renta dignidad
capture drop ysstot
egen ysstot=rsum(s7_01a s7_01b s7_01c s7_01d),m

* Income from property *
capture drop yprotot
egen yprotot=rsum(s7_02a s7_02b s7_02c s7_03a s7_03b s7_03c),m

* Intra-household transfers *
capture drop ytrh_*
gen ytrh_1=aux33
gen ytrh_2=aux55 //cambio la pregunta resp 2013
egen ytrh_3=rowtotal(aux77), miss //sin aux88!!!

note: se incluyeron las remesas en Intra-household transfers 

capture drop ytrhtot
egen ytrhtot=rsum(ytrh_1 ytrh_2 ytrh_3),m

* Goverment transfers *
capture drop ytrgtot
egen ytrgtot=rsum(s7_01eb),m // only renta dignidad in this case

* Other non labor income *
capture drop yothtot
egen yothtot=rsum(s7_04a s7_04b s7_04c) ,m					//UDAPE no lo toma en cuenta 

* TOTAL
*capture drop ynonjb
*egen ynonjb=rsum(yprotot ysstot ytrhtot ytrgtot ),m

*Total BJA:
egen bja_tot=rsum(spbja_bmonto spbja_monto sppren_q)
gen bja_m=bja_tot/12

*Prueba 1:
egen ynonjb=rsum(yprotot ysstot ytrhtot ytrgtot bja_m),m

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


*Total per-cápita
capture drop ypctot*
gen ypctot=hhytot/hhtotal 

* Just for harmonizing
gen yprilab=.
gen yseclab=.


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