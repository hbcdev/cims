PARAMETERS tcXlsFile
IF EMPTY(tcXlsFile)
	tcXlsFile = GETFILE("XLS", "Select Excel file to import","Select")
ENDIF 
******************************
IF EMPTY(tcXlsFile)
	RETURN 
ENDIF 
IF !FILE(tcXlsFile)
	RETURN 
ENDIF 
SET NULL ON 
SET NULLDISPLAY TO " "
**********************************************
CREATE TABLE KtaMember FREE ;
	(hcusid C(15), hplan C(20), hpno C(30), htitle C(20), hname c(50), hmname c(50), hsname c(50), ;
	haddr1 C(50), haddr2 C(50), haddr3 C(50), haddr4 C(50), hpost C(5), htel C(30), hsex C(1), hoccls C(20), ;
	hdob D, hage N(3), heffdte D, hexpdte D, hperm Y, hexclu C(50), hagent1 C(30), hagenc1 C(30), hpnosts C(200), ;
	hrenew N(3), holdpln C(30), hhblmt Y, hpnodte D, hpayer C(80), hbagunn C(50), hbagnamf C(80), hbadd1 C(80), ;
	hbadd2 C(80), hbadd3 C(80), hbadd4 C(80), hbadd5 C(80), hbadd6 C(80), hbtel1 C(50), hbpost C(5), hagflag1 C(10), hpmod C(1))
**********************************************
SELECT ktamember
SCATTER MEMVAR BLANK 

i = 1
e = 0
o = CREATEOBJECT("Excel.Application")
oWorkBook = o.Application.workBooks.Open(tcXlsFile)
oSheet = oWorkBook.ActiveSheet
DO WHILE .T.
	WAIT WINDOW TRANSFORM(i, "@Z 999,999") NOWAIT 
	i = i + 1
	m.hpno = oSheet.Cells(i,2).Value
	m.hplan = oSheet.Cells(i,3).Value
	m.hhblmt = oSheet.Cells(i,4).Value
	m.hcusid = oSheet.Cells(i,5).Value
	m.htitle = oSheet.Cells(i,6).Value
	m.hname = oSheet.Cells(i,7).Value
	m.hmname = oSheet.Cells(i,8).Value
	m.hsname = oSheet.Cells(i,9).Value
	m.hsex  = oSheet.Cells(i,10).Value
	m.hdob = oSheet.Cells(i,11).Value	
	m.hage  = oSheet.Cells(i,12).Value
	m.haddr1 =  oSheet.Cells(i,13).Value
	m.haddr2 =  oSheet.Cells(i,14).Value
	m.haddr3 =  oSheet.Cells(i,15).Value	
	m.haddr4 =  oSheet.Cells(i,16).Value	
	m.hpost =  ALLTRIM(STR(oSheet.Cells(i,18).Value,5))
	m.htel =  oSheet.Cells(i,19).Value
	m.hpnodte =  oSheet.Cells(i,22).Value
	m.heffdte =  oSheet.Cells(i,23).Value
	m.hexpdte =  oSheet.Cells(i,24).Value
	m.hprem =  oSheet.Cells(i,25).Value
	m.hexclu =  oSheet.Cells(i,26).Value
	m.hagent1 =  ALLTRIM(STR(oSheet.Cells(i,27).Value))
	m.hagenc1 =  oSheet.Cells(i,28).Value
	m.hbagnamf =  ALLTRIM(oSheet.Cells(i,31).Value)+" "+ALLTRIM(oSheet.Cells(i,32).Value)
	m.hbadd1 = oSheet.Cells(i,33).Value
	m.hbadd2 = oSheet.Cells(i,34).Value
	m.hbadd3 = oSheet.Cells(i,35).Value
	m.hbadd4 = oSheet.Cells(i,36).Value
	m.hbadd5 = oSheet.Cells(i,37).Value
	m.hbadd6 = oSheet.Cells(i,38).Value
	m.hbpost = 	ALLTRIM(STR(oSheet.Cells(i,39).Value,5))
	m.hbtel1 = 	oSheet.Cells(i,40).Value
	m.hpaymod = oSheet.Cells(i,62).Value
	m.holdpln = ALLTRIM(STR(oSheet.Cells(i,64).Value))	
	m.hoccls = ALLTRIM(STR(oSheet.Cells(i,67).Value))
	m.hrenew = oSheet.Cells(i,69).Value	
	m.hpnosts = oSheet.Cells(i,71).Value		
	m.hpayer = oSheet.Cells(i,73).Value
	***********************************
	IF ISNULL(m.hcusid)
		m.hcusid = ""
	ELSE 
		IF TYPE("m.hcusid") = "N"	
			m.hcusid = ALLTRIM(STR(m.hcusid))
		ENDIF 
	ENDIF 		
	************************************
	IF EMPTY(m.hpno)
		e = e + 1
	ELSE 
		INSERT INTO ktaMember FROM MEMVAR 
	ENDIF 	
	IF e = 3
		EXIT 
	ENDIF 	
ENDDO 
o.quit
