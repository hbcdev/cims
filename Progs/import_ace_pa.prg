*SET PROCEDURE TO progs\utility
*lcSourceFile = GETFILE("TXT")
*LEFT(RIGHT(lcSourcefile,7),3)
*ldDate = INPUTBOX("Enter Date:")
*ldDate = CTOD(ldDate)
*lcDbf = PUTFILE("Target name", ALLTRIM(STR(YEAR(ldDate)))+"-"+ALLTRIM(STR(MONTH(ldDate)))+"-"+ALLTRIM(STR(DAY(ldDate)))+" PA Member "+STRTRAN(DTOC(ldDate), "/", "")+LEFT(RIGHT(lcSourcefile,7),3),"DBF")
*************************************
IF EMPTY(lcSourceFile)
	RETURN 
ENDIF 
*	
IF FILE(lcDbf)
	=MESSAGEBOX(lcDbf+" is exist")
	RETURN 
ENDIF 
*	
SELECT 0
CREATE TABLE (lcDbf) FREE (branch_cde C(20), province C(20), policy_no c(30),  pol_holder C(20), plan C(20), inf_date D, exp_date D, cust_id C(20), ;
	title C(20), first_nam C(40), middle_nam C(40), last_name c(40), sex C(1), dob D, age I, ;	
	address_1 C(40), address_2 c(40), address_3 C(40), address_4 C(40), pcode C(5), premium Y, medical Y, package C(20), ;
	cause1 C(10), cause2 C(10), cause3 C(10), cause4 C(10), cause5 C(10), cause6 C(10), cause7 C(10), cause8 C(10), ;
	cause9 C(10), cause10 C(10), cause11 C(10), cause12 C(10), adj_date D)

*
?DBF()
lnLines = ALINES(laTextArray,FILETOSTR(lcSourceFile))
lcDelimeter = ";"
FOR i = 2 TO lnLines-1
	WAIT WINDOW TRANSFORM(i, "@Z 99,999") NOWAIT 
	lnFieldCounts = FCOUNT()
	SCATTER TO laData BLANK 
	lcTemp = laTextArray[i]
	FOR j = 1 TO lnFieldCounts
		laData[j] = STRTRAN(IIF(AT(";",lcTemp) = 0, lcTemp, LEFT(lcTemp,AT(";",lcTemp)-1)),'"','')
		IF j = 3
			IF laData[j] = "N/A"
				laData[j] = ""
			ENDIF 	
		ENDIF 			
		IF INLIST(j ,6,7,14, 36)
			ldDateCvt = trandate(laData[j])
			IF EMPTY(ldDateCvt)	
				lcDate = laData[j]		
				laData[j] = CTOD(LEFT(lcDate,2)+"/"+SUBSTR(lcDate,3,2)+"/"+STR(VAL(SUBSTR(lcDate,5,4))-543,4))
			ELSE 
				laData[j] = DATE(YEAR(ldDateCvt)-543, MONTH(ldDateCvt), DAY(ldDateCvt))				
			ENDIF 	
		ENDIF 	
		IF INLIST(j ,15, 21, 22)
			laData[j] = VAL(laData[j])
		ENDIF 	
		*
		lcTemp = SUBSTR(lcTemp,AT(";",lcTemp)+1)
	ENDFOR 
	INSERT INTO (lcdbf) FROM ARRAY laData
ENDFOR
BROWSE 
USE