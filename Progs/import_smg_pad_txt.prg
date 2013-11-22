lcSourceFile = GETFILE("TXT")
lcDbf = STRTRAN(lcSourceFile, ".TXT", ".DBF")
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
*lcDbf = "d:\hips\data\smg_scb_data.dbf"
SELECT 0	
lnSelect = SELECT()
CREATE TABLE (lcDbf) FREE (title V(20), firstname V(40), lastname V(40), selldate D, sellbranch V(10), effdate T, expdate T, plans V(20), creditcard V(20), ;
refno V(20), premium Y, dfpolicyno V(30), statuscard V(10), importdte D, idcardtype V(10), idcardno V(20), refaccno V(10), pa_type V(10), status V(10), remark V(100), medical Y)
*
*!*	SET DEFAULT TO ?
*!*	lnAmountFiles = ADIR(laSmg, "*.TXT")
*!*	FOR lnFile = 1 TO lnAmountFiles
*!*		DO ConvertData WITH laSmg[lnFile, 1]
*!*	ENDFOR 		

*PROCEDURE convertData
*PARAMETERS lcSourceFile

?lcSourceFile
STORE 0 TO lnNew, lnUpdate
lcDate = RIGHT(JUSTFNAME(DBF()),12)
ldDate = CTOD(LEFT(lcDate, 2)+"/"+SUBSTR(lcDate,3,2)+"/"+SUBSTR(lcDate, 5, 4))
lnLines = ALINES(laTextArray,FILETOSTR(lcSourceFile))
FOR i = 2 TO lnLines
	WAIT WINDOW TRANSFORM(i-1, "@Z 999,999")+"/"+TRANSFORM(lnLines, "@Z 999,999") AT 25, 45 NOWAIT 
	lnFieldCounts = FCOUNT()
	SCATTER TO laData BLANK 
	lcTemp = laTextArray[i]
	FOR j = 1 TO lnFieldCounts - 1
		laData[j] = STRTRAN(IIF(AT(";",lcTemp) = 0, lcTemp, LEFT(lcTemp,AT(";",lcTemp)-1)),'"','')
		laData[j] = STRTRAN(laData[j], '"','')		
		DO CASE 
		CASE INLIST(j , 4, 6, 7, 14)
			laData[j] = IIF(ISNULL(laData[j]), {}, laData[j])
			IF EMPTY(laData[j])
				laData[j] = {}
			ENDIF 	
			IF TYPE("laData[j]") = "C"
				laData[j] = CTOD(laData[j])
			ENDIF 				
			IF INLIST(j, 6, 7)
				IF EMPTY(laData[j])
					laData[j] = {}
				ELSE 	
					laData[j] = DATETIME(YEAR(laData[j]), MONTH(laData[j]), DAY(laData[j]), 12, 00)
				ENDIF 	
			ENDIF 	
		CASE j = 8
			laData[21] = ICASE(laData[j] = "S", 5000, laData[j] = "G", 25000, 0)
			laData[j] = 	ICASE(laData[j] = "S", "Silver", laData[j] = "G", "Gold", laData[j])
		CASE j = 11
			laData[j] = VAL(STRTRAN(laData[j], ",", ""))
		ENDCASE
		IF AT(";",lcTemp) # 0
			lcTemp = SUBSTR(lcTemp,AT(";",lcTemp)+1)
		ENDIF 	
	ENDFOR 	
	INSERT INTO (lcdbf) FROM ARRAY laData
ENDFOR
*!*	lcMessage = "Update: "+TRANSFORM(lnUpdate, "@Z 999,999") +CHR(13)+;
*!*		"New: "+TRANSFORM(lnNew, "@Z 999,9999") +CHR(13)+;
*!*		"Total: "+TRANSFORM(RECCOUNT(lnSelect), "@Z 999,999") +CHR(13)	
*!*	=MESSAGEBOX(lcMessage,0,"SMG Convert")	
*!*	** 