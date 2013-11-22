CLEAR 
CLOSE ALL 
SET PROCEDURE TO progs\utility
lcDataFile = GETFILE("XLS", "SMG Claim Receive data", "Select")
IF EMPTY(lcDataFile)
	RETURN 
ENDIF 
*
OPEN DATABASE \\192.168.100.5\hips\data\cims.DBC
lcDbf = STRTRAN(lcDataFile, ".XLS", ".DBF")
lcErrorFile = ADDBS(JUSTPATH(lcDataFile))+"Error_"+JUSTFNAME(lcDataFile)
oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.workbooks.open(lcDataFile)

oexcel.ActiveWindow.Activate
oexcel.ActiveWindow.FreezePanes = .F.
*
oSheet = oWorkBook.worksheets(1)
CREATE CURSOR curClaimrcv (no I, clientname V(80), branch V(40), receive D, senddate D, note C(250), billamt I, charge Y)
***************************************************
lldebug = .t.
lnFieldCount = 8
lnRow = 2
DIMENSION laData[8]
DO WHILE !ISNULL(oSheet.Cells(lnRow, 2).Value)
	WAIT WINDOW TRANSFORM(lnRow-1, "999,999") NOWAIT 
	FOR i = 1 TO lnFieldCount
		laData[i] = oSheet.Cells(lnRow,i).Value
	ENDFOR 
	IF !EMPTY(laData[2])
		laData[6] = IIF(ISNULL(laData[6]), "", laData[6])
		lcName = ALLTRIM(LEFT(laData[2], AT(" ", laData[2])))
		lcSurname = SUBSTR(laData[2], AT(" ", laData[2]))		
		loValue = getCustByFullName("SMG", lcName, lcSurname)
		IF ISNULL(loValue)		
			INSERT INTO cims!batch (client_name, sendfrom, receive_date, senddate, note, total, charge, fundcode) ;
			VALUES (laData[2], laData[3], laData[4], laData[5], laData[6], laData[7], laData[8], "SMG")
			*
			INSERT INTO curClaimrcv FROM ARRAY laData
		ELSE 
			INSERT INTO cims!batch (client_name, sendfrom, receive_date, senddate, note, total, charge, fundcode, cardno, natid, l_user, l_update) ;
			VALUES (laData[2], laData[3], laData[4], laData[5], laData[6], laData[7], laData[8], loValue.fundcode, loValue.cardno, loValue.natid, UPPER(SUBSTR(ID(), AT("#", ID())+2)), DATETIME())
		ENDIF 	
	ENDIF
	lnRow = lnRow + 1
ENDDO
BROWSE 
COPY TO (lcErrorFile) TYPE XL5
=MESSAGEBOX("Finished.....")
USE 
oExcel.quit


FUNCTION chgMonth(tcMonth)

DIMENSION laMonth[12]
laMonth[1] = "JAN"
laMonth[2] = "FEB"
laMonth[3] = "MAR"
laMonth[4] = "APR"
laMonth[5] = "MAY"
laMonth[6] = "JUN"
laMonth[7] = "JUL"
laMonth[8] = "AUG"
laMonth[9] = "SEP"
laMonth[10] = "OCT"
laMonth[11] = "NOV"
laMonth[12] = "DEC"

RETURN STR(ASCAN(laMonth, UPPER(tcMonth)),2)
