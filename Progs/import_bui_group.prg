SET PROCEDURE TO progs\utility

lcSourceFile = GETFILE("CSV")
lcDbf = STRTRAN(lcSourceFile, ".CSV", ".DBF")
*************************************
IF EMPTY(lcSourceFile)
	RETURN 
ENDIF 
*	
IF FILE(lcDbf)
	=MESSAGEBOX(lcDbf+" is exist")
*	RETURN 
ENDIF 
*	
SELECT 0
CREATE TABLE (lcDbf) FREE (policy_no c(30), person_no I, client_no c(20), title C(20), name C(50), surname C(50), dob D, age I, plan C(20), employee C(60), relation C(20), old_pol C(30), ;
	eff_date D, exp_date D, pol_name C(60))

*
?DBF()
lnLines = ALINES(laTextArray,FILETOSTR(lcSourceFile))
FOR i = 2 TO lnLines
	WAIT WINDOW TRANSFORM(i-1, "@Z 99,999") NOWAIT 
	lnFieldCounts = FCOUNT()
	SCATTER TO laData BLANK 
	lcTemp = laTextArray[i]
	IF !EMPTY(ALLTRIM(lcTemp))	
		FOR j = 1 TO lnFieldCounts
			IF AT(",",lcTemp) # 0	
				IF LEFT(lcTemp, 1) = '"'
					laData[j] = STRTRAN(SUBSTR(lcTemp, 2, AT('"',SUBSTR(lcTemp,2))-1), '"','')
				ELSE 					
					laData[j] = STRTRAN(LEFT(lcTemp,AT(",",lcTemp)-1),'"','')
				ENDIF 	
			ELSE
				laData[j] = STRTRAN(lcTemp, '"', '')	
			ENDIF 	
			IF INLIST(j , 7, 13, 14)
				laData[j] = CTOD(laData[j])
			ENDIF 	
			IF INLIST(j ,2,8)
				laData[j] = VAL(laData[j])
			ENDIF 	
			*		
			IF AT(",",lcTemp) # 0
				IF LEFT(lcTemp,1) = '"'
					lcTemp = SUBSTR(lcTemp, AT('"',SUBSTR(lcTemp,2))+3)			
				ELSE 	
					lcTemp = SUBSTR(lcTemp,AT(",",lcTemp)+1)
				ENDIF 	
			ENDIF 	
		ENDFOR 
		INSERT INTO (lcdbf) FROM ARRAY laData
	ENDIF 	
ENDFOR
BROWSE 
USE 