#INCLUDE "include\cims.h"
IF MESSAGEBOX("��û�Ѻ�Ѫ�բ����� ��ͧ���ء����ͧ ��ش��ҹ ����͡�ҡ�к���͹", MB_YESNO, "����͹") = IDNO
	RETURN
ENDIF
LOCAL lnTotalTable,;
	lcTable
SET DATABASE TO cims
SET TALK ON
lnTotalTable = ADBOBJECT(aCims, "TABLE")
IF lnTotalTable > 0
	FOR i = 1 TO lnTotalTable
		lcTable = aCims[i]
		WAIT WINDOW lcTable NOWAIT
		IF USED(lcTable)
			SELECT (lcTable)
		ELSE
			SELECT 0
		ENDIF
		USE (lcTable) EXCL		
		REINDEX
	ENDFOR
ENDIF	
SET TALK OFF
SET EXCL OFF
	
