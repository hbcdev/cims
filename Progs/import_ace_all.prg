SET PROCEDURE TO progs\utility
lcSourceFile = GETFILE("TXT")
lcDbf = STRTRAN(lcSourceFile, "TXT", "DBF")
*************************************
IF EMPTY(lcSourceFile)
	RETURN 
ENDIF 
*	
*!*	IF FILE(lcDbf)
*!*		=MESSAGEBOX(lcDbf+" is exist")
*!*		RETURN 
*!*	ENDIF 
*
SELECT 0
CREATE TABLE (lcDbf) FREE (policy_grp C(30), plan_type C(1), prodcode C(20), cust_id C(20), title C(20), name C(40), surname C(40), ;
	sex C(1), dob D, age I, address1 C(40), address2 c(40), country c(40), postcode C(5), telephone C(20), ;
	poldate T, effdate T, expdate T, premium Y, exclusion C(40), agent C(20), agency C(40), paymode C(2), renew I, polstatus C(1), ;
	payer C(100), medical Y, hb_benefit Y, endorse_no C(30), enddate D, endtype C(1), paiddate D, rein_date D, lapsedate D, canldate D, ;
	policy_no C(30), pol_type C(2), plan C(20), reindate D, canceldate D, custtype C(1), adddate D, prodcat C(2), oldexpdate T, plan_id C(10))
*
?DBF()
lnSelect = SELECT()
*
STORE "" TO lcOldPolNo, lcOldPlan

DIMENSION laData[45]
lnLines = ALINES(laTextArray,FILETOSTR(lcSourceFile))
llError = .F.
lcDelimeter = ","
lnFieldCounts = 35
FOR i = 2 TO lnLines-1
	WAIT WINDOW TRANSFORM(i, "@Z 99,999") NOWAIT 
	STORE "" TO laData
	lcTemp = laTextArray[i]
	FOR j = 1 TO lnFieldCounts
		laData[j] = ALLTRIM(STRTRAN(IIF(AT(",",lcTemp) = 0, lcTemp, LEFT(lcTemp,AT(",",lcTemp)-1)),'"',''))
		DO CASE 
		CASE j = 2
			laData[41] = ICASE(laData[j] = "H", "I", laData[j] = "B", "B", laData[j])
		CASE  INLIST(j ,9, 16, 17, 18, 30, 32, 33, 34, 35)
			IF EMPTY(laData[j])	
				laData[j] = {}
			ELSE 				
				laData[j] = CTOD(RIGHT(laData[j], 2)+"/"+SUBSTR(laData[j], 5, 2)+"/"+LEFT(laData[j], 4))
				IF YEAR(laData[j]) > 2500
					laData[j] = DATE(YEAR(laData[j])-543, MONTH(laData[j]), DAY(laData[j]))
				ENDIF 	
				IF INLIST(j, 16, 17, 18)
					IF j = 17
						laData[16] = IIF(EMPTY(laData[16]), laData[17], laData[16])
					ENDIF 	
					laData[j] = DATETIME(YEAR(laData[j]), MONTH(laData[j]), DAY(laData[j]), 00, 00)
				ENDIF 	
			ENDIF 	
		ENDCASE 
		lcTemp = SUBSTR(lcTemp,AT(",",lcTemp)+1)
	ENDFOR 
	******************
	IF INLIST(LEFT(laData[1], 2), "A0", "P0")
		laData[36] = SUBSTR(laData[1], 3)
	ELSE 
		laData[36] = laData[1]
	ENDIF 		
	****************************
	SELECT description, IIF(EMPTY(same_as), plan_id, same_as) AS plan_id FROM cims!plan ;
	WHERE prod_id  like "ACE%" AND ALLTRIM(title) = ALLTRIM(laData[3]) INTO CURSOR curMemb
	IF _TALLY > 0
		IF INLIST(LEFT(laData[1], 2), "A0", "P0")
			laData[38] = LEFT(curMemb.description,20)
		ELSE 
			laData[38] = laData[3]
		ENDIF 				
		laData[45] = curMemb.plan_id
	ELSE 
		IF INLIST(laData[41], "A", "P")
			laData[38] = laData[3]
			laData[45] = "ACE1409"
		ELSE 
			llError = .T.	
		ENDIF 	
	ENDIF 	
	***********************************
	IF laData[25] = "C"
		IF laData[36] = lcOldPolNo AND laData[38] = lcOldPlan
			laData[38] = laData[3]	
		ENDIF 	
		IF EMPTY(laData[34])
			laData[44] = laData[18]
			laData[18] = laData[35]
		ELSE 
			laData[44] = laData[18]
			laData[18] = laData[34]
		ENDIF 			
	ENDIF 	
	***********************************	
	laData[4] = IIF("N/A" $ laData[4], "", laData[4])
	laData[37] = LEFT(laData[1], 2)	
	laData[39] = IIF(EMPTY(laData[34]), {}, laData[33])			
	laData[40] = IIF(laData[25] = "C", laData[35], {})			
	laData[42] = CTOD(LEFT(RIGHT(lcDbf, 12), 2)+"/"+SUBSTR(RIGHT(lcDbf, 12), 3, 2)+"/"+SUBSTR(RIGHT(lcDbf, 12), 5, 4))
	laData[43] = LEFT(laData[3], 2)
	*******************************
	IF laData[16] > laData[17]
		ltEff = laData[16]
		laData[16] = laData[17]
		laData[17] = ltEff
	ENDIF 	
	*******************************	
	INSERT INTO (lcdbf) FROM ARRAY laData
	*
	lcOldPolNo = laData[36]
	lcOldPlan = laData[38]
	*
ENDFOR
USE IN curMemb
*
lcPath = JUSTPATH(lcDbf)
lcHsDbf = ADDBS(lcPath)+"HS_"+JUSTFNAME(lcdbf)
lcHbDbf = ADDBS(lcPath)+"HB_"+JUSTFNAME(lcdbf)
lcMeDbf = ADDBS(lcPath)+"PA_"+JUSTFNAME(lcdbf)
*
SELECT (lnSelect)
BROWSE 

COPY TO (lcHbDbf) FOR plan_type = "B"
COPY TO (lcHsDbf) FOR plan_type = "H"
COPY TO (lcMeDbf) FOR !INLIST(plan_type, "B", "H")
*
USE