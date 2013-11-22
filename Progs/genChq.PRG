IF !USED("kta_pv")
	USE g:\report\kta_pv
ENDIF 
*
CREATE DBF g:\report\chqlist (chqno C(10), chqdate C(30), paidto c(50), amount Y, paidtype I, pvno C(200))
*
SELECT chqlist
SCATTER MEMVAR BLANK 
SELECT kta_pv
GO TOP 
DO WHILE !EOF()
	m.pvno = ""
	m.amount = 0
	m.chqno = chqno
	m.chqdate = SUBSTR(chqdate,8)
	m.paidto = paid_to
	DO WHILE chqno = m.chqno AND !EOF()
		m.paidtype = paidtype
		m.amount = m.amount+total
		m.pvno = ALLTRIM(m.pvno)+IIF(EMPTY(ALLTRIM(m.pvno)), "", ", ")+pv_no+"="+TRANSFORM(total, "@Z 999,999.99")
		SKIP 
	ENDDO 
	INSERT INTO chqlist FROM MEMVAR 
ENDDO 		
	
	