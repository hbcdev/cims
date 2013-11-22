fax = CREATEOBJECT("FAXCOMEX.FAXSERVER")
fax.Connect("dragon1")
faxinarc = fax.Folders.IncomingArchive.GetMessages()
faxinarc.MoveFirst

DO WHILE !faxinarc.AtEOF
	?faxinarc.Message.Id
	?faxinarc.Message.CallerId
	?faxinarc.Message.Pages
	?faxinarc.Message.TransmissionStart
	?faxinarc.Message.TransmissionEnd
	?faxinarc.Message.CSID
	?faxinarc.Message.TSID
	?faxinarc.Message.CallerId
	?faxinarc.Message.Retries
	?faxinarc.Message.DeviceName
	?faxinarc.Message.RoutingInformation
	?faxinarc.Message.CopyTiff("f:\fax.tiff")
	faxinarc.MoveNext
ENDDO 	
