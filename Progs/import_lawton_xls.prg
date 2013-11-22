CLEAR 
SET PROCEDURE TO progs\utility
lcDataFile = GETFILE("XLS;XLSX", "Lawton data", "Select")
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
CREATE DBF (lcDbf) FREE (cardno C(25), Policy_no C(30), fullname C(80), dob D, Effdate T, Expdate T, deduc Y, scheme C(30), ;
	programe V(100), remark V(200), area C(10), adddate D, firstname C(40), surname C(40), groupno C(30), plan_id C(10), plan C(20), ;
	poldate T,groupname V(100), polstatus C(1), overall Y)
***************************************************
lnFieldCount = 11
lnRow = 2
DIMENSION laData[21]

llNoAVI = checkInterFund(left(oSheet.Cells(lnRow,1).Value,3))
DO WHILE !ISNULL(oSheet.Cells(lnRow, 2).Value)
	WAIT WINDOW TRANSFORM(RECNO(), "999,999") NOWAIT 
	if llNoAVI
		laData[1] = null	
		FOR i = 2 TO lnFieldCount-1		
			laData[i] = oSheet.Cells(lnRow,i-1).Value
			DO CASE 
			CASE i = 1
				IF TYPE("laData[1]") = "N"
					laData[1] = STRTRAN(STR(laData[1]), " ", "")
				ELSE 
					laData[1] = STRTRAN(laData[1], " ", "")
				ENDIF 	
			CASE i = 3	
				laData[i] = UPPER(laData[i])
				IF AT(".", laData[i]) = 0
					laData[13] = ALLTRIM(UPPER(LEFT(laData[3], AT(" ", laData[3]))))
					laData[14] = ALLTRIM(UPPER(SUBSTR(laData[3], AT(" ", laData[3]))))
				ELSE 
					lcName = ALLTRIM(SUBSTR(laData[3], AT(".", laData[3])+1))
					laData[13] = ALLTRIM(UPPER(LEFT(lcName, AT(" ", lcName))))
					laData[14] = ALLTRIM(UPPER(SUBSTR(lcName, AT(" ", lcName))))
				ENDIF 	
			CASE INLIST(i, 5, 6)
				IF TYPE("laData[i]") = "C"
					IF LEN(laData[i]) = 10
						laData[i] =  CTOD(LEFT(laData[i],2)+"/"+chgMonth(SUBSTR(laData[i],3,3))+"/"+RIGHT(laData[i],4))
					ELSE 
						laData[i] =  CTOD(LEFT(laData[i],2)+"/"+chgMonth(SUBSTR(laData[i],4,3))+"/"+RIGHT(laData[i],4))			
					ENDIF 	
				ENDIF 	
				if i = 6
					laData[6] = DATETIME(YEAR(laData[6]),MONTH(laData[6]),DAY(laData[6]),23,59)
				endif	
			CASE i = 9
				laData[11] = ALLTRIM(UPPER(SUBSTR(laData[9], AT("AREA", laData[9]))))			
				laData[9] = UPPER(laData[9])
				laData[16] = ""
			OTHERWISE 		
				laData[i] = IIF(ISNULL(laData[i]), "", laData[i])
			ENDCASE 
		ENDFOR 	
		
		loMember = getInterPolicyGroup(left(laData[2],3), laData[15])
		if isnull(loMember)
			loPlan = getInterPlanId(left(laData[2],3),laData[8]) 
			if isnull(loPlan)
				STORE "" TO laData[16], laData[17], laData[19]
				STORE {} TO laData[18]
			else
				laData[16] = laPlan[1]
				laData[17] = laPlan[2]
				laData[21] = laPlan[3]
			endif	
		else  
			laData[16] = laMember[1]		
			laData[17] = laMember[2]
			laData[18] = laMember[3]
			laData[19] = laMember[4]
			laData[21] = laMember[5]				
		endif  		
	else
		FOR i = 1 TO lnFieldCount		
			laData[i] = oSheet.Cells(lnRow,i).Value
			DO CASE 
			CASE i = 1
				IF TYPE("laData[1]") = "N"
					laData[1] = STRTRAN(STR(laData[1]), " ", "")
				ELSE 
					laData[1] = STRTRAN(laData[1], " ", "")
				ENDIF 	
			CASE i = 3	
				laData[i] = UPPER(laData[i])
				IF AT(".", laData[3]) = 0
					laData[13] = ALLTRIM(UPPER(LEFT(laData[3], AT(" ", laData[3]))))
					laData[14] = ALLTRIM(UPPER(SUBSTR(laData[3], AT(" ", laData[3]))))
				ELSE 
					lcName = ALLTRIM(SUBSTR(laData[3], AT(".", laData[3])+1))
					laData[13] = ALLTRIM(UPPER(LEFT(lcName, AT(" ", lcName))))
					laData[14] = ALLTRIM(UPPER(SUBSTR(lcName, AT(" ", lcName))))
				ENDIF 	
			CASE INLIST(i, 5, 6)
				IF TYPE("laData[i]") = "C"
					IF LEN(laData[i]) = 10
						laData[i] =  CTOD(LEFT(laData[i],2)+"/"+chgMonth(SUBSTR(laData[i],3,3))+"/"+RIGHT(laData[i],4))
					ELSE 
						laData[i] =  CTOD(LEFT(laData[i],2)+"/"+chgMonth(SUBSTR(laData[i],4,3))+"/"+RIGHT(laData[i],4))			
					ENDIF 	
				ENDIF 	
				laData[6] = DATETIME(YEAR(laData[6]),MONTH(laData[6]),DAY(laData[6]),23,59)
			CASE i = 9
				laData[11] = ALLTRIM(UPPER(SUBSTR(laData[9], AT("AREA", laData[9]))))			
				laData[9] = UPPER(laData[9])
				laData[16] = ""
			OTHERWISE 		
				laData[i] = IIF(ISNULL(laData[i]), "", laData[i])
			ENDCASE 
		ENDFOR 
		
		laData[15] = LEFT(laData[1],10)	
		SELECT plan_id, product, policy_date, policy_name, overall_limit ;
		FROM cims!member ;
		WHERE tpacode = "AVI" ;
			AND policy_group = laData[15] ;
		INTO ARRAY laMember
		IF _TALLY = 0
			STORE "" TO laData[16], laData[17], laData[19]
			STORE {} TO laData[18]
		ELSE 
			IF laData[15] = "2044331005"
				laData[18] = laData[5]
				laData[19] = laMember[4]
			ELSE 
				laData[16] = laMember[1]		
				laData[17] = laMember[2]
				laData[18] = laMember[3]
				laData[19] = laMember[4]
				laData[21] = iif(laData[15] = '2044343001', 2133333, laMember[5])
			ENDIF 	
		ENDIF 		
		*
		IF EMPTY(laData[16])
			DO CASE 
			CASE UPPER(laData[9]) = "INPATIENT ONLY AREA 2"
				laData[16] = "AVI1577"
				laData[17] = "INPATIENT ONLY"
				laData[21] = 83000000
			CASE UPPER(laData[9]) = "PROGRAM 2 AREA 2"
				DO CASE 
				CASE UPPER(laData[8]) = "BCIS"
					laData[16] = "AVI1580"
					laData[17] = "PROGRAMME A"
				CASE UPPER(laData[8]) = "BPS"
					laData[16] = "AVI1581"
					laData[17] = "PROGRAMME B"
					laData[21] = 80000000							
				CASE UPPER(laData[8]) = "ST.JOHN"
					laData[16] = "AVI1582"
					laData[17] = "PROGRAMME C"
				CASE UPPER(laData[8]) = "NIST"
					laData[16] = "AVI1583"
					laData[17] = "PROGRAMME D"
				OTHERWISE 	
					laData[16] = "AVI1578"
					laData[17] = "PROGRAMME 2"			
				ENDCASE 					
				IF EMPTY(laData[21])
					laData[21] = 83000000			
				ENDIF 	
			CASE UPPER(laData[9]) = "PROGRAM 3 AREA 2"
				laData[16] = "AVI1578"
				laData[17] = "PROGRAMME 3"		
				laData[21] = 83000000
			CASE UPPER(laData[9]) = "PREMIER ELITE"
				laData[16] = "AVI1692"
				laData[17] = "PREMIER - ELITE"
				laData[21] = 48000000				
			CASE UPPER(laData[9]) = "PREMIER SUPREME EXPAT"
				laData[16] = "AVI1795"
				laData[17] = "PREMIER - SUPREME E"
				laData[21] = 100000
			CASE UPPER(laData[9]) = "PREMIER SUPREME PARTNER"
				laData[16] = "AVI1793"
				laData[17] = "PREMIER - SUPREME P"
				laData[21] = 500000						
			CASE UPPER(laData[9]) = "PREMIER SUPREME MANAGER"
				laData[16] = "AVI1794"
				laData[17] = "PREMIER - SUPREME M"
				laData[21] = 100000						
			CASE UPPER(laData[9]) = "PREMIER SUPREME"
				laData[16] = "AVI1584"
				laData[17] = "PREMIER-SUPREME"
				laData[21] = 100000
			ENDCASE 
		ENDIF 					
	endif	
	*
*!*			IF LEN(ALLTRIM(laData[1])) = 10
*!*				SELECT IIF(EMPTY(same_as), plan_id, same_as) AS plan_id, description FROM cims!plan WHERE title = laData[9] INTO ARRAY laPlan
*!*				IF _TALLY <> 0
*!*					laData[16] = laPlan[1]
*!*					laData[17] = laPlan[2]				
*!*				ENDIF 		
*!*			ENDIF 
*!*	ENDIF 		
	laData[1] = IIF(ISNULL(laData[1]), strtran(laData[2],"-",""), laData[1])
	laData[6] = IIF(ISNULL(laData[6]), GOMONTH(laData[5],12)-1, laData[6])
	laData[12] = DATE()	
	laData[20] = IIF(EMPTY(laData[20]) OR laData[20] = "F", "", laData[20])	
	IF !EMPTY(laData[2])
		INSERT INTO (lcDbf) FROM ARRAY laData
	ENDIF
	lnRow = lnRow + 1
ENDDO
BROWSE 
=MESSAGEBOX("Finished.....")
USE 
oExcel.quit

************************************
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