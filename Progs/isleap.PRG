LPARAMETER tdFrom, tdTo
IF PARAMETER() = 0
	RETURN
ELSE
	IF PARAMETER() = 1
		tdTo = DATE()
	ENDIF
ENDIF
*******************			
lnYearFrom = YEAR(tdFrom)
lnYearTo = YEAR(tdTo)
lnTotalYear = lnYearTo - lnYearFrom
lnLeap = 0
FOR i = lnYearFrom To lnYearTo
	IF MOD(i, 4) = 0
		susp
		lnLeap = lnLeap + 1
	ENDIF	
ENDFOR
RETURN (tdFrom + (365 * lnTotalYear))+lnLeap
