************************************************
* EXCHANGE RATES
************************************************
note: 	Los tipos de cambio anuales 2012 para el euro, /// 
		peso argentino, real, peso chileno , sol y bolívares ///
		resultan del promedio de los tipos de cambio observados ///
		el primer día hábil de cada mes (Fuente: BCB).
note:	Los tipos de cambio 2014/2016 y 2018 son de noviembre de ///
		cada año segun BCB. 												

*** EXCHANGE RATE (Dolar)
 capture drop tc
 gen 		tc= .
 replace	tc=	5.82 	if year==1999
 replace 	tc=	6.19 	if year==2000
 replace 	tc=	6.61 	if year==2001
 replace 	tc=	7.18 	if year==2002
 replace 	tc=	7.66 	if year==2003
 replace 	tc=	7.94 	if year==2004
 replace 	tc=	8.08 	if year==2005
 replace 	tc=	7.96 	if year==2006
 replace 	tc=	7.81 	if year==2007
 replace 	tc=	7.08	if year==2008
 replace 	tc=	6.97 	if year==2009
 replace 	tc=	6.97	if year==2010
 replace 	tc=	6.88	if year==2011
 replace 	tc=	6.86 	if year==2012
 replace 	tc=	6.86 	if year==2013 | year==2014 | year==2015 | year==2016 | year==2017 | year==2018 | year==2019 | year==2020 | year==2021
 				
*** EXCHANGE RATE 2 (Euro)
 capture drop tc2
 gen 		tc2=.
 *replace tc2=x if year==1999
 *replace tc2=x if year==2000
 *replace tc2=x if year==2001
 replace 	tc2= 7.8383 	if year==2002
 replace 	tc2= 9.8149 	if year==2003
 replace 	tc2= 10.9734	if year==2004
 replace 	tc2= 9.4804		if year==2005
 replace 	tc2= 10.4260	if year==2006
 replace 	tc2= 10.2		if year==2007     /*diferencia en el 2007 11.1404 */	
 replace 	tc2= 10.6625	if year==2008
 replace 	tc2= 9.70234	if year==2009
 replace 	tc2= 9.26109	if year==2010
 replace 	tc2= 9.65775	if year==2011
 replace 	tc2= 8.84281	if year==2012
 replace 	tc2= 9.09179	if year==2013
 replace 	tc2= 8.59574	if year==2014 
 replace 	tc2= 7.54941	if year==2015
 replace 	tc2= 7.53225	if year==2016
 replace 	tc2= 7.22425 	if year==2017
 replace 	tc2= 7.76756 	if year==2018
 replace 	tc2= 7.65164 	if year==2019
 replace 	tc2= 7.98845 	if year==2020 
 replace 	tc2= 7.92670 	if year==2021 

*** EXCHANGE RATE 3 (Pesos argentinos)
 capture drop tc3
 gen 		tc3=.
 *replace tc3=X if year==1999  
 replace 	tc3=6.3904		if year==2000
 replace 	tc3= 6.4762		if year==2001
 replace 	tc3= 2.2262		if year==2002
 replace 	tc3= 2.6644		if year==2003
 replace 	tc3= 2.7021		if year==2004
 replace 	tc3= 2.6446		if year==2005
 replace 	tc3= 2.5810		if year==2006 
 replace 	tc3= 2.44170	if year==2007 /*2.4036*/
 replace 	tc3= 2.287734 	if year==2008									
 replace 	tc3= 1.876131 	if year==2009
 replace 	tc3= 1.784231 	if year==2010
 replace 	tc3= 1.675143 	if year==2011
 replace 	tc3= 1.517972 	if year==2012
 replace 	tc3= 1.273708 	if year==2013
 replace 	tc3= 0.80693	if year==2014 
 replace 	tc3= 0.72126	if year==2015
 replace 	tc3= 0.45269	if year==2016
 replace 	tc3= 0.43199 	if year==2017
 replace 	tc3= 0.19105 	if year==2018
 replace 	tc3= 0.11500 	if year==2019
 replace 	tc3= 0.08759 	if year==2020
 replace 	tc3= 0.06879 	if year==2021

 
*** EXCHANGE RATE 4 (Reales)
 capture drop tc4
 gen 		tc4=.
 *replace tc4=x if year==1999
 replace 	tc4= 3.2718 	if year==2000
 replace 	tc4= 2.9468 	if year==2001
 replace 	tc4= 2.1172 	if year==2002	
 replace 	tc4= 2.6947 	if year==2003
 replace 	tc4= 3.0317 	if year==2004
 replace 	tc4= 3.4426 	if year==2005
 replace 	tc4= 3.7160 	if year==2006
 replace 	tc4= 4.41948 	if year==2007 /*4.2511*/
 replace 	tc4= 4.092603 	if year==2008							
 replace 	tc4= 3.461347 	if year==2009
 replace 	tc4= 3.949342 	if year==2010
 replace 	tc4= 4.173045 	if year==2011
 replace 	tc4= 3.540694 	if year==2012
 replace 	tc4= 3.195653 	if year==2013
 replace 	tc4= 2.77068 	if year==2014 
 replace 	tc4= 1.77601 	if year==2015
 replace 	tc4= 2.14677 	if year==2016
 replace 	tc4= 2.10740 	if year==2017
 replace 	tc4= 1.84186 	if year==2018
 replace 	tc4= 1.70957 	if year==2019
 replace 	tc4= 1.19304	if year==2020
 replace 	tc4= 1.21495	if year==2021
 
*** EXCHANGE RATE 5 (Pesos Chilenos)
 capture drop tc5
 gen 		tc5=.
 *replace tc5=x  if year==1999
 replace 	tc5= 0.0112		if year==2000
 replace 	tc5= 0.0103 	if year==2001
 replace 	tc5= 0.0104		if year==2002
 replace 	tc5= 0.0132 	if year==2003
 replace 	tc5= 0.0145  	if year==2004
 replace 	tc5= 0.0156 	if year==2005
 replace 	tc5= 0.0148  	if year==2006
 replace 	tc5= 0.01557 	if year==2007 /*0.0152*/
 replace 	tc5= 0.0141983 	if year==2008									
 replace 	tc5= 0.0123817 	if year==2009
 replace 	tc5= 0.0135917 	if year==2010
 replace 	tc5= 0.0144275 	if year==2011
 replace 	tc5= 0.0140125 	if year==2012
 replace 	tc5= 0.01386 	if year==2013
 replace 	tc5= 0.01187 	if year==2014 
 replace 	tc5= 0.00992 	if year==2015
 replace 	tc5= 0.01050 	if year==2016
 replace 	tc5= 0.01023 	if year==2017
 replace 	tc5= 0.00985 	if year==2018
 replace 	tc5= 0.00925 	if year==2019
 replace 	tc5= 0.00886 	if year==2020
 replace 	tc5= 0.00842 	if year==2021

*** EXCHANGE RATE 6 (soles)
 capture drop tc6 
 gen 		tc6=.
 *replace tc6=x if year==1999
 replace 	tc6= 1.8087 	if year==2000
 replace 	tc6= 1.9791 	if year==2001
 replace 	tc6= 2.1277 	if year==2002
 replace 	tc6= 2.2552 	if year==2003
 replace 	tc6= 2.4482 	if year==2004
 replace 	tc6= 2.3337 	if year==2005
 replace 	tc6= 2.4805 	if year==2006
 replace 	tc6= 2.55620 	if year==2007 /*2,5276*/
 replace 	tc6= 2.469371 	if year==2008							
 replace 	tc6= 2.308387 	if year==2009
 replace 	tc6= 2.461144 	if year==2010
 replace 	tc6= 2.495131 	if year==2011
 replace 	tc6= 2.593038 	if year==2012
 replace 	tc6= 2.541721 	if year==2013
 replace 	tc6= 2.34811 	if year==2014 
 replace 	tc6= 2.08701 	if year==2015
 replace 	tc6= 2.03954 	if year==2016 
 replace 	tc6= 2.04410 	if year==2017
 replace 	tc6= 2.03470 	if year==2018
 replace 	tc6= 2.05088 	if year==2019
 replace 	tc6= 1.89774 	if year==2020
 replace 	tc6= 1.71805 	if year==2021

 *** EXCHANGE RATE 7 (bolívares)
 capture drop tc7
 gen 		tc7=.
 replace 	tc7= 1.08889 	if year==2014 						
 
*** EXCHANGE RATE 8 (libras)
 capture drop tc8
 gen 		tc8=.
 replace 	tc8= 10.97266 	if year==2014
 
 *** EXHANGE RATE 9 (Pesos Cubanos)
 capture drop tc9
 gen tc9=.
 replace 	tc9=.2800 	if year==2017

 *** EXHANGE RATE 10 (Pesos Mexicanos)
 capture drop tc10
 gen tc10=.
 replace 	tc10= 0.33767 	if year==2018
 
 label variable	tc			"Tipo de cambio dolar"
 label variable	tc2			"Tipo de cambio euro"
 label variable	tc3			"Tipo de peso argentino"	
 label variable	tc4			"Tipo de cambio reales"
 label variable	tc5			"Tipo de cambio peso chileno"
 label variable	tc6			"Tipo de cambio soles"
 label variable	tc7			"Tipo de cambio bolivares"
 label variable	tc8			"Tipo de cambio libras"
 label variable	tc9			"Tipo de cambio pesos cubanos"
 label variable	tc10		"Tipo de cambio pesos mexicanos"
