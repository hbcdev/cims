CLEAR 
SET PROCEDURE TO progs\utility
lcDataFile = GETFILE("XLS;XLSX", "Axa PPP data", "Select")
IF EMPTY(lcDataFile)
	RETURN 
ENDIF 
lcDbf = STRTRAN(lcDataFile, ".XLS", ".DBF")
lcDbf = iif(right(lcDbf,1) = "X", left(lcDbf,len(lcDbf)-1),lcDbf)

oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.workbooks.open(lcDataFile)

oexcel.ActiveWindow.Activate
oexcel.ActiveWindow.FreezePanes = .F.
*
oSheet = oWorkBook.worksheets(1)
CREATE DBF (lcDbf) FREE (policy_no C(30), fullname C(80), dob D, Effdate T, Expdate T, deduc Y, scheme C(30), programe V(100), remark V(200), ;
	adddate D, firstname C(40), surname C(40), groupno C(30), plan_id C(10), plan C(20), ;
	poldate T,groupname V(100), polstatus C(1), overall Y, cardno C(25),area C(10))	
***************************************************
lnFieldCount = 9
lnRow = 2
DIMENSION laData[21]

DO WHILE !ISNULL(oSheet.Cells(lnRow, 2).Value)
	WAIT WINDOW TRANSFORM(RECNO(), "999,999") NOWAIT 
	FOR i = 1 TO lnFieldCount		
		laData[i] = oSheet.Cells(lnRow,i).Value
		DO CASE 
		CASE i = 2
			laData[i] = UPPER(laData[i])
			IF AT(".", laData[i]) = 0
				laData[11] = ALLTRIM(UPPER(LEFT(laData[i], AT(" ", laData[i]))))
				laData[12] = ALLTRIM(UPPER(SUBSTR(laData[i], AT(" ", laData[i]))))
			ELSE 
				lcName = ALLTRIM(SUBSTR(laData[i], AT(".", laData[i])+1))
				laData[11] = ALLTRIM(UPPER(LEFT(lcName, AT(" ", lcName))))
				laData[12] = ALLTRIM(UPPER(SUBSTR(lcName, AT(" ", lcName))))
			ENDIF 	
		CASE INLIST(i, 4, 5)
			IF TYPE("laData[i]") = "C"
				IF LEN(laData[i]) = 10
					laData[i] =  CTOD(LEFT(laData[i],2)+"/"+chgMonth(SUBSTR(laData[i],3,3))+"/"+RIGHT(laData[i],4))
				ELSE 
					laData[i] =  CTOD(LEFT(laData[i],2)+"/"+chgMonth(SUBSTR(laData[i],4,3))+"/"+RIGHT(laData[i],4))			
				ENDIF 	
			ENDIF 	
			*laData[8] = DATETIME(YEAR(laData[6]),MONTH(laData[6]),DAY(laData[6]))
		OTHERWISE 		
			laData[i] = IIF(ISNULL(laData[i]), "", laData[i])
		ENDCASE 
	ENDFOR 
	laData[10] = date()
	laData[13] = LEFT(laData[1],9)

	loGrp = getInterPolicyGroup("AXA",laData[13])
	laData[14] = loGrp.planid
	laData[15] = loGrp.product
	laData[16] = loGrp.policydate
	laData[17] = loGrp.policyname
	laData[18] = "A"
	laData[19] = loGrp.overalllimit
	
	
	if empty(laData[14])
		loPlan = getPlanByTitle(laData[7])
		if !isnull(loPlan)
			laData[14] = loPlan.plan_id
			laData[15] = loPlan.description
			laData[19] = loPlan.aggregate_oon
		endif 
		laData[16] = laData[4]
		laData[17] = laData[7]
	endif		
	laData[20] = strtran(laData[1], "-","")
	laData[21] = 'Area2'
	
	IF !EMPTY(laData[1])
		INSERT INTO (lcDbf) FROM ARRAY laData
	ENDIF
	lnRow = lnRow + 1
ENDDO
BROWSE 
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
