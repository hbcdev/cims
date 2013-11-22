LPARAMETER lcFRX, lnCopies
LOCAL lcNewExpr, lnStartCopiesLine, lcStartAtCopiesLine, lnEndCopiesLine ;
	lnLenCopiesLine, lcTop, lcBottom
#DEFINE vfCRLF CHR(13) + CHR(10)

IF !(UPPER(RIGHT(lcFRX, 4)) = ".FRX")
	lcFRX = lcFRX + ".FRX"
ENDIF
USE (lcFRX)
LOCATE FOR objType = 1 AND objCode = 53

IF EMPTY(EXPR)

        lcNewExpr = "COPIES=" + ALLT(STR(lnCopies)) + vfCRLF
ELSE

        lnStartCopiesLine = ATC("COPIES", EXPR)
        lcStartAtCopiesLine = SUBSTR(EXPR, lnStartCopiesLine)
        lnEndCopiesLine = ATC(vfCRLF, lcStartAtCopiesLine)
        lnLenCopiesLine = LEN(SUBSTR(lcStartAtCopiesLine, 1, lnEndCopiesLine))
        lcTop = SUBSTR(EXPR, 1, lnStartCopiesLine - 1)
        lcBottom = SUBSTR(EXPR, (LEN(lcTop) + lnLenCopiesLine))
        lcNewExpr  = lcTop + "COPIES=" + ALLT(STR(lnCopies)) + lcBottom

ENDIF

REPLACE EXPR WITH lcNewExpr
USE IN (lcFRX) 