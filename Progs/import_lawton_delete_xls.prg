CLEAR 
SET PROCEDURE TO progs\utility
lcDataFile = GETFILE("XLS", "Lawton data", "Select")
IF EMPTY(lcDataFile)
	RETURN 
ENDIF 
llCovert = .F.
lcDbf = STRTRAN(lcDataFile, ".XLS", ".DBF")
IF FILE(lcdbf)
	llCovert = MESSAGEBOX("พบไฟล์ที่แปลงเสร็จแล้ว ต้องการใช้ไฟล์นี้ กด Yes แปลงใหม่ กด No",4+32+256, "Confirm") = 7	
ENDIF 	

IF llConvert
	oExcel = CREATEOBJECT("Excel.Application")
	oWorkBook = oExcel.workbooks.open(lcDataFile)

	oexcel.ActiveWindow.Activate
	oexcel.ActiveWindow.FreezePanes = .F.
	*
	oSheet = oWorkBook.worksheets(1)
	CREATE DBF (lcDbf) FREE (cardno C(25), Policy_no C(30), fullname C(80), dob D, Effdate T, Expdate T, deduc Y, scheme C(30), ;
		programe C(20), canceldate D)
	***************************************************
	lnFieldCount = 10
	lnRow = 2
	DIMENSION laData[10]
	DO WHILE !ISNULL(oSheet.Cells(lnRow, 2).Value)
		WAIT WINDOW TRANSFORM(RECNO(), "999,999") NOWAIT 
		FOR i = 1 TO lnFieldCount
			laData[i] = oSheet.Cells(lnRow,i).Value
			DO CASE 
			CASE i = 1
				IF ISNULL(laData[i])
					laData[i] = ""
				ELSE 	
					IF TYPE("laData[1]") = "N"
						laData[1] = STRTRAN(STR(laData[1]), " ", "")
					ELSE 
						laData[1] = STRTRAN(laData[1], " ", "")
					ENDIF 	
				ENDIF 	
			CASE INLIST(i, 4, 5, 6)
				IF TYPE("laData[i]") = "C"
					laData[i] = ALLTRIM(laData[i]) 			
					IF LEN(laData[i]) = 10
						laData[i] =  CTOD(LEFT(laData[i],2)+"/"+SUBSTR(laData[i],3,2)+"/"+RIGHT(laData[i],4))
					ELSE 
						laData[i] =  CTOD(LEFT(laData[i],2)+"/"+chgMonth(SUBSTR(laData[i],4,3))+"/"+RIGHT(laData[i],4))			
					ENDIF 	
				ENDIF 	
			OTHERWISE 		
				laData[i] = IIF(ISNULL(laData[i]), "", laData[i])
			ENDCASE 
		ENDFOR 
		laData[10] = IIF(EMPTY(laData[10]), DATE(), laData[10])
		IF !EMPTY(laData[2])
			INSERT INTO (lcDbf) FROM ARRAY laData
		ENDIF
		lnRow = lnRow + 1
	ENDDO
	oExcel.quit
ELSE 
	SELECT 0
	USE (lcDbf)	
ENDIF 	
BROWSE
IF MESSAGEBOX("Update Cancel Member into Table",4+32,"Message") = 6
	GO TOP 
	llClosed = .F.	
	IF !USED("member")
		llClosed = .T.
		USE cims!member IN 0
	ENDIF 	
	*
	SCAN 
		WAIT WINDOW TRANSFORM(RECNO(), "@Z 9,999") NOWAIT 		
		SCATTER MEMVAR 
		lcPolNo = "AVI"+m.policy_no
		IF SEEK(lcPolNo, "member", "policy_no")
			REPLACE member.expiry WITH m.expdate, ;
				member.canceldate WITH m.expdate, ;
				member.adjcancel WITH  m.canceldate, ;
			 	member.polstatus WITH  "C"
		ENDIF 	 	
	ENDSCAN 	
ENDIF 
USE 
IF llClosed
	USE IN member
ENDIF 	
=MESSAGEBOX("Finished.....")