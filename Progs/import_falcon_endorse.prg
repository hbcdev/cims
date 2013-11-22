lcDataFile = GETFILE("XLS", "Falcon Endorse File", "Select")
IF EMPTY(lcDataFile) AND !USED("eff") AND !USED("exp")
	RETURN 
ENDIF 
********************
llError = .F.
lcDbf = STRTRAN(lcDataFile, ".XLS", ".DBF")
lcErrorFile = STRTRAN(lcDataFile, ".XLS", ".TXT")
oExcel = CREATEOBJECT("Excel.Application")
oWorkBook = oExcel.workbooks.open(lcDataFile)

oexcel.ActiveWindow.Activate
oexcel.ActiveWindow.FreezePanes = .F.
*
oSheet = oWorkBook.worksheets(1)
CREATE DBF (lcDbf) FREE (Policy_no V(30), sequence I, Plan V(20), Cust_id V(20), Title V(20), Name V(40), MidName V(40), Surname V(40), ;
	Sex C(1), Dob D, Age I, Address1 V(40), Address2 V(40), Address3 V(40), Address4 V(40), Country V(40), Postcode C(5), Telephone V(30), ContactPer C(40), ContactTel C(30), ;
	Pol_date T, Eff_date T, Exp_date T, Premium Y, Exclusion C(100), Agent C(20), Agency C(20), Pay_mode C(1), OccuCode C(20), OccuClass C(10), AdjDate D, Renew I, PolStatus C(1), ;
	Employee C(1), Payer C(40), HB_Limit Y, Medical Y, pol_group C(20), pol_name C(60), adddate D, cardno C(20))
	
?DBF()
lcDate = RIGHT(JUSTFNAME(DBF()),12)
ldDate = CTOD(LEFT(lcDate, 2)+"/"+SUBSTR(lcDate,3,2)+"/"+SUBSTR(lcDate, 5, 4))
***************************************************
lnFieldCount = 37
lnRow = 2
DIMENSION laData[41]
DO WHILE !ISNULL(oSheet.Cells(lnRow, 6).Value)
	WAIT WINDOW TRANSFORM(RECNO(), "999,999") NOWAIT 
	FOR i = 1 TO lnFieldCount
		laData[i] = oSheet.Cells(lnRow,i).Value
		DO CASE 
		CASE i = 3
			laData[i] = UPPER(laData[i])
		CASE i = 4
			laData[i] = IIF(ISNULL(laData[i]), "", laData[i])				
			laData[i] = STRTRAN(IIF(AT(",", laData[i]) = 0, laData[i], LEFT(laData[i], AT(",", laData[i])-1)), "-", "")					
		CASE INLIST(i, 11, 24, 32, 36, 37)
			laData[i] = IIF(ISNULL(laData[i]), 0, laData[i])		
		CASE INLIST(i, 10, 21, 22, 23, 31, 39)
			laData[i] = IIF(ISNULL(laData[i]), {}, laData[i])
			IF EMPTY(laData[i])
				laData[i] = {}
			ENDIF 	
			IF TYPE("laData[i]") = "C"
				laData[i] = CTOD(laData[i])
			ENDIF 	
			
			IF INLIST(i, 21, 22, 23)
				IF EMPTY(laData[i])
					laData[i] = {}
				ELSE 	
					laData[i] = DATETIME(YEAR(laData[i]), MONTH(laData[i]), DAY(laData[i]), 12, 00)
				ENDIF 	
				IF i = 23
					laData[i] = GOMONTH(laData[22], 2)
					laData[i] = DATETIME(YEAR(laData[i]), MONTH(laData[i]), DAY(laData[i]), 12, 00)					
				ENDIF 				
			ENDIF 	
		OTHERWISE 		
			laData[i] = IIF(ISNULL(laData[i]), "", laData[i])
			IF TYPE("laData[i]") = "N"
				laData[i] = LTRIM(STR(laData[i]))
			ENDIF 	
		ENDCASE 
	ENDFOR
	laData[38] = laData[1]
	laData[39] = ALLTRIM(laData[6])+" "+ALLTRIM(laData[8])	
	laData[40] = ldDate
	laData[41] = STRTRAN(laData[1], "-", "")
	IF !EMPTY(laData[6])
	
		INSERT INTO (lcDbf) FROM ARRAY laData
	ENDIF
	lnRow = lnRow + 1
ENDDO
BROWSE 
oExcel.quit 
*
if not "ENDORSE" $ upper(lcDataFile)
	USE 
	=MESSAGEBOX("Finished.....")
	return
endif 
*
if messagebox("ต้องกาตอัพเทดข้อมูลไป เข้าระบบ หรือไม่",4+32+256,"Update Falcon Member Endorse") = 6
	go top
	scan 
		wait window transform(recno(),"@Z 999,999") nowait 
		scatter memvar
		if empty(m.policy_no) and empty(m.cust_id) and empty(m.name) and empty(m.surname)
			lcError = alltrim(m.policy_no)+" "+alltrim(name)+" "+alltrim(surname)+" "+alltrim(m.plan)+" "+"Column Blank"
			=StoreErrorFile(lcError,lcErrorFile)
		ELSE
			lnUpdate = updateEndorse('FAL',m.policy_no, m.plan, m.name, m.surname, m.cust_id, m.sex, m.dob, m.age, m.address1, m.address2,;
				m.address3, m.address4, m.country, m.postcode, m.telephone, m.title)
			if lnUpdate <= 0
				lcError = alltrim(m.policy_no)+" "+alltrim(name)+" "+alltrim(surname)+" "+alltrim(m.plan)+" "+"Not Found"			
				=StoreErrorFile(lcError,lcErrorFile)
			endif
			
			*Update to SQL
			lcSQL = "{call sp_UpdateEndorse('FAL',?m.policy_no,?m.plan, ?m.name,?m.surname,?m.cust_id, ?m.sex, ?m.dob, ?m.age,;
				?m.address1, ?m.address2, ?m.address3, ?m.address4, ?m.country, ?m.postcode, ?m.telephone, ?m.title)}"
			lnSuscess = sqlexec(gnConn,lcSql)
			IF lnSuscess < 0
				=aerror(aSqlError)
				=saveError(aSqlError[2])
			ENDIF 	
		endif	
	endscan		
endif	

if llError
	modify file (lcErrorFile) noedit
endif 	
************************************
function StoreErrorFile(tcError,tcFile)
 =strtofile(tcError, tcFile,1)
