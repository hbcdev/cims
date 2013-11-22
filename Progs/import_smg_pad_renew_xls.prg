CLEAR 
SET PROCEDURE TO progs\utility
lcDataFile = GETFILE("XLS;XLSX", "SMG data", "Select")
IF EMPTY(lcDataFile)
	RETURN 
ENDIF 
********************
lcAlias = ""
lcDbf = FORCEEXT(lcDataFile, ".DBF")
*lcDbf = ["C:\Users\admin\Documents\Health Fund\SMG\All_Renew\MEMBER_RENEW_20110404.DBF"] 
IF FILE(lcDbf)
	IF MESSAGEBOX("ต้องการแปลงข้อมูลใหม่หรือไม่",4+32+256,"Confrim") = 6
		DO CovertXls
	ENDIF 
ELSE 
	DO CovertXls
ENDIF 		
IF MESSAGEBOX("ต้องการอัพเดทข้อมูลเข้าระบบ หรือไม่",4+32+256,"Comfrim") = 7
	RETURN 
ELSE 
	DO Update2Members	
ENDIF 
USE 
******************************
*
PROCEDURE CovertXls
*
CREATE DBF (lcDbf) FREE (selldate D, oldeff T, entrydate D, cardno C(20), nextpaid T, nextfee D, neweff T, cutmonth I, importdate D, senddate D, effdate T, expdate T)
lcAlias = ALIAS()

oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.workbooks.open(lcDataFile)

oexcel.ActiveWindow.Activate
oexcel.ActiveWindow.FreezePanes = .F.
	*
oSheet = oWorkBook.worksheets(1)
	
?DBF()
lcDate = RIGHT(JUSTFNAME(DBF()),12)
ldDate = CTOD(LEFT(lcDate, 2)+"/"+SUBSTR(lcDate,3,2)+"/"+SUBSTR(lcDate, 5, 4))
***************************************************
lnFieldCount = 10
lnRow = 2
DIMENSION laData[12]
DO WHILE !ISNULL(oSheet.Cells(lnRow, 4).Value)
	WAIT WINDOW TRANSFORM(RECNO(), "999,999") NOWAIT 
	FOR i = 1 TO lnFieldCount
		laData[i] = oSheet.Cells(lnRow,i).Value
		DO CASE 
		CASE INLIST(i, 2, 5, 7)
			laData[i] = IIF(ISNULL(laData[i]), {}, laData[i])
			IF EMPTY(laData[i])
				laData[i] = {}
			ENDIF 	
			IF TYPE("laData[i]") = "C"
				laData[i] = CTOD(laData[i])
			ENDIF 	
			IF EMPTY(laData[i])
				laData[i] = {}
			ELSE 	
				laData[i] = DATETIME(YEAR(laData[i]), MONTH(laData[i]), DAY(laData[i]), 12, 00)
			ENDIF 	
		ENDCASE 
	ENDFOR
	IF !EMPTY(laData[4])
		ldDue = GOMONTH(DATE(YEAR(GOMONTH(GOMONTH(laData[2],12),1)), MONTH(GOMONTH(GOMONTH(laData[2],12),1)),1),1)-1
		IF laData[6] > ldDue
			laData[11] = DATETIME(YEAR(laData[6]), MONTH(laData[6]), DAY(laData[6]), 12, 00)
			laData[12] = GOMONTH(laData[11],12)
			laData[12] = DATETIME(YEAR(laData[12]), MONTH(laData[12]), DAY(laData[12]), 12, 00)			
		ELSE 
			laData[11] = GOMONTH(laData[2],12)
			laData[11] = DATETIME(YEAR(laData[11]), MONTH(laData[11]), DAY(laData[11]), 12, 00)
			laData[12] = GOMONTH(laData[11],12)			
			laData[12] = DATETIME(YEAR(laData[12]), MONTH(laData[12]), DAY(laData[12]), 12, 00)
		ENDIF
		laData[3] = IIF(EMPTY(laData[3]) OR ISNULL(laData[3]), {}, laData[3])
		laData[5] = IIF(EMPTY(laData[5]) OR ISNULL(laData[5]), {}, DATETIME(YEAR(laData[5]), MONTH(laData[5]), DAY(laData[5]), 12, 00))
		INSERT INTO (lcDbf) FROM ARRAY laData
	ENDIF
	lnRow = lnRow + 1
ENDDO
BROWSE 
oExcel.quit 

PROCEDURE Update2Members
*	
IF EMPTY(lcAlias)
	USE ? IN 0 ALIAS smgrenew
	lcAlias = "smgrenew"
ENDIF 
*
lnUpdate = 0
llError = .F.

SELECT (lcAlias)
GO TOP 
SCAN 
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 999,999") NOWAIT 
	SCATTER MEMVAR
	UPDATE cims!members SET members.effective_y = EVALUATE(lcAlias+".effdate"), ;
		members.start_date = IIF(EMPTY(members.start_date), members.start_date, members.effective), ;
		members.effective = EVALUATE(lcAlias+".effdate"), ;
		members.oldexpiry = IIF(EMPTY(members.oldexpiry), members.oldexpiry, members.expiry), ;
		members.expiry = EVALUATE(lcAlias+".expdate"), ;
		members.expried_y = EVALUATE(lcAlias+".nextpaid"), ;		
		members.l_submit = EVALUATE(lcAlias+".senddate"), ;
		members.lastpaid = EVALUATE(lcAlias+".senddate"), ;
		members.pay_seq = members.pay_seq+1, ;
		members.renew = IIF(members.renew = 0, 2, members.renew+1), ;
		members.adj_permium_date = EVALUATE(lcAlias+".importdate"), ;
		members.l_update = DATETIME() ;
	WHERE members.tpacode = "SMG" ;
		AND members.cardno = EVALUATE(lcAlias+".cardno") ;
		AND members.polstatus <> "C"		
	IF _TALLY = 1
		lnUpdate = lnUpdate + 1
	ELSE
		llError = .T.
		lcError = m.cardno+CHR(13)
		=STRTOFILE(lcError, "smg_renew_error.txt",.F.)	
	ENDIF
ENDSCAN
=MESSAGEBOX("Total Record: "+TRANSFORM(RECCOUNT(), "@Z 999,999")+CHR(13)+;
	"Total Update: "+TRANSFORM(lnUpdate, "@Z 999,999"), 0, "Info")
*	
IF llError
	MODIFY FILE smg_renew_error.txt NOMENU
ENDIF 		
