*-----------------| Location Section |--------------------
*) Procedure..: A simple TCP/IP server test form
*} Library....:
*} Class......:
*} Method.....:
*) Author........: Markus Voellmy
*) Company.......:
*) Description...: A server for TCP/IP. Uses Winsock OCX for communications.
*-------------------| Usage Section |---------------------
*$ Scope.........:
*$ Parameters....: tnPort - Numeric. The port number. If not supplied, 63333 is used.
*$ Usage.........: Simple run it. Parameter is optional.
*$ Example.......: DO tcpserver WITH 63333
*$ Returns.......:
*-------------------| Various Info |----------------------
*@ Precondition Invariants.....:
*@ Post-condition Invariants...:
*----------------| Maintenance Section |------------------
*? To Do............:
*= Methods Called...:
** Process..........: This test server uses the Winsock OCX for communications
*^ Change Log.......:
*--------------------------------------------------------- 
LPARAMETERS tnPort
#DEFINE EOT CHR(4) && End of Transmission sign
CLEAR
IF VARTYPE(tnPort) # "N"
  tnPort = 63333
ENDIF
oForm = CREATEOBJECT('myForm',tnPort)
READ EVENTS
RELEASE oForm
RETURN


* --- The form class
DEFINE CLASS MyForm AS FORM
  nProtocol = 0
  nPort = 0 && this should be filled with a normally unusued port
  AutoCenter = .T.
  Caption = 'TCP-Server --- Port '+ALLTRIM(STR( This.nPort) )
  nstat = 0

  PROCEDURE Load
   SYS(2333,0)
   _VFP.AutoYield = .F.
   RETURN
  ENDPROC

  PROCEDURE Unload
   _VFP.AutoYield = .T.
   RETURN
  ENDPROC

  PROCEDURE QueryUnload
   CLEAR EVENTS
   RETURN
  ENDPROC

  PROCEDURE Init
   LPARAMETERS tnPort
   This.nPort = tnPort
   This.AddObject('EditOut', 'bEditBox')
   WITH This.EditOut
    .Top = 60
    .Left = 10
    .Width = This.Width-20
    .Height = This.Height-(.Top+5)
    .ReadOnly = .T.
    .Value = ''
    .Visible = .T.
   ENDWITH
   This.AddObject('txtStat', 'TextBox')
   WITH this.txtStat
    .Top = 10
    .Left = 10
    .Width = 20
    .Readonly = .T.
    .ControlSource = "ThisForm.nStat"
    .Visible = .T.
   ENDWITH
   This.AddObject('oSock', 'frmSock' )
   This.oSock.Listen()
   This.Visible = .T.
   RETURN
  ENDPROC
ENDDEFINE

* --- WinSock ActiveX Abstract
DEFINE CLASS aWinSock AS OleControl
  OleClass = "MSWinsock.Winsock"

  PROCEDURE Init
   This.protocol = Thisform.nProtocol
   This.localport = Thisform.nPort
  ENDPROC

  PROCEDURE Error
   LPARAMETERS number, description, scode, source, helpfile, helpcontext, canceldisplay

   * It's used for error displaying purposes
   WITH ThisForm.EditOut
    .Value = .Value + CHR(13) + CHR(10)
    .Value = .Value + 'Error ' + STR(number) + " " + ;
    Description + chr(13) + chr(10)
    .Refresh()
   ENDWITH
  ENDPROC
ENDDEFINE

* --- WinSock ActiveX "the listener"
DEFINE CLASS frmSock AS aWinSock

* Because it might be, that we want to have more than one single
* connection active, we need a method to do a pseudo multi
* threading. I have "stolen" this idea from EETAServer ---
* Thx btw --- and have later on noticed that this already is
* recommended in the online help.

  PROCEDURE ConnectionRequest
   LPARAMETER tnRequestID

* This ActiveX is a performance hog, so we need to get
* rid of older connections that aren't active anymore.
* So before adding a new one we check if we can skip
* another.

  FOR EACH lControl IN ThisForm.Controls

* This DoEvent might not really be necessary, but
* it helps to get a correct state from the instance

   DOEVENTS
   IF LOWER(lControl.Class) != 'frmsock2' or ;
      ((seconds()-lControl.nCreateTime) < 5 or lControl.State = 7)
      LOOP
   ENDIF
* If we have an instance to skip we show this to the user
   WITH ThisForm.EditOut
    .Value = .Value + 'Info ' + 'Remove ' + lControl.name + chr(13) + chr(10)
    .Refresh()
   EndWith
   Thisform.RemoveObject(lControl.name )
  ENDFOR

* Now let's add another TCP server, that is able to handle
* the intended connection. The SYS(2015) function is a simple
* way to get an almost unique object name. In a serious production
* app it might be necessary to catch it's weaknesses for fast
* consequtive calls.

  ThisForm.Addobject( SYS(2015), 'frmSock2', m.tnRequestID )
* If we have an instance to add we also show this to the user
   WITH ThisForm.EditOut
    .Value = .Value + 'Info ' + 'Connection added ID ' + ;
    STR(m.tnRequestID) + chr(13) + chr(10)
    .Refresh()
   ENDWITH
   RETURN
  ENDPROC
ENDDEFINE
* --- WinSock ActiveX for multiple Connections
DEFINE CLASS frmSock2 AS aWinSock
  nCreateTime = 0 && The creation time
  cReceiveBuffer = '' && a buffer to stitch incomming transmission together

  PROCEDURE Init
   LPARAMETERS tnRequestID
   LOCAL llRetVal
   This.nCreateTime = SECONDS()
   This.Accept(tnRequestID)
   ThisForm.nstat = this.State
   ThisForm.Refresh()
   RETURN
  ENDPROC

  PROCEDURE DataArrival
   LPARAMETERS tnByteCount
   LOCAL lcBuffer
   lcBuffer = SPACE(tnByteCount)

* This gets the data from the socket. It can happen, that the data isn't
* received in a single rush. Thus we need a EOT (end of transmission)
* sign to be sure, the data is complete. Until we get this, the data
* is stuffed into cReceiveBuffer.

   This.GetData( @lcBuffer, , tnByteCount )
   IF AT( EOT, lcBuffer ) = 0 && Not yet finished
    This.cReceiveBuffer = This.cReceiveBuffer + lcBuffer
   ELSE
    This.cReceiveBuffer = This.cReceiveBuffer + LEFT( lcBuffer, AT( EOT, lcBuffer ) -1 )

* First we strip off the EOT sign that has done it's purpose ...
* then follows the "real" action. All we want to do should be done
* here now. For a sample we show the incoming text in an
* editbox
    WITH ThisForm.EditOut
     .Value = .Value + This.cReceiveBuffer + CHR(13) + CHR(10)
     .Refresh()
    ENDWITH

* But we can do a lot more of course eg ...
* return the time of the servers machine when we get a request
* for it ...

    IF UPPER( LEFT( This.cReceiveBuffer, 7 ) ) = 'GETTIME'

* Again in a production app we would have to be a little
* more careful. If the connection got lost meanwhile this
* returns an ugly error with a a popping up Messagebox :-(

     This.SendData( TTOC(datetime()) + EOT )
    ENDIF

* Finally the receive Buffer has to be cleared again to
* be ready for the next transmission

    This.cReceiveBuffer = ''
   ENDIF
   RETURN
  ENDPROC

  PROCEDURE Close
   This.Object.Close()
  ENDPROC

ENDDEFINE

* --- AutoScrolling EditBox

DEFINE CLASS bEditBox AS EditBox
  PROCEDURE refresh
   WITH This
     .SelStart = len(.text)
   ENDWITH
  ENDPROC
ENDDEFINE



... and now the client application ..



*-----------------| Location Section |--------------------
*) Procedure..: A simple TCP/IP client test form
*} Library....:
*} Class......:
*} Method.....:
*) Author........: Markus Voellmy
*) Company.......:
*) Description...: A client for TCP/IP. Uses Winsock OCX for communications.
*-------------------| Usage Section |---------------------
*$ Scope.........:
*$ Parameters....: tnPort - Numeric. The port number. If not supplied, 63333 is used.
*$ tcRemoteHost - Character. The remote host address. If not supplied, "localhost" is used.
*$ Usage.........: Simple run it. Parameters are optional.
*$ Example.......: DO tcpclient WITH 63333, "localhost"
*$ Returns.......:
*-------------------| Various Info |----------------------
*@ Precondition Invariants.....:
*@ Post-condition Invariants...:
*----------------| Maintenance Section |------------------
*? To Do............:
*= Methods Called...:
** Process..........: This test client uses the Winsock OCX and stores the received data in a temporary
** buffer until the EndOfTransmission (EOT = CHR(4)) is received.
*^ Change Log.......:
*---------------------------------------------------------

LPARAMETERS tnPort, tcRemoteHost
#DEFINE EOT CHR(4) && End of Transmission sign
CLEAR
IF VARTYPE(tnPort) # "N"
 tnPort = 63333
ENDIF
IF VARTYPE(tcRemoteHost) # "C"
 tcRemoteHost = "localhost"
ENDIF
oForm = CREATEOBJECT('frmTCPClient',tnPort,tcRemoteHost)
READ EVENTS
RELEASE oForm
RETURN

*) -- The form definition --

DEFINE CLASS frmTCPClient AS FORM
  nProtocol = 0
  nPort = 0 
&& there a normal unusued port will be filled
  cRMHost = ""
  AutoCenter = .T.
  Caption = 'TCP-Client'
  nStat = 0
  Width = 500
  lConnected = .F. && Semaphore to signal the connection state

  PROCEDURE Load
   SYS(2333,0)
   _VFP.AutoYield = .F.
   RETURN
  ENDPROC

  PROCEDURE Unload
   _VFP.AutoYield = .T.
   RETURN
  ENDPROC

  PROCEDURE QueryUnload
   CLEAR EVENTS
   RETURN
  ENDPROC

  PROCEDURE Init
   LPARAMETERS tnPort, tcRemoteHost
   ThisForm.nPort = tnPort
   ThisForm.cRMHost = tcRemoteHost
   This.AddObject('EditOut', 'bEditBox')
   WITH This.EditOut
    .Top = 120
    .Left = 10
    .Width = This.Width-20
    .Height = This.Height-(.Top+5)
    .Readonly = .t.
    .Value = ''
    .Visible = .T.
   ENDWITH
   This.AddObject('txtRMHost', 'rTextBox')
   WITH This.txtRMHost
    .Top = 30
    .Left = 10
    .Width = 100
    .Enabled = .T.
    .ControlSource = 'ThisForm.cRMHost'
    .Visible = .t.
   ENDWITH
   This.AddObject('lblRemoteHost', 'label')
   WITH This.lblRemoteHost
    .Top = 10
    .Left = 10
    .Autosize = .T.
    .Caption = 'RemoteHost'
    .Visible = .T.
   ENDWITH
   This.AddObject('txtRemotePort', 'rTextBox')
   WITH This.txtRemotePort
    .Top = 30
    .Left = 130
    .Width = 50
    .Enabled = .T.
    .ControlSource = 'ThisForm.nPort'
    .Visible = .T.
   ENDWITH
   This.AddObject('lblTCPPort', 'label')
   WITH This.lblTCPPort
    .Top = 10
    .Left = 130
    .AutoSize = .T.
    .Caption = 'TCP-Port'
    .Visible = .T.
   ENDWITH
   This.AddObject('cmdConnect', 'myConnCB')
   WITH This.cmdConnect
    .Top = 30
    .Left = 240
    .Height = 24
    .Width = 100
    .Visible = .T.
   ENDWITH
   This.AddObject('cmdDisconnect', 'myDisconnCB')
   WITH this.cmdDisconnect
    .Top = 30
    .Left = 360
    .Height = 24
    .Width = 100
    .Visible = .T.
   ENDWITH
   This.AddObject('txtInbox', 'r2TextBox')
   WITH This.txtInbox
    .Top = 80
    .Left = 10
    .Height = 24
    .Width = 370
    .Value = "" && An empty string
    .Visible = .T.
   ENDWITH
   This.AddObject('cmdSend', 'mySendCB')
   WITH This.cmdSend
    .Top = 80
    .Left = 390
    .Height = 24
    .Width = 100
    .Visible = .T.
   ENDWITH
   This.AddObject('oSock', 'frmSock' )
   This.AddObject('txtStat', 'TextBox')
   WITH This.txtStat
    .Top = 30
    .Left = 200
    .Width = 20
    .Enabled = .F.
    .ControlSource = 'Thisform.oSock.State'
    .Visible = .T.
   ENDWITH

   This.Refresh()
   This.Visible = .T.
   RETURN
  ENDPROC
ENDDEFINE
* -------- WinSock ActiveX
DEFINE CLASS frmSock AS OleControl
  OleClass = "MSWinsock.Winsock"
  cReceiveBuffer = ''

  && a buffer to stitch incomming transmission together

  PROCEDURE Error
   LPARAMETERS Number, Description, Scode, Source, Helpfile, Helpcontext, Canceldisplay
* This method is used only for error diplaying purposes.
   WITH Thisform.EditOut
    .Value = .Value + CHR(13) + CHR(10) +;
    "Error ---- " + STR(Number) +' - ' + Description + CHR(13) + CHR(10)
    .Refresh()
   EndWith
ENDPROC
  PROCEDURE Close

* This is necessary to really close the socket, without it you will end up
* in a timeout
   This.Object.Close()
  ENDPROC

  PROCEDURE Destroy
* It's used to close the socket if the user close the form
   This.Object.Close()
  ENDPROC

  PROCEDURE DataArrival
   LPARAMETERS tnByteCount
   LOCAL lcBuffer
   lcBuffer = SPACE(tnByteCount)

* This gets the data from the socket. It happens, that the data
* isn't received in a single rush. Thus we use a EOT (end of transmission)
* sign to be sure, the data is complete. Until we get this, the data is stuffed
* into cRecieveBuffer.

   This.GetData( @lcBuffer, , tnByteCount )
   IF AT( EOT, lcBuffer ) = 0  && CHR(4) not found, not yet finished
    This.cReceiveBuffer = This.cReceiveBuffer + lcBuffer
   ELSE
    This.cReceiveBuffer = This.cReceiveBuffer + LEFT( lcBuffer, AT( EOT, lcBuffer ) -1 )
* Other than the server this only shows the results 
    With ThisForm.EditOut
     .Value = .Value+This.cReceiveBuffer+chr(13)+chr(10)
     ThisForm.refresh()
    Endwith

* Finally the receive Buffer has to be cleared again to
* be ready for the next transmission

    This.cReceiveBuffer = ''
   ENDIF
   RETURN
  ENDPROC
ENDDEFINE
* --- Send CommandButton
DEFINE CLASS mySendCB AS CommandButton
  Caption = 'Send'

  PROCEDURE Refresh
   This.Enabled = ThisForm.lConnected
  ENDPROC
	
  PROCEDURE Click
   WITH ThisForm.oSock
    IF .state = 7 
&& No connection, no send
     .SendData(ALLTRIM(ThisForm.txtInbox.Value)+EOT)
    ELSE
     .Error( -1, 'Connection lost', , , , , .T. )
     .Close()
     ThisForm.lConnected = .F.
    ENDIF
   ENDWITH
   ThisForm.Refresh()
  ENDPROC
ENDDEFINE
* --- Connect CommandButton
DEFINE CLASS myConnCB AS CommandButton
  Caption = 'Connect'

  PROCEDURE Refresh
   This.Enabled = Not ThisForm.lConnected
  ENDPROC
	
  PROCEDURE Click
   WITH ThisForm.oSock
   IF .state != 0

&& The connection isn't idle ... we simply close it
    .Object.Close()
   ENDIF
   .protocol = 0  && TCP
   .remoteHost = ALLTRIM(ThisForm.crmhost) 
&& RemoteHostname
   .remotePort = ThisForm.nPort 
&& RemotePort
   .localPort = 0 && Takes any available LocalPort
   .Object.Connect()
   DO WHILE .Object.state < 7
    DOEVENTS && we must check for the State
    ThisForm.txtStat.Refresh() 
&& and show it on the form
    IF .state = 9
     EXIT
    ENDIF
   ENDDO
    IF .object.state = 7
     ThisForm.lConnected = .T.
    ELSE && we Couldn't connect :-(
     ThisForm.lConnected = .F.
    ENDIF
   ENDWITH
   ThisForm.Refresh()
  ENDPROC
ENDDEFINE
* --- Disconnect CommandButton
DEFINE CLASS myDisConnCB AS CommandButton
  Caption = 'Disconnect'

  PROCEDURE Refresh
   This.Enabled = ThisForm.lConnected
  ENDPROC
	
  PROCEDURE Click
   Thisform.oSock.Object.Close()
   DO WHILE Thisform.oSock.state > 0
    DOEVENTS
    ThisForm.txtStat.Refresh()
   ENDDO
   ThisForm.lConnected = .F.
   ThisForm.Refresh()
  ENDPROC
ENDDEFINE
* --- Controlled Texbox, reacts on disconnect
DEFINE CLASS rTextBox AS TextBox
  PROCEDURE Refresh
   This.Enabled = NOT ThisForm.lConnected
  ENDPROC
ENDDEFINE
* --- Controlled Texbox, reacts on connect
DEFINE CLASS r2TextBox AS TextBox
  PROCEDURE Refresh
   This.Enabled = ThisForm.lConnected
  ENDPROC
ENDDEFINE
* --- AutoScrolling EditBox
DEFINE CLASS bEditBox AS EditBox
  PROCEDURE refresh
   WITH This
     .SelStart = len(.text)
   ENDWITH
  ENDPROC
ENDDEFINE
