clear all 

********************************************************************************
*************		REPLICANDO INDICADORES INE 2018                *************
********************************************************************************

use "D:\Encuestas Hogares\Encuesta de Hogares 2018\DTA\eh_2018_persona.dta"
global year 2018
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
gen edad= s02a_03

* PARENTCO: Relacion jefe del hogar
capture drop parentco
gen parentco =s02a_05 
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
gen spbja =  (s04b_19 == 1) if s04b_19 != .

capture drop spbja_monto
capture drop aux1
gen aux1 = s04b_20a2 * 50
capture drop aux2
gen aux2 = 125 if s04b_20b == 1
egen spbja_monto = rowtotal(aux1 aux2)

capture drop spbja_b /*BJA: controles bimestrales */
gen spbja_b = (s04d_26 ==1 ) if s04d_26 !=.

capture drop spbja_bmonto
gen spbja_bmonto = s04d_27b * 125   /* 125 bs por cada control post parto */
replace spbja_bmonto = 0 if spbja_bmonto ==. & spbja_b == 0

capture drop spprenat_q
gen sppren_q = s04b_21b*300

*BONO JUANCITO PINTO

capture drop spbjp
gen spbjp = (s05a_08 == 1) if  s05a_08 !=.

******************************************************************
 capture drop aa
 gen aa=s06a_01		//Q: durante la semana pasada, ¿trabajó al menos una hora?
 capture drop bb
 gen bb=s06a_02		//Q. durante la semana pasada, dedicó al menos una hora a: otros trabajos remunerados
 recode bb 			1/2=1 3=2 4=3 5=4 6=5 7=6 8=7
 capture drop ccc
 gen ccc=s06a_03	//Q. ¿la semana pasada, tuvo algún empleo, negocio o empresa propia al cual no asistio por enfermedad, u otro.		
 
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
 replace salaried=1   if emppri==1 & (s06b_16==1 | s06b_16==2 | s06b_16==4  | s06b_16==8)
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
fincome s06c_25b, by(s06b_22)
capture drop ysal1net
gen ysal1net=.
replace ysal1net=s06c_25a*freq

*----------------------
*INGRESOS EXTRAS - ASALARIADO- ACTIVIDAD PRINCIPAL
*----------------------

*1. Prima de producción mensualizado
capture drop ysal1ben_1
gen ysal1ben_1=s06c_26a/12

*2. Aguinaldo mensualizado
capture drop ysal1ben_2
gen ysal1ben_2=s06c_26b/12

*3. Comisiones
fincome s06c_27ab, by(s06b_22)
capture drop ysal1ben_3
gen ysal1ben_3=.
replace ysal1ben_3=s06c_27aa*freq 

*4. Horas Extra
fincome s06c_27bb, by(s06b_22)
capture drop ysal1ben_4
gen ysal1ben_4=.
replace ysal1ben_4=s06c_27ba*freq

***SALARIO MINIMO
do "$do\salario_minimo.do"

*5. Subsidio de lactancia mensualizado
capture drop ysal1ben_5
gen ysal1ben_5=(2000*s06c_28a1)/12 if s06c_28a==1

*6. Bono de natalidad
capture drop ysal1ben_6
gen ysal1ben_6=salmin/12 		if s06c_28b==1

*Sumatoria de ingresos extra
egen ysal1ben=rsum(ysal1ben_1 ysal1ben_2 ysal1ben_4 ysal1ben_5 ysal1ben_6),m
*egen ysal1ben=rsum(ysal1ben_1 ysal1ben_2 ysal1ben_3 ysal1ben_4 ysal1ben_5 ysal1ben_6),m

*----------------------
* INGRESOS EN ESPECIE - ASALARIADO - ACTIVIDAD PRINCIPAL
*----------------------			

*1. Alimentos
fincome s06c_30a1, by(s06b_22)
recode s06c_30a2 *=. if s06c_30a2>=880000 
gen  ysal1esp_1=s06c_30a2*freq

*2. Transporte
fincome s06c_30b1, by(s06b_22)
recode s06c_30b2 *=. if s06c_30b2>=880000
gen ysal1esp_2=s06c_30b2*freq

*3. Vestidos y Calzado
fincome s06c_30c1, by(s06b_22)
recode s06c_30c2 *=. if s06c_30c2>=880000
gen ysal1esp_3=s06c_30c2*freq

*4. Vivienda
fincome s06c_30d1, by(s06b_22)
recode s06c_30d2 *=. if s06c_30d2>=880000
gen ysal1esp_4=s06c_30d2*freq

*5. Otros
fincome s06c_30e1, by(s06b_22)
recode s06c_30e2 *=. if s06c_30e2>=880000
gen ysal1esp_5=s06c_30e2*freq

*Sumatoria de ingresos en especie
egen ysal1esp=rsum(ysal1esp_1 ysal1esp_2 ysal1esp_3 ysal1esp_4 ysal1esp_5),m

*----------------------
* INGRESOS CUENTA PROPIA (TRABAJADOR INDEPENDIENTE)- ACTIVIDAD PRINCIPAL
*----------------------

*Total Ingresos
fincome s06d_31b, by(s06b_22)
recode s06d_31a *=. if s06d_31a>=880000
capture drop yind1tot
gen yind1tot=.
replace  yind1tot=s06d_31a*freq

* Ingreso Neto T.I.
fincome s06d_33b, by(s06b_22) 
recode s06d_33a *=. if s06d_33a>=880000
capture drop yind1net
gen yind1net=.
replace yind1net=s06d_33a*freq

capture drop yind1fin
gen yind1fin=yind1net  	

*----------------------
* INGRESO LABORAL - ACTIVIDAD PRINCIPAL
*----------------------

capture drop yprijb
egen yprijb=rsum(ysal1net ysal1ben ysal1esp), m

replace yprijb=yind1fin					if s06b_16==3 | s06b_16==5 | s06b_16==6
replace yprijb=0						if s06b_16==7

*twoway (kdensity yprijb_2) (kdensity yprilab)

*-----------------------------
*INGRESOS ACTIVIDAD SECUNDARIA
*-----------------------------

*ASALARIADO
* Ingreso liquido en horario normal
fincome s06g_47b, by(s06f_44)						
recode  s06g_47a *=. if s06g_47a>=880000
capture drop ysal2net
gen ysal2net=.
replace ysal2net=s06g_47a*freq

* Ingreso extra 
*a* Ingreso por horas extras/ bono/ aguinaldo
*capture drop ysal2ben_a
*gen ysal2ben_a=s06g_49a1/12
capture drop ysal2ben
gen ysal2ben=s06g_48a1/12	

/*b* subsidio de lactancia/bono de natalidad
capture drop ysal2ben_b
gen ysal2ben_b=.

egen ysal2ben=rsum(ysal2ben_a ysal2ben_b),m*/

* Ingreso en especie

*1. Alimentos/Transporte/Vestidos y calzados
recode s06g_48b1 *=. if s06g_48b1>=880000
gen ysal2esp_a=s06g_48b1/12

*2. Vivienda/Otros
recode s06g_48c1 *=. if s06g_48c1>=880000
gen ysal2esp_b=s06g_48c1/12

* INGRESO EN ESPECIE TOTAL
egen ysal2esp=rsum(ysal2esp_a ysal2esp_b),m

*CUENTA PROPIA

*Ingreso Total
fincome s06g_49b, by(s06f_44)
recode s06g_49a *=. if s06g_49a>=880000
capture drop yind2tot
gen yind2tot=.
replace  yind2tot=s06g_49a*freq

*Ingreso Neto
fincome s06g_51b, by(s06f_44)
recode s06g_51a *=. if s06g_51a>=880000
capture drop yind2net
gen yind2net=s06g_51a*freq

capture drop yindfin
gen yindfin=yind2net  

*----------------------
* INGRESO LABORAL - ACTIVIDAD SECUNDARIA
*----------------------
capture drop ysecjb
egen ysecjb=rsum(ysal2net ysal2ben ysal2esp),m 

replace ysecjb=yindfin			if s06f_41==3 | s06f_41==5 | s06f_41==6
replace ysecjb=0				if s06f_41==7

*twoway (kdensity ysecjb_2) (kdensity yseclab)

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
*Bono Indigencia por Ceguera (IBC):
cap drop spibc spibc_monto
gen spibc=(s04a_09==1)
destring s04a_09a, replace
gen spibc_monto=s04a_09a/12 if (spibc==1)

for varlist s07a_01a s07a_01b s07a_01c s07a_01d s07a_01e0: 		recode X *=. if X>=880000  				/*jubila, etc*/	
for varlist s07a_02a s07a_02b s07a_02c: 				recode X *=. if X>=880000          				/*rentas*/		
for varlist s07a_03a s07a_03b s07a_03c: 				recode X *=. if X>=880000          				/*renta capi*/ 	
for varlist s07a_04a s07a_04b s07a_04c s07a_04d: 				recode X *=. if X>=880000  				/*ing.extraor*/ 
for varlist s07b_05aa s07b_05ba s07b_05ca s07b_05da s07b_05ea:	recode X *=. if X>=880000               /*tranf.o.h*/	
for varlist s07c_08a:			 			recode X *=. if X>=880000 	//	               				/*remesas*/		
                                                                                            				
*** Monthlyizing and converting to Bs.                                                      				
for varlist s07a_03a s07a_03b s07a_03c: 		replace X =X/12                            	
for varlist s07a_04a s07a_04b s07a_04c s07a_04d:	 	replace X =X/12

capture drop aux*
fincome s07b_05ab
gen aux33=s07b_05aa*freq

fincome s07b_05bb
gen aux55=s07b_05ba*freq

fincome s07b_05cb
gen aux66=s07b_05ca*freq

fincome s07b_05db
gen aux67=s07b_05da*freq

fincome s07b_05eb
gen aux68=s07b_05ea*freq

do "$do/exchange_rate"

fincome s07c_07
capture drop aux77 aux88
gen aux77=s07c_08a*freq     if s07c_08b==1    /*remesas*/		
gen aux88=s07c_10*freq                        /*en especie*/	
capture drop flag11
gen flag11=1 if (s07c_10==s07c_08a) & (s07c_10!=. )
replace flag11=0	if (s07c_10!=s07c_08a) & (s07c_08a!=.) & (s07c_10!=. )	

replace aux77=s07c_08a*freq*tc  if s07c_08b==3	//$us
replace aux77=s07c_08a*freq*tc2 if s07c_08b==2  //euros
replace aux77=s07c_08a*freq*tc3 if s07c_08b==4	//pesos argentinos
replace aux77=s07c_08a*freq*tc4 if s07c_08b==5	//reales
replace aux77=s07c_08a*freq*tc5 if s07c_08b==6	//pesos chilenos
replace aux77=s07c_08a*freq*tc6 if s07c_08b==7 & s07c_08e=="SOLES"  //soles
replace aux77=s07c_08a*freq*tc10 if s07c_08b==7 & s07c_08e=="PESOS MEXICANOS"  //pesos mexicanos
				
* Income from social security *
note: sin renta dignidad
capture drop ysstot
egen ysstot=rsum(s07a_01a s07a_01b s07a_01c s07a_01d),m

* Income from property *
capture drop yprotot
egen yprotot=rsum(s07a_02a s07a_02b s07a_02c s07a_03a s07a_03b s07a_03c),m

* Intra-household transfers *
capture drop ytrh_*
gen ytrh_1=aux33
gen ytrh_2=aux55 //cambio la pregunta resp 2013
gen ytrh_4=aux66
gen ytrh_5=aux67
gen ytrh_6=aux68
egen ytrh_3=rowtotal(aux77 aux88), miss //cambio preg. 09 a 08 resp. 2013

note: se incluyeron las remesas en Intra-household transfers 

capture drop ytrhtot
egen ytrhtot=rsum(ytrh_1 ytrh_2 ytrh_3 ytrh_4 ytrh_5 ytrh_6),m

* Goverment transfers *
capture drop ytrgtot
egen ytrgtot=rsum(s07a_01e0),m // only renta dignidad in this case

* Other non labor income *
capture drop yothtot
egen yothtot=rsum(s07a_04a s07a_04b s07a_04c s07a_04d),m

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
replace hhytot=0 if hhytot==. & hhmember==1 // Esta condicion esta rara

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