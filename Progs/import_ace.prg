*SET PROCEDURE TO progs\utility
CurDate = DTOC(DATE()-1)
CurDate = INPUTBOX("Enter Date:", "Date to covert", curDate)
CurDate = CTOD(CurDate)
IF EMPTY(CurDate)
	RETURN 
ENDIF 	
SET DEFAULT TO ?
lnAmountFiles = ADIR(laAce, "*.TXT")
FOR lnFile = 1 TO lnAmountFiles
	DO ConvertToDbf WITH laAce[lnFile, 1]
ENDFOR 		
**********************************
PROCEDURE ConvertToDbf
PARAMETERS tcSourceFile

lcSourceFile = tcSourceFile
IF EMPTY(lcSourceFile)
	EXIT 
ELSE 	
	DO CASE 
	CASE "HB" $ lcSourcefile
		lcDbf = ALLTRIM(STR(YEAR(CurDate)))+"-"+ALLTRIM(STR(MONTH(CurDate)))+"-"+ALLTRIM(STR(DAY(CurDate)))+" HB Member "+STRTRAN(DTOC(CurDate), "/", "")+LEFT(RIGHT(lcSourcefile,7),3)
		IF !EMPTY(lcDbf)
			DO progs\import_ace_hb
		ENDIF 	
	CASE "HS" $ lcSourcefile
		lcDbf = ALLTRIM(STR(YEAR(CurDate)))+"-"+ALLTRIM(STR(MONTH(CurDate)))+"-"+ALLTRIM(STR(DAY(CurDate)))+" HS Member "+STRTRAN(DTOC(CurDate), "/", "")+LEFT(RIGHT(lcSourcefile,7),3)
		IF !EMPTY(lcDbf)				
			DO progs\import_ace_hs
		ENDIF 	
	CASE "ME" $ lcSourcefile
		lcDbf = ALLTRIM(STR(YEAR(CurDate)))+"-"+ALLTRIM(STR(MONTH(CurDate)))+"-"+ALLTRIM(STR(DAY(CurDate)))+" PA Member "+STRTRAN(DTOC(CurDate), "/", "")+LEFT(RIGHT(lcSourcefile,7),3)		
		IF !EMPTY(lcDbf)				
			DO progs\import_ace_pa
		ENDIF 	
	ENDCASE
ENDIF 
