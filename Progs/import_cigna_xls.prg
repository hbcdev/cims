CLEAR 
SET PROCEDURE TO progs\utility
lcDataFile = GETFILE("XLS", "SMG data", "Select")
IF EMPTY(lcDataFile)
	RETURN 
ENDIF 
********************
lcDbf = STRTRAN(lcDataFile, ".XLS", ".DBF")

CREATE DBF (lcDbf) FREE (fundname C(10), sponsor C(10), prodcode C(10), prodtype C(2), cover_op C(2), progress C(2), policy_no C(30), pol_status C(1), title C(20), name C(44), surname C(44), ;
	natid C(20), dob D, gender C(1), title_p C(20), name_p C(44), surname_p C(44), natid_p C(20), dob_p D, gender_p C(1), addr1_p C(70), addr2_p C(70), addr3_p C(50), addr4_p C(50), addr5_p C(50), ;
	addr6_p C(50), zipcode C(20), country C(2), o_phone C(20), h_phone C(20), mobile C(20), email C(60), effdate T, expdate T, paiddate T, pay_freq C(1), pol_name C(50), pol_group C(20), plan C(20), plan_id C(10))

oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.workbooks.open(lcDataFile)

oexcel.ActiveWindow.Activate
oexcel.ActiveWindow.FreezePanes = .F.
oSheet = oWorkBook.worksheets(1)
	
?DBF()
lcDate = RIGHT(JUSTFNAME(DBF()),12)
ldDate = CTOD(LEFT(lcDate, 2)+"/"+SUBSTR(lcDate,3,2)+"/"+SUBSTR(lcDate, 5, 4))
***************************************************
lnFieldCount = 36
lnRow = 2
DIMENSION laData[40]
DO WHILE !ISNULL(oSheet.Cells(lnRow, 7).Value)
	WAIT WINDOW TRANSFORM(RECNO(), "999,999") NOWAIT 
	FOR i = 1 TO lnFieldCount
		laData[i] = oSheet.Cells(lnRow,i).Value
		DO CASE 
		CASE INLIST(i, 13, 19, 33, 34, 35)
			laData[i] = IIF(ISNULL(laData[i]), {}, laData[i])
			IF EMPTY(laData[i])
				laData[i] = {}
			ENDIF 	
			IF TYPE("laData[i]") = "C"
				laData[i] = CTOD(laData[i])
			ENDIF 				
			IF INLIST(i, 33, 34)
				IF EMPTY(laData[i])
					laData[i] = {}
				ELSE 	
					laData[i] = DATETIME(YEAR(laData[i]), MONTH(laData[i]), DAY(laData[i]), 00, 00)
				ENDIF 	
			ENDIF 
			IF i = 35 
				IF !EMPTY(laData[i])
					laData[i] = laData[i]-1
					laData[i] = DATETIME(YEAR(laData[i]), MONTH(laData[i]), DAY(laData[i]), 23, 59)
				ENDIF 	
			ENDIF 					
		OTHERWISE 		
			laData[i] = IIF(ISNULL(laData[i]), "", laData[i])
			IF TYPE("laData[i]") = "N"
				laData[i] = LTRIM(STR(laData[i]))
			ENDIF 	
		ENDCASE 
	ENDFOR
	***
	IF EMPTY(laData[35])
		DO CASE 
		CASE laData[8] = "A" &&  มีผลบังคับ
			laData[35] = GOMONTH(laData[33], 1)
		CASE laData[8] = "S" &&  รอชำระเบี้ย
			laData[35] = GOMONTH(laData[33], 1)		
		CASE laData[8] = "T" &&  ยกเลิกกรมธรรม์ ไม่ชำระเบี้ย
			laData[35] = laData[33]
		ENDCASE 
	ENDIF 
	***
	laData[37] = ALLTRIM(laData[10])+" "+ALLTRIM(laData[11])	
	laData[38] = laData[7]
	laData[39] = ALLTRIM(laData[3])+"-"+ALLTRIM(laData[4])
	laData[40] = "CIG1472"
	IF !EMPTY(laData[7])
		INSERT INTO (lcDbf) FROM ARRAY laData
	ENDIF
	lnRow = lnRow + 1
ENDDO
BROWSE 
USE 
=MESSAGEBOX("Finished.....")
oExcel.quit 