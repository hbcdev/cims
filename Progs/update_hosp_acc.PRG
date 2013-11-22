CLOSE ALL 
USE ? IN 0 ALIAS hacc
USE cims!provider IN 0 ORDER prov_id

SELECT hacc
SCAN 
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 999") NOWAIT 
	IF !EMPTY(acno)
		IF SEEK(prov_id, "provider", "prov_id")
			REPLACE provider.account_no WITH acno, ;
				provider.acc_name WITH accname, ;
				provider.bank WITH bank
		ENDIF 
	ENDIF 
ENDSCAN 				