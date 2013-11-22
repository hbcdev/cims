SET TALK OFF
SET EXCL OFF
SET MULTILOCK ON
SET SAFE OFF
SET DELE ON
***********
PUBLIC DataPath
DataPath = "C:\HIPS\"
SET DEFA TO (datapath)
IF !FILE(DataPath+"class.dbf")
	CREATE TABLE (DATAPATH+"class") (;
		fundcode C(3),;
		policy_no C(30),;
		class C(120),;
		page C(60))
ENDIF
DO FORM form\addpage
READ EVENT