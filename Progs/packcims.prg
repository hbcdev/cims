#INCLUDE "include\cims.h"
IF MESSAGEBOX("��û�Ѻ��ا������ ��ͧ���ء����ͧ ��ش��ҹ ����͡�ҡ�к���͹"+CHR(13)+"��ͧ������ӧҹ���������� ", MB_YESNO, "����͹") = IDNO
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
	
