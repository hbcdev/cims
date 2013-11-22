PARAMETERS tcText
	
IF EMPTY(tcText)
	RETURN 
ENDIF 
*	
lnSelect = SELECT()
IF !USED("title")
	USE cims!title IN 0 
ENDIF 
**
lcTitle = ""
lnLen = 0
SELECT title 
GO TOP 
DO WHILE EMPTY(lcTitle) AND !EOF()
	lcText = LEFT(tcText,LEN(ALLTRIM(title.short_title)))
	IF ALLTRIM(title.short_title) = lcText
		lcTitle = ALLTRIM(title.short_title)
		lnLen = LEN(lcTitle)
		lcName = ALLTRIM(SUBSTR(tcText, lnLen+1))
	ENDIF 
	SKIP 	
ENDDO 	
RETURN lcName
USE IN title
SELECT (lnSelect)