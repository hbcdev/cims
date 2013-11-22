lnHandle = SQLCONNECT("tic member")
IF lnHandle = 0
	WAIT WINDOW "cannot connect to ODBC" NOWAIT 
	RETURN 
ENDIF 

= SQLSETPROP(lnHandle, 'asynchronous', .F.)
= SQLEXEC(lnHandle, "SELECT * FROM papolmas WHERE  Papolmas.product_cd IS NOT NULL ORDER BY Papolmas.policy_no", 'pamas')
= SQLEXEC(lnHandle, "SELECT * FROM paitem ", 'paitems')

PROCEDURE aa

IF !USED("pa_member")
	RETURN 
ENDIF 
*
SELECT * ;
FROM pa_member ;
WHERE UPPER(product_cd) IN ("D-LITE", "X-CITE") ;
INTO CURSOR curMemb

ALLTRIM(LEFT(inquirymain.ins_name, AT(" ", inquirymain.ins_name))) AS title, ;
ALLTRIM(LEFT(SUBSTR(inquirymain.ins_name, AT(" ", inquirymain.ins_name)+1), AT(" ", SUBSTR(inquirymain.ins_name, AT(" ", inquirymain.ins_name)+1)))) AS name, ;
ALLTRIM(SUBSTR(SUBSTR(inquirymain.ins_name, AT(" ", inquirymain.ins_name)+1),AT(" ", SUBSTR(inquirymain.ins_name, AT(" ", inquirymain.ins_name)+1)))) AS surname, ;



SELECT pa_member

SCAN 
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 99,999") NOWAIT 
	FOR i = 1 TO FCOUNT()
		lcFldName = FIELD(i)
		IF ISNULL(&lcFldName)
			DO CASE 
			CASE TYPE(lcFldName) $ "NIY"
				REPLACE &lcFldName WITH 0
			CASE TYPE(lcFldName) $ "CM"
				REPLACE &lcFldName WITH ""
			CASE TYPE(lcFldName) $ "DT"
				REPLACE &lcFldName WITH {}
			ENDCASE 
		ENDIF 
	ENDFOR 
	IF INLIST(LEFT(policyno,19), "001D/PH51-00-000664", "001D/PH51-01-000432", "001D/PH51-03-000538", "001D/PH51-04-001480", "001D/PH51-02-000570")
		REPLACE employee WITH "Staff"
	ELSE 
		REPLACE employee WITH ""
	ENDIF 		
ENDSCAN