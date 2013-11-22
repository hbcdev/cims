IF !USED("kta_pv")
	RETURN 
ENDIF 
*
CREATE CURSOR curChq	 (chqno C(10), chqdate C(20), paid_to C(50), pvno C(50), amount Y)
IF !USED("curChq")
	RETURN 
ENDIF 
*
SELECT chqno, chqdate, paid_to, pv_no, total ;
FROM (gcPvTable) ;
ORDER BY chqno, pv_no ;
WHERE INLIST(paidtype, 1, 2, 5, 6) ;
INTO CURSOR curPvOut
*
SELECT curPvout
DO WHILE !EOF()
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 99,999") NOWAIT 
	SCATTER MEMVAR 
	m.pvno = ""
	m.amount = 0
	DO WHILE chqno = m.chqno AND !EOF()
		m.pvno = m.pvno+IIF(EMPTY(m.pvno), "", ", ")+pv_no
		m.amount = m.amount + total
		SKIP 
	ENDDO 
	INSERT INTO curChq FROM MEMVAR 
ENDDO
USE IN curPvout 
SELECT curChq 		