lcSourceFile = GETFILE("TXT")
lcDbf = STRTRAN(lcSourceFile, ".TXT", ".DBF")
ldDate = CTOD(SUBSTR(JUSTFNAME(lcDbf), 21,2)+"/"+SUBSTR(JUSTFNAME(lcDbf),18,2)+"/"+SUBSTR(JUSTFNAME(lcDbf),13, 4))
?ldDate
*************************************
SET HOURS TO 24
IF EMPTY(lcSourceFile)
	RETURN 
ENDIF 
*	
IF FILE(lcDbf)
	=MESSAGEBOX(lcDbf+" is exist")
ENDIF 
*	
SELECT 0
CREATE DBF (lcDbf) FREE (Policy_no C(30), Plan_type C(3), Plan C(20), cust_id C(20), title C(20), Name C(40), Surname C(40), ;
	Sex C(1), Dob D, Age I, District C(40), Province C(40), Country C(40), Postcode C(5), Telephone C(30), ;
	Poldate T, Effdate T, Expdate T, Premium Y, Exclusion C(200),  Agent C(15), Agency C(15), ;
	Paymode C(2), Renew I, Polstatus C(2), Payer C(40), Medical Y, Hbcover Y, Endorse C(30), ;
	EndDate D, EndType C(2), Paiddate D, Reindate D, Laspedate D, Canceldate D, prodcode C(10), Adddate D, ;
	plan_id C(10), cardno C(25), insure C(80))
*
?DBF()
lnFieldCounts = 36
lnLines = ALINES(laTextArray,FILETOSTR(lcSourceFile))
FOR i = 1 TO lnLines
	WAIT WINDOW TRANSFORM(i, "@Z 999,999") NOWAIT 
	SCATTER TO laData BLANK 
	lcTemp = laTextArray[i]
	FOR j = 1 TO lnFieldCounts
		laData[j] = STRTRAN(IIF(AT("|",lcTemp) = 0, lcTemp, LEFT(lcTemp,AT("|",lcTemp)-1)),"|","")
		laData[j] = STRTRAN(laData[j], '"','')	
		laData[j] = IIF(laData[j] = "NULL", "", laData[j])	
		DO CASE 
		CASE INLIST(j , 9, 16, 17, 18, 32, 33, 34, 35)
			laData[j] = SUBSTR(laData[j], 1,2)+"/"+SUBSTR(laData[j], 3, 2)+"/"+RIGHT(laData[j], 4)
			laData[j] = CTOD(laData[j])
			IF !EMPTY(laData[j])
				IF INLIST(j, 16, 17, 18)
					laData[j] = DATETIME(YEAR(laData[j]), MONTH(laData[j]), DAY(laData[j]), 12, 01)	
					IF j = 18
						laData[j] = DATETIME(YEAR(laData[j]), MONTH(laData[j]), DAY(laData[j]), 12, 00)	
					ENDIF 
				ELSE 
					laData[j] = DATETIME(YEAR(laData[j]), MONTH(laData[j]), DAY(laData[j]), 12, 00)						
				ENDIF 	
			ENDIF
		CASE j = 28
			laData[j] = 1000	
		ENDCASE  	
		*	
		IF AT("|",lcTemp) # 0
			lcTemp = SUBSTR(lcTemp,AT("|",lcTemp)+1)
		ENDIF 	
	ENDFOR 
	laData[3] = IIF(TYPE("laData[3]") = "N", ALLTRIM(STR(laData[3])), laData[3])	
	laData[38] = "KPI1666"
	SELECT plan_id, description FROM cims!plan2cat WHERE title = ALLTRIM(laData[36]) INTO ARRAY aPlan
	IF _TALLY <> 0
		laData[3] = ALLTRIM(aPlan[2])+" แผน "+ALLTRIM(laData[3])
		laData[38] = aPlan[1]
	ELSE 
		laData[3] = ICASE(laData[36] = "5P01", "PA Happy life Plan ", laData[36] = "1P01", "พิทักษ์ภัย แผน ", laData[36] = "7P01", "ยิ้มได้ สุขใจ แผน ", laData[36] = "7P02", "Senior Care แผน ", "")+ ALLTRIM(laData[3])	
	ENDIF 
	laData[37] = ldDate
	laData[39] = STRTRAN(laData[1], "-", "")
	laData[40] = ALLTRIM(laData[6])+" "+ALLTRIM(laData[7])
	INSERT INTO (lcdbf) FROM ARRAY laData
ENDFOR 
BROWSE 
USE 