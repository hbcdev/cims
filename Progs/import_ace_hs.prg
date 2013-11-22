*SET PROCEDURE TO progs\utility
*lcSourceFile = GETFILE("TXT")
*ldDate = INPUTBOX("Enter Date:")
*ldDate = CTOD(ldDate)
*lcDbf = PUTFILE("Target name", ALLTRIM(STR(YEAR(ldDate)))+"-"+ALLTRIM(STR(MONTH(ldDate)))+"-"+ALLTRIM(STR(DAY(ldDate)))+" HS Member "+STRTRAN(DTOC(ldDate), "/", "")+LEFT(RIGHT(lcSourcefile,7),3),"DBF")
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
CREATE TABLE (lcDbf) FREE (policy_no c(30), plan C(20), cust_id C(20), title_nam C(20), first_nam C(40), middle_nam C(40), ;
	last_name c(40), s C(1), dob D, ag I, address_1 C(40), address_2 c(40), address_3 C(40), address_4 C(40), country c(40), pcode C(5), tel C(20), ;
	contact_pe C(40), contact_ph C(40), pol_date D, rid_date D, exp_date D, premium Y, excls C(40), agent_unit C(20), agent_no c(40), mo C(2), ;
	old_plan c(20), old_prem Y, occ_code C(20), old_occ C(20), occ_clas C(20), adj_date D, ye I, st C(10), em C(10)) 

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
		IF j = 2
			laData[j] = IIF(laData[j] = "00000000", "", ALLTRIM(STR(VAL(laData[j]))))
		ENDIF 	
		IF j = 3
			IF laData[j] = "N/A"
				laData[j] = ""
			ENDIF 	
		ENDIF 			
		IF INLIST(j ,9,20,21,22,33)
			ldDateCvt = trandate(laData[j])
			IF EMPTY(ldDateCvt)	
				lcDate = laData[j]		
				laData[j] = CTOD(LEFT(lcDate,2)+"/"+SUBSTR(lcDate,3,2)+"/"+STR(VAL(SUBSTR(lcDate,5,4))-543,4))
			ELSE 
				laData[j] = DATE(YEAR(ldDateCvt)-543, MONTH(ldDateCvt), DAY(ldDateCvt))				
			ENDIF 	
		ENDIF 	
		IF INLIST(j ,10,23,29,34)
			laData[j] = VAL(laData[j])
		ENDIF 	
		*
		lcTemp = SUBSTR(lcTemp,AT(";",lcTemp)+1)
	ENDFOR 
	INSERT INTO (lcdbf) FROM ARRAY laData
ENDFOR
BROWSE 
USE