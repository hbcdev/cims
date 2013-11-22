SET CENTURY ON 
SET CENTURY TO 19
 
lcSourceFile = GETFILE("XLS")
lcDbf = STRTRAN(lcSourceFile, ".XLS", ".DBF")
*************************************
SET SAFETY OFF 
IF EMPTY(lcSourceFile)
	RETURN 
ENDIF 
*	
IF FILE(lcDbf)
	=MESSAGEBOX(lcDbf+" is exist")
*	RETURN 
ENDIF 

SELECT 0
CREATE TABLE (lcDbf) FREE (hcurdt D, hpno C(30),  hplan C(20), hhblmt Y, hcusid C(20), htitle C(20), hname C(50), hmname C(50), hsname C(50), ;
	hsex C(1), hdob D, hage I, haddr1 C(50), haddr2 C(50), haddr3 C(50), haddr4 C(50), hcntry C(30), hpost C(5), htel C(50), hconper C(20), hcontel C(20), ;		
	hpnodte T, heffdte T, hexpdte T, hprem Y, hexclu C(30), hagent1 C(40), hbagunn C(40), hagenc1 C(40), hagflag1 C(1), hbagnamf C(40), hbagname C(40), ;
	hbadd1 C(50), hbadd2 C(50), hbadd3 C(50), hbadd4 C(50), hbadd5 C(50), hbadd6 C(50), hbpost C(5), hbtel1 C(30), hbtel2 C(30), hbtel3 C(30), hbrnnm1 C(50), ;
	hagent2 C(50), hbagunn2 C(40), hagenc2 C(40), hagflag2 C(1), hbagnamf2 C(40), hbagname2 C(40), hbadd12 C(50), hbadd22 C(50), hbadd32 C(50), ;
	hbadd42 C(50), hbadd52 C(50), hbadd62 C(50), hbpost2 C(5), hbtel12 C(30), hbtel22 C(30), hbtel32 C(30), hbrnnm2 C(50), ;
	hbpolyear C(10), hpaymod C(1), holdpln C(10), holdprm I, hoccup C(20), holdocc C(10), hoccls I, hadjdte D, hrenew I, hpnosts I, hempty C(10), hadjprm Y, ;
	hpayer C(50),  htc I, hteff C(10), htlpd C(10))	
*
?DBF()
*
oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.workbooks.open(lcSourceFile)
oexcel.ActiveWindow.Activate
oexcel.ActiveWindow.FreezePanes = .F.
IF "MEA" $ DBF()
	oSheet = oWorkBook.worksheets(2)
ELSE 
	oSheet = oWorkBook.worksheets(1)
ENDIF 	
*****************
i = 2
lnFieldCounts = FCOUNT()
DO WHILE !ISNULL(oSheet.Cells(i, 1).Value)
	WAIT WINDOW TRANSFORM(i-1, "@Z 99,999") NOWAIT 
	SCATTER TO laData BLANK 
	FOR j = 1 TO lnFieldCounts
		laData[j] = oSheet.Cells(i, j).Value
		DO CASE 	
		CASE INLIST(j ,1,11,22,23,24)
			IF !INLIST(TYPE("laData[j]"), "T", "D")
				laData[j] = CTOD(laData[j])
			ENDIF 	
		CASE INLIST(j ,4, 12,25,69,74)
			IF !INLIST(TYPE("laData[j]"), "N", "Y")		
				laData[j] = VAL(laData[j])
			ENDIF 	
		CASE INLIST(j, 5, 46)
			IF !ISNULL(laData[j])
				IF TYPE("laData[j]") = "N"
					laData[j] = ALLTRIM(STR(laData[j],13))
				ENDIF 	
			ENDIF 	
		OTHERWISE 
			DO CASE 
			CASE INLIST(TYPE("laData[j]"), "N", "Y")		
				laData[j] = ALLTRIM(STR(laData[j]))	
			CASE INLIST(TYPE("laData[j]"), "T", "D")		
				laData[j] = laData[j]
			OTHERWISE 				
				laData[j] = ALLTRIM(laData[j])
			ENDCASE 	
		ENDCASE 
		IF ISNULL(laData[j])
			laData[j] = ""
		ENDIF 	
	ENDFOR 
	INSERT INTO (lcdbf) FROM ARRAY laData	
	i = i + 1			
ENDDO
oExcel.quit
BROWSE 
USE 
SET CENTURY TO 
