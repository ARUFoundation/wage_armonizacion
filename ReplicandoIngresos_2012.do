clear all 

********************************************************************************
*************		REPLICANDO INDICADORES INE 2012                *************
********************************************************************************

use "D:\Encuestas Hogares\Encuesta de Hogares 2012\eh_2012_persona.dta"
global year 2012
global do "D:\ARU\Armonización EH\Replica_2021\Replica_y_INE\do"
global temp "D:\ARU\Armonización EH\Replica_2021\Replica_y_INE\temp"

*******************************************************************

gen year="$year"

*UPM
capture drop iupm
rename upm iupm

* DEPARTAMENTO
capture drop idep
gen idep = departamento 
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
gen edad= s1_04

* PARENTCO: Relacion jefe del hogar
capture drop parentco
gen parentco =s1_08 
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
gen spbja =  (s3_20a == 1) if s3_20a  != .

capture drop spbja_monto
gen spbja_monto = s3_20b /* En los 12 meses, cu�nto dinero ha cobrado �por los controles real */

capture drop spbja_b /*BJA: controles bimestrales */
gen spbja_b = (s3_12a ==1 ) if s3_12a !=.

capture drop spbja_bmonto
gen spbja_bmonto = s3_12b     /* 125 bs por cada control post parto */

*subsidio
capture drop spprenat_q
gen sppren_q = . // A partir de 2015


*BONO JUANCITO PINTO

capture drop spbjp
gen spbjp = (s4_08 == 1) if  s4_08 !=.


******************************************************************
 capture drop aa
 gen aa=s5_01	//Q: durante la semana pasada, ¿trabajó al menos una hora?
 capture drop bb
 gen bb=s5_02	//Q. durante la semana pasada, dedicó al menos una hora a: otros trabajos remunerados
 capture drop ccc
 gen ccc=s5_03		
 
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
 replace salaried=1   if emppri==1 & (s5_21==1 | s5_21==2 | s5_21==4  | s5_21==8)
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
fincome s5_31b, by(s5_29)		
recode  s5_31a *=. if s5_31a>=880000			
capture drop ysal1net
gen ysal1net=.
replace ysal1net=s5_31a*freq

*----------------------
*INGRESOS EXTRAS - ASALARIADO- ACTIVIDAD PRINCIPAL
*----------------------

*1. Prima de producción mensualizado
recode s5_32a *=. if s5_32a>=880000	
capture drop ysal1ben_1
gen ysal1ben_1=s5_32a/12

*2. Aguinaldo mensualizado
recode s5_32b *=. if s5_32b>=880000				
capture drop ysal1ben_2
gen ysal1ben_2=s5_32b/12

*3. Comisiones
fincome s5_33a2, by(s5_29)				
recode s5_33a1 *=. if s5_33a1>=880000	
capture drop ysal1ben_3
gen ysal1ben_3=.
replace ysal1ben_3=s5_33a1*freq

*4. Horas Extra
fincome s5_33b2, by(s5_29)
recode s5_33b1 *=. if s5_33b1>=880000
capture drop ysal1ben_4
gen ysal1ben_4=.
replace ysal1ben_4=s5_33b1*freq

***SALARIO MINIMO
do "$do\salario_minimo.do"

*5. Subsidio de lactancia mensualizado
capture drop ysal1ben_5
gen ysal1ben_5=(salmin*s5_34a2)/12 if s5_34a1==1

*6. Bono de natalidad
capture drop ysal1ben_6
gen ysal1ben_6=salmin/12 		if s5_34b==1

*Sumatoria de ingresos extra
egen ysal1ben=rsum(ysal1ben_1 ysal1ben_2 ysal1ben_4 ysal1ben_5 ysal1ben_6),m
*egen ysal1ben=rsum(ysal1ben_1 ysal1ben_2 ysal1ben_3 ysal1ben_4 ysal1ben_5 ysal1ben_6),m

*----------------------
* INGRESOS EN ESPECIE - ASALARIADO - ACTIVIDAD PRINCIPAL
*----------------------			

*1. Alimentos
fincome s5_36a2, by(s5_29)
recode s5_36a3 *=. if s5_36a3>=880000 
gen  ysal1esp_1=s5_36a3*freq

*2. Transporte
fincome s5_36b2, by(s5_29)
recode s5_36b3 *=. if s5_36b3>=880000
gen ysal1esp_2=s5_36b3*freq

*3. Vestidos y Calzado
fincome s5_36c2, by(s5_29)
recode s5_36c3 *=. if s5_36c3>=880000
gen ysal1esp_3=s5_36c3*freq

*4. Vivienda
fincome s5_36d2, by(s5_29)
recode s5_36d3 *=. if s5_36d3>=880000
gen ysal1esp_4=s5_36d3*freq

*5. Otros
fincome s5_36e2, by(s5_29)
recode s5_36e3 *=. if s5_36e3>=880000
gen ysal1esp_5=s5_36e3*freq

*Sumatoria de ingresos en especie
egen ysal1esp=rsum(ysal1esp_1 ysal1esp_2 ysal1esp_3 ysal1esp_4 ysal1esp_5),m

*----------------------
* INGRESOS CUENTA PROPIA (TRABAJADOR INDEPENDIENTE)- ACTIVIDAD PRINCIPAL
*----------------------

*Total Ingresos
fincome s5_37b, by(s5_29)				
recode s5_37a *=. if s5_37a>=880000
capture drop yind1tot
gen yind1tot=.
replace  yind1tot=s5_37a*freq

* Ingreso Neto T.I.
fincome s5_39b, by(s5_29)
recode s5_39a *=. if s5_39a>=880000
capture drop yind1net
gen yind1net=.
replace yind1net=s5_39a*freq

capture drop yind1fin
gen yind1fin=yind1net  	

*----------------------
* INGRESO LABORAL - ACTIVIDAD PRINCIPAL
*----------------------

capture drop yprijb
egen yprijb=rsum(ysal1net ysal1ben ysal1esp), m

replace yprijb=yind1net					if s5_21==3 | s5_21==5 | s5_21==6
replace yprijb=0						if s5_21==7

*-----------------------------
*INGRESOS ACTIVIDAD SECUNDARIA
*-----------------------------

*ASALARIADO
* Ingreso liquido en horario normal
fincome s5_48b, by(s5_46a)			
recode  s5_48a *=. if s5_48a>=80000
capture drop ysal2net
gen ysal2net=.
replace ysal2net=s5_48a*freq


* Ingreso extra 
*a* Ingreso por horas extras/ bono/ aguinaldo
recode s5_49a2 *=. if s5_49a2>=880000										
capture drop ysal2ben_a
gen ysal2ben_a=s5_49a2/12

*b* subsidio de lactancia/bono de natalidad
capture drop ysal2ben_b
gen ysal2ben_b=.

egen ysal2ben=rsum(ysal2ben_a ysal2ben_b),m

* Ingreso en especie

*1. Alimentos/Transporte/Vestidos y calzados
recode s5_49b2 *=. if s5_49b2>=880000
gen ysal2esp_a=s5_49b2/12

*2. Vivienda/Otros
recode s5_49c2 *=. if s5_49c2>=880000
gen ysal2esp_b=s5_49c2/12

* INGRESO EN ESPECIE TOTAL
egen ysal2esp=rsum(ysal2esp_a ysal2esp_b),m

*CUENTA PROPIA

*Ingreso Total
fincome s5_50b, by(s5_46a)
recode s5_50a *=. if s5_50a>=880000
capture drop yind2tot
gen yind2tot=.
replace  yind2tot=s5_50a*freq

*Ingreso Neto
fincome s5_52b, by(s5_46a)
recode s5_52a *=. if s5_52a>=880000
capture drop yind2net
gen yind2net=s5_52a*freq

capture drop yindfin
gen yindfin=yind2net  

*----------------------
* INGRESO LABORAL - ACTIVIDAD SECUNDARIA
*----------------------
capture drop ysecjb
egen ysecjb=rsum(ysal2net ysal2ben ysal2esp),m 

replace ysecjb=yindfin		if s5_43==3 | s5_43==5 | s5_43==6
replace ysecjb=0			if s5_43==7

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
for varlist s6_01a  s6_01b  s6_01c s6_01d s6_01eb: 		recode X *=. if X>=880000    /*jubila, etc*/	
for varlist s6_02a s6_02b s6_02c: 				recode X *=. if X>=880000            /*rentas*/		
for varlist s6_03a s6_03b s6_03c: 				recode X *=. if X>=880000            /*renta capi*/ 	
for varlist s6_04a s6_04b s6_04c: 				recode X *=. if X>=880000            /*ing.extraor*/ 
for varlist s6_05a1 s6_05b1 :		 			recode X *=. if X>=880000            /*tranf.o.h*/	
for varlist s6_09a:			 			recode X *=. if X>=880000 	//	             /*remesas*/		
                                                                                     				
*** Annualizing and converting to Bs.                                                				
for varlist s6_03a s6_03b s6_03c: 		replace X =X/12                              /*remesas*/		
for varlist s6_04a s6_04b s6_04c:	 	replace X =X/12 

capture drop aux*
fincome s6_05a2
gen aux33=s6_05a1*freq

fincome s6_05b2
gen aux55=s6_05b1*freq

fincome s6_07
capture drop aux77 aux88
gen aux77=s6_09a*freq     if s6_09b=="A"    /*remesas*/		
*gen aux88=s7c_10*freq                       /*en especie*/	
		

do "$do/exchange_rate"


replace aux77=s6_09a*freq*tc  if s6_09b=="C"	//$us
replace aux77=s6_09a*freq*tc2 if s6_09b=="B"	//euros
replace aux77=s6_09a*freq*tc3 if s6_09b=="D"	//pesos argentinos
replace aux77=s6_09a*freq*tc4 if s6_09b=="E"	//reales
replace aux77=s6_09a*freq*tc5 if s6_09b=="F"	//pesos chilenos
replace aux77=s6_09a*freq*0.08593 if  s6_09b=="G" & s6_09e=="YEN"	//yen
				
* Income from social security *
note: sin renta dignidad
capture drop ysstot
egen ysstot=rsum(s6_01a  s6_01b  s6_01c s6_01d),m

* Income from property *
capture drop yprotot
egen yprotot=rsum(s6_02a s6_02b s6_02c s6_03a s6_03b s6_03c),m

* Intra-household transfers *
capture drop ytrh_*
gen ytrh_1=aux33
gen ytrh_2=aux55 //cambio la pregunta resp 2013
egen ytrh_3=rowtotal(aux77), miss //cambio preg. 09 a 08 resp. 2013

note: se incluyeron las remesas en Intra-household transfers 

capture drop ytrhtot
egen ytrhtot=rsum(ytrh_1 ytrh_2 ytrh_3),m

* Goverment transfers *
capture drop ytrgtot
egen ytrgtot=rsum(s6_01eb),m // only renta dignidad in this case

* Other non labor income *
capture drop yothtot
egen yothtot=rsum(s6_04a s6_04b s6_04c),m				//UDAPE no lo toma en cuenta 

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