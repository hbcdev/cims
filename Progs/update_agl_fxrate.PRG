lnFxYear = YEAR(DATE())
lnFxMonth = MONTH(DATE())
SELECT usd2thb, lak2thb, lak2usd ;
FROM cims!exchange_rate ;
WHERE fundcode = "AGL" ;
	AND fxyear = lnFxYear ;
	AND fxmonth = lnFxMonth ;
INTO ARRAY laFxRate
******************************************
IF laFxRate[1] = 0 OR laFxRate[2] = 0
	=MESSAGEBOX("อัตราแลกเปลี่ยน = 0 กรุณาขออัตราฯ ใหม่ก่อนทำการอัพเดท", 0, "Error")
ELSE 	
	UPDATE cims!policy2items SET fxrate = laFxRate[1], ;
		benefit_th = benefit*laFxRate[1], ;
		l_user = UPPER(ALLTRIM(SUBSTR(ID(), AT("#", ID())+1))), ;
		l_update = DATETIME() ;
	WHERE fundcode = "AGL" AND currency_type = "USD" 
	lnUsd = _TALLY

	UPDATE cims!policy2items SET fxrate = laFxRate[2], ;
		benefit_th = benefit/laFxRate[2], ;
		l_user = UPPER(ALLTRIM(SUBSTR(ID(), AT("#", ID())+1))), ;
		l_update = DATETIME() ;	
	WHERE fundcode = "AGL" AND currency_type = "LAK" 
	lnLak = _TALLY
	=MESSAGEBOX("Total Update : "+TRANSFORM(lnUsd+lnLak,"@Z 99,999"), 0, "Message")
ENDIF 