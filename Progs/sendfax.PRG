SET OLEOBJECT ON
lcServerName = "Dragon1"
lcFaxName = "Fax"
lsDocName = "doc.txt"
oFaxS = CREATEOBJECT('FaxComEx.FaxServer')
oFaxD = CREATEOBJECT("FaxComEx.FaxDocument")

oFaxS.connect(lcServername)
oFaxD.body = lcFaxName

*-- values 0-low;1-normal;2-high
*-- setting to high priority give access denied error??
oFaxD.Priority = 1			

oFaxD.Recipients.Add(lcFaxNo,lcFaxTo)
oFaxD.AttachFaxToReceipt = .T.
oFaxD.DocumentName 	= lsDocName		

*-- Sender Defaults
WITH oFaxD.sender
	.name 			= "YOURNAME"
	.company		= "YOURCOMPANYNAME"
	.officephone		= "888-8888"	
	.faxnumber 		= "503"
ENDWITH 

jobid = oFaxD.ConnectedSubmit(oFaxS)
*....do the rest

