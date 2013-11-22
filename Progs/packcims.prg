#INCLUDE "include\cims.h"
IF MESSAGEBOX("การปรับปรุงข้อมูล ต้องให้ทุกเครื่อง หยุดใช้งาน และออกจากระบบก่อน"+CHR(13)+"ต้องการให้ทำงานต่อหรือไม่ ", MB_YESNO, "คำเตือน") = IDNO
	RETURN
ENDIF
LOCAL lnTotalTable,;
	lcTable

IF DBUSED("cims")
	SET DATABASE TO cims
ENDIF 
OPEN DATABASE cims EXCLUSIVE 
VALIDATE DATABASE RECOVER 
*
SET TALK ON
SELECT 0
lnSelect = SELECT()
************************
lnTotalTable = ADBOBJECT(aCims, "TABLE")
IF lnTotalTable > 0
	FOR i = 1 TO lnTotalTable
		lcTable = aCims[i]
		WAIT WINDOW lcTable NOWAIT
		IF USED(lcTable)
			SELECT (lcTable)
		ELSE
			SELECT (lnSelect)
		ENDIF
		USE (lcTable) EXCL
		IF ISEXCLUSIVE(lcTable)
			PACK
		ENDIF 	
	ENDFOR
ENDIF	
SET TALK OFF
SET EXCL OFF
	
