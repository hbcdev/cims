goFaxServer = CreateObject("FaxComEx.FaxServer")
goFaxServer.Connect("Dragon-edc")
lnIncoming = goFaxServer.Activity.IncomingMessages
IF lnIncoming # 0
	=MESSAGEBOX("��ῡ����� ��سҵ�Ǩ�ͺ��� Fax console", 0, "Warning")
ENDIF 	
goFaxServer.Activity.Refresh
