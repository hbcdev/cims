IF !USED("faxinout")
	USE f:\hips\data\faxinout 
ENDIF 
SELECT faxinout
	

fax = CREATEOBJECT("FAXCOMEX.FAXSERVER")
fax.Connect("dragon1")
faxinarc = fax.Folders.IncomingArchive.GetMessages()
faxinarc.MoveFirst

DO WHILE !faxinarc.AtEOF
	m.type = "I"
	m.id = faxinarc.Message.Id
	m.callerid = faxinarc.Message.CallerId
	m.pages = faxinarc.Message.Pages
	m.datestart = faxinarc.Message.TransmissionStart
	m.dateend = faxinarc.Message.TransmissionEnd
	m.csid = faxinarc.Message.CSID
	m.tsid = faxinarc.Message.TSID
	m.deviceName = faxinarc.Message.DeviceName
	*?faxinarc.Message.RoutingInformation
	*********************************
 	IF !SEEK(LEFT(m.id,30), "faxinout", "id")
 		lcTiff = "F:\Fax\"+ALLTRIM(m.id)+".tiff"
		faxinarc.Message.CopyTiff(lcTiff)		 	
		?m.id
		APPEND BLANK 
		GATHER MEMVAR 
		APPEND GENERAL tifffile FROM (lcTiff)
	ENDIF 	 
	 *********************************
	faxinarc.MoveNext
ENDDO 	
