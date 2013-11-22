LPARAMETER ldInput1, ldInput2

	DO CASE
		CASE TYPE("ldInput1") = "L"
			ldInput1 = DATE()
		CASE TYPE("ldInput1") = "C"
			ldInput1 = CTOD(ldInput1)
		CASE TYPE("ldInput1") = "D"
	OTHERWISE
		=MESSAGEBOX("Invalid date parameter passed")
		RETURN 0
	ENDCASE
	
	DO CASE
		CASE TYPE("ldInput2") = "L"
			ldInput2 = DATE()
		CASE TYPE("ldInput2") = "C"
			ldInput2 = CTOD(ldInput2)
		CASE TYPE("ldInput1") = "D"
	OTHERWISE
		=MESSAGEBOX("Invalid date parameter passed")
		RETURN 0
	ENDCASE
	
	ldStartDate	= IIF(ldInput1  > ldInput2,ldInput2,ldInput1)
	ldEndinDate = IIF(ldInput1 => ldInput2,ldInput1,ldInput2)
	lnNumberOfDays = ldEndinDate - ldStartDate
	lnReturnDays = lnNumberOfDays
	
	FOR iDays = 1 TO lnNumberOfDays
		IF DOW(ldStartDate + iDays) < 7 AND ;
			DOW(ldStartDate + iDays) > 1
			lnReturnDays  = lnReturnDays - HolidayFilter((ldStartDate + iDays))
		ELSE
			lnReturnDays  = lnReturnDays - 1
		ENDIF
	ENDFOR
	
RETURN lnReturnDays

PROCEDURE HolidayFilter

	LPARAMETER ldDate

	lnReturnValue = 0
	lnYear = YEAR(ldDate)
	lnMont = MONTH(ldDate)
	lcMont = PADL(ALLTRIM(STR(MONTH(ldDate))),2,"0")
	lcDay  = PADL(ALLTRIM(STR(DAY(ldDate))),2,"0")
	lnSelect = SELECT()
	USE holidays SHARED IN 0
	SELECT holidays
	ldHoliday = DATE(lnYear,monthnum,daynum)

	SCAN FOR !DELETED("holidays")
		IF holidays.name = "New Year's Day" AND lnMont = 1
			IF DOW(ldHoliday) = 7
				IF holidays.name = "New Year's Day"
					ldHoliday = ldHoliday + 2
				ELSE
					ldHoliday = ldHoliday - 1
				ENDIF
			ENDIF
			IF DOW(ldHoliday) = 1
				ldHoliday = ldHoliday + 1
			ENDIF
			IF ldDate = ldHoliday
				lnReturnValue = 1
			ENDIF
		ENDIF
		IF lnMont = holidays.monthnum AND holidays.name <> "New Year's Day"
			IF holidays.dayofweek = 0
				IF DOW(ldHoliday) = 7
					ldHoliday = ldHoliday - 1
				ENDIF
				IF DOW(ldHoliday) = 1
					ldHoliday = ldHoliday + 1
				ENDIF
				IF ldDate = ldHoliday
					lnReturnValue = 1
				ENDIF
			ELSE
				IF holidays.dayoccur = 9
					DO CASE
						CASE (lcMont$"01.03.05.07.08.10.12")
							lcDateStart = ALLTRIM(STR(lnYear))+"-"+;
								PADL(ALLTRIM(STR(monthnum)),2,"0")+"-31"
						CASE (lcMont$"04.06.09.11")
							lcDateStart = ALLTRIM(STR(lnYear))+"-"+;
								PADL(ALLTRIM(STR(monthnum)),2,"0")+"-30"
					OTHERWISE
						IF MOD(lnYear,4) = 0
							lcDateStart = ALLTRIM(STR(lnYear))+"-"+;
								PADL(ALLTRIM(STR(monthnum)),2,"0")+"-29"
						ELSE
							lcDateStart = ALLTRIM(STR(lnYear))+"-"+;
								PADL(ALLTRIM(STR(monthnum)),2,"0")+"-28"
						ENDIF
					ENDCASE
					lnDaysBack = 0
					DO WHILE .T.
						ldHoliday = {^&lcDateStart} - lnDaysBack
						IF DOW(ldHoliday) = holidays.dayofweek
							EXIT
						ELSE
							lnDaysBack = lnDaysBack + 1
						ENDIF
					ENDDO
					IF ldDate = ldHoliday
						lnReturnValue = 1
					ENDIF
				ELSE
					lcDateStart = ALLTRIM(STR(lnYear))+"-"+lcMont+"-01"
					lnDayOccur = 0
					lnDaysUp = 0
					llCanExit = .F.
					DO WHILE .T.
						ldHoliday = {^&lcDateStart} + lnDaysUp
						IF DOW(ldHoliday) = holidays.dayofweek
							lnDayOccur = lnDayOccur + 1
							IF lnDayOccur = holidays.dayoccur
								llCanExit = .T.
							ENDIF
						ENDIF
						IF llCanExit
							EXIT
						ELSE
							lnDaysUp = lnDaysUp + 1
						ENDIF
					ENDDO
					IF ldDate = ldHoliday
						lnReturnValue = 1
					ENDIF
				ENDIF
			ENDIF
		ENDIF
	ENDSCAN
	USE IN holidays
	SELECT (lnSelect)
	
RETURN lnReturnValue