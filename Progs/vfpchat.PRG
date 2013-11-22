#DEFINE dlTestMode .T.
#DEFINE dcChatPath "c:\FoxBoard\ChatProgram\"
PARAMETERS tnUserNumber as Integer
PUBLIC oForm

IF dlTestMode AND NOT FILE(dcChatPath+"UserInfo.dbf")
CREATE TABLE UserInfo (nUserID i, cUserName c(15), cIP c(15), nPort i, lActive l)
INSERT INTO UserInfo VALUES (1,"User 1","127.0.0.1",1234,.F.)
INSERT INTO UserInfo VALUES (2,"User 2","127.0.0.1",1235,.F.)
INSERT INTO UserInfo VALUES (3,"User 3","127.0.0.1",1236,.F.)
INSERT INTO UserInfo VALUES (4,"User 4","127.0.0.1",1237,.F.)
ENDIF

IF EMPTY(tnUserNumber)
tnUserNumber = 0
ENDIF
oForm = CREATEOBJECT("clsChat",tnUserNumber)
oForm.visible = .t.

READ EVENTS

Store Null to oForm, oForm2
Release oForm, oForm2
* UserInfo (nUserID i, cUserName c(15), cIP c(15), nPort i, lActive l)

DEFINE CLASS clschat AS form
Top = 0
Left = 0
Height = 268
Width = 376
DoCreate = .T.
Caption = "VFP CHAT"
Name = "clschat"
oUserInfo = ''

ADD OBJECT txtchatname AS textbox WITH ;
Height = 23, ;
Left = 216, ;
Top = 12, ;
Width = 132, ;
Name = "txtChatname"

ADD OBJECT edtchat AS editbox WITH ;
Height = 134, ;
Left = 24, ;
ReadOnly = .T., ;
Top = 48, ;
Width = 324, ;
DisabledBackColor = RGB(255,255,255), ;
DisabledForeColor = RGB(0,0,0), ;
Name = "edtChat"

ADD OBJECT txtmessage AS textbox WITH ;
Height = 23, ;
Left = 84, ;
Top = 194, ;
Width = 264, ;
Name = "txtMessage"

ADD OBJECT command1 AS commandbutton WITH ;
Top = 221, ;
Left = 298, ;
Height = 25, ;
Width = 50, ;
Caption = "Send", ;
Name = "Command1"

ADD OBJECT winsock1 AS WSControl 

ADD OBJECT label2 AS label WITH ;
AutoSize = .T., ;
BackStyle = 0, ;
Caption = "MESSAGE", ;
Height = 17, ;
Left = 24, ;
Top = 197, ;
Width = 59, ;
Name = "Label2"

ADD OBJECT label1 AS label WITH ;
AutoSize = .T., ;
BackStyle = 0, ;
Caption = "CHAT NAME", ;
Height = 17, ;
Left = 144, ;
Top = 15, ;
Width = 70, ;
Name = "Label1"

PROCEDURE Init
LPARAMETERS tnUserID as Integer
SELECT nUserID, cUserName, cIP, nPort, lActive ;
FROM (dcChatPath+"UserInfo") ;
WHERE nUserID = tnUserID ;
AND NOT lActive ;
INTO CURSOR tcUserInfo
IF _TALLY # 1 && Error
***Your Message Here to User
USE IN SELECT('UserInfo')
USE IN SELECT('tcUserInfo')
CANCEL
ELSE
SCATTER NAME thisform.oUserInfo
USE IN SELECT('tcUserInfo')
UPDATE (dcChatPath+"UserInfo") ;
SET lActive = .T. ;
WHERE nUserID = thisform.oUserInfo.nUserID
WITH thisform
.winsock1.object.bind(.oUserInfo.nPort)
.txtChatname.value = ALLTRIM(.oUserInfo.cUserName)
.txtMessage.setfocus() 
ENDWITH
ENDIF
ENDPROC

PROCEDURE Destroy
UPDATE (dcChatPath+"UserInfo") ;
SET lActive = .F. ;
WHERE nUserID = thisform.oUserInfo.nUserID
ThisForm.RemoveObject('WinSock1')
ENDPROC

PROCEDURE Unload
CLEAR events
ENDPROC

PROCEDURE txtmessage.KeyPress
LPARAMETERS nKeyCode, nShiftAltCtrl
IF nKeycode = 13 AND nShiftAltCtrl = 0 AND !EMPTY(thisform.txtMessage.value)
thisform.command1.Click()
ENDIF
ENDPROC

PROCEDURE txtChatname.lostfocus
LOCAL lcUserName as String
lcUserName = ALLTRIM(thisform.txtChatname.value)
UPDATE (dcChatPath+"UserInfo") ;
SET cUserName = lcUserName ;
WHERE nUserID = thisform.oUserInfo.nUserID
thisform.txtmessage.setfocus()
ENDPROC

PROCEDURE command1.Click
LOCAL sChatName, sMessageSent
WITH thisform
sChatName = ALLTRIM(thisform.txtChatname.value)
sMessageSent = sChatName +" says: " + ALLTRIM(thisform.txtMessage.value)
WITH .winsock1.object
IF NOT USED("UserInfo")
USE (dcChatPath+"UserInfo") IN 0 SHARED
ENDIF
SELECT ('UserInfo')
SCAN FOR lActive
.RemotePort = nPort
.RemoteHost = ALLTRIM(cIP)
.SendData(sMessageSent)
ENDSCAN
ENDWITH
.txtMessage.value = ""
endwith
ENDPROC

ENDDEFINE

DEFINE CLASS WSControl AS OleControl
OleClass='MSWinsock.Winsock.1'
Top = 228
Left = 24
Height = 100
Width = 100
Name = "winsock1"

PROCEDURE Init
this.object.Protocol = 1
ENDPROC

PROCEDURE DataArrival
LPARAMETERS bytestotal
sMessage = SPACE(bytestotal)
WITH thisform
.winsock1.object.GetData(@sMessage)
.edtChat.Value = thisform.edtChat.Value + sMessage + CHR(13)
ENDWITH
ENDPROC

ENDDEFINE
