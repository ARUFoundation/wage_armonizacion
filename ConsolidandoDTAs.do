clear all 

********************************************************************************
************* 				CONSOLIDANDO DTAs 						************
********************************************************************************

global do "D:\ARU\Armonización EH\Replica_2021\Replica_y_INE\do"
global temp "D:\ARU\Armonización EH\Replica_2021\Replica_y_INE\temp"

global yearlist 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020 2021

** do-files:
	foreach yyy of global yearlist{
		do "D:\ARU\Armonización EH\Replica_2021\Replica_y_INE\do\ReplicandoIngresos_`yyy'"
		}

 ** append 
global yearlist 2011 2012 2013 2014 2015 2016 2017 2018 2019 2020
	foreach yyy of global yearlist{
		append using "$temp\eh`yyy'(per)income.dta", force
		}

*Para recalcular ingresos laborales, actividad principal:
global switch_yprilab =0
	if $switch_yprilab==0{
		note: Ingresos laborales replican los del INE
		}
	if $switch_yprilab==1{
		note: Ingreso laboral act. principal con comisiones (como en base armonizada)
		cap drop aux*
		egen aux1=rsum(yprijb ysal1ben_3), m
		replace yprijb=aux1
		egen aux2=rsum(ysal1ben ysal1ben_3)
		replace ysal1ben=aux2
		}
	if $switch_yprilab==2{
		note: otra especificación de ingreso 
		}
*Para recalcular ingresos laborales, actividad principal:
global switch_ynolab =0		
	if $switch_ynolab==0{
		note: Ingresos laborales replican los del INE
		}
	if $switch_ynolab==1{
		note: Ingreso no-laboral sin bja (como base armonizada hasta 2018)
		cap drop aux*
		egen aux1=rsum(yprotot ysstot ytrhtot ytrgtot), m
		replace ynonjb=aux1
		}
	if $switch_ynolab==2{
		note: Ingreso no-laboral con otros ingresos no-laborales y sin bja (como base armonizada desde 2018)
		cap drop aux*
		egen aux1=rsum(yprotot ysstot ytrhtot ytrgtot yothtot), m
		replace ynonjb=aux1
		}
	if $switch_ynolab==3{
		note: Ingreso no-laboral con todos ingresos no-laborales y bja
		cap drop aux*
		egen aux1=rsum(yprotot ysstot ytrhtot ytrgtot yothtot bja_m), m
		replace ynonjb=aux1
		}

*Recalculamos ingresos agregados y per-capita:
if ($switch_yprilab!=0 | $switch_ynolab!=0){
	cap drop hhyjb hhynonjb hhytot ypcjb ypcnonjb ypctot yalljb
	*Ingreso laboral total
	egen yalljb=rsum(yprijb ysecjb),m
	egen hhyjb=sum(yalljb) if hhmember==1, by (id_hh)
	egen hhynonjb=sum(ynonjb) if hhmember==1, by (id_hh)
	
	*Ingreso laboral per-capita
	capture drop ypcjb
	gen ypcjb=hhyjb/hhtotal

	*Ingreso no-laboral total
	capture drop ypcnonjb
	gen ypcnonjb=hhynonjb/hhtotal

	*Ingreso Total
	capture drop hhytot
	egen hhytot=rsum(hhyjb hhynonjb),m

	capture drop ypctot
	gen ypctot=hhytot/hhtotal
}

*The second yearlist is only to t-1, because it's already opened due to previous do command. 
compress
save "$temp\Income_2011_2021.dta", replace 

