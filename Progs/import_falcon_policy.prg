CLEAR 
SET SAFETY OFF 
SET PROCEDURE TO progs\utility
lcDataFile = GETFILE("XLS", "Falcon data", "Select")
IF EMPTY(lcDataFile)
	RETURN 
ENDIF 
********************
lcDbf = STRTRAN(lcDataFile, ".XLS", ".DBF")
lcErrorFile = STRTRAN(lcDataFile, ".XLS", ".TXT") 


oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.workbooks.open(lcDataFile)

oexcel.ActiveWindow.Activate
oexcel.ActiveWindow.FreezePanes = .F.
*
oSheet = oWorkBook.worksheets(1)
CREATE DBF (lcDbf) FREE (Policy_no C(30), name C(50), surname C(50), cust_id C(20), quotation C(50), adjdate D)
*
lcDate = LEFT(RIGHT(DBF(), 12), 8)
ldDate = CTOD(LEFT(lcDate,2)+"/"+SUBSTR(lcDate,3,2)+"/"+RIGHT(lcDate,4))
************************************************************
llError = .F.
lnFieldCount = 5
lnRow = 2
DIMENSION laData[6]
DO WHILE !ISNULL(oSheet.Cells(lnRow, 4).Value)
	WAIT WINDOW TRANSFORM(RECNO(), "999,999") NOWAIT 
	FOR i = 1 TO lnFieldCount
		laData[i] = oSheet.Cells(lnRow,i).Value
		laData[i] = IIF(ISNULL(laData[i]), "", laData[i])
		IF TYPE("laData[i]") = "N"
			laData[i] = LTRIM(STR(laData[i]))
		ENDIF 	
	ENDFOR
	IF !EMPTY(laData[1])
		laData[6] = ldDate
		INSERT INTO (lcDbf) FROM ARRAY laData
	ENDIF
	lnRow = lnRow + 1
enddo
oExcel.quit

BROWSE 

if messagebox("ต้องกาตอัพเทดข้อมูลไป เข้าระบบ หรือไม่",4+32+256,"Update Falcon Member Policy No") = 6
	go top
	scan 
		wait window transform(recno(),"@Z 999,999") nowait 
		scatter memvar
		if empty(m.policy_no) and empty(m.cust_id) and empty(m.name) and empty(m.surname) and empty(m.quotation)
			llError = .T.
			lcError = alltrim(m.policy_no)+" "+alltrim(quotation)+" "+alltrim(name)+" "+alltrim(surname)
			=StoreErrorFile(lcError,lcErrorFile)
		else
			if updateFniPolicy('FAL',m.policy_no,m.name,m.surname,m.cust_id,m.quotation) = 0
				llError = .T.
				lcError = "No New Data "+alltrim(m.policy_no)+" "+alltrim(quotation)+" "+alltrim(name)+" "+alltrim(surname)
				=StoreErrorFile(lcError,lcErrorFile)				
			else
				do updateToSQL with m.policy_no,m.cust_id,alltrim(m.quotation)
			endif			
		endif	
	endscan		
endif	

if llError
	modify file (lcErrorFile) noedit
endif 	
USE 
=MESSAGEBOX("Finished.....")
******************************************
function StoreErrorFile(tcError,tcFile)
 =strtofile(tcError+chr(13), tcFile,1)

****************************************** 
procedure updateToSQL
parameters tcFundCode, tcPolicyNo,tcNatId,tcQuoNo

lcSQL = "{call sp_updateFniPolicy(?tcPolicyNo, ?tcNatId, ?tcQuoNo)}"
lnSuscess = sqlexec(gnConn,lcSql)