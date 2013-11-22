goFaxServer = CreateObject("FaxComEx.FaxServer")
goFaxServer.Connect("Dragon-edc")
lnIncoming = goFaxServer.Activity.IncomingMessages
IF lnIncoming # 0
	=MESSAGEBOX("มีแฟกซ์เข้า กรุณาตรวจสอบที่ Fax console", 0, "Warning")
ENDIF 	
goFaxServer.Activity.Refresh
