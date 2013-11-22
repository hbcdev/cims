DEFINE CLASS excelclass AS Custom
	PROCEDURE OpenXls 
		LOCAL oExcel 
		oExcel = CREATEOBJECT("Excel.Application")
		RETURN oExcel
	ENDPROC 
	
	PROCEDURE SaveXls
	ENDPROC 
ENDDEFINE  

