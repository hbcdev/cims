**แสดง NETWORK
Declare Integer WNetOpenEnum In WIN32API ;
	INTEGER dwScope, ;
	INTEGER dwType, ;
	INTEGER dwUseage, ;
	STRING @ lpNetResource, ;
	INTEGER @ lphEnum
Declare Integer WNetEnumResource In WIN32API ;
	INTEGER hEnum, ;
	INTEGER @lpcCount, ;
	INTEGER lpBuffer, ;
	INTEGER @ lpBufferSize
Declare Integer WNetCloseEnum In WIN32API Integer hEnum
Local oHeapObj, oNetRsc, hEnum, nResult, nBuff, cBuff, nCnt, i
oHeapObj=Createobj('Heap')
oNetRsc=Createobj('NETRESOURCE',oHeapObj)
hEnum = 0
=WNetOpenEnum(2,0,3,0,@hEnum)
nResult = 0
nBuffPtr = oHeapObj.Alloc(4000)
Do While nResult = 0
	oHeapObj.CopyTo(nBuffPtr, Space(4000))
	nCnt = 25
	nBufSize = 4000
	nResult = WNetEnumResource(@hEnum, @nCnt, nBuffPtr, @nBufSize)
	cBuff = oHeapObj.CopyFrom(nBuffPtr)
	For i = 0 To nCnt-1
		oNetRsc.cNETRESOURCE = Subst(cBuff,(32 * i + 1),32)
		oNetRsc.ParseNETRESOURCE()
		If ! Isnull(oNetRsc.GetRemoteName())
			? oNetRsc.GetLocalName() &&, oNetRsc.GetRemoteName(), oNetRsc.GetProviderName(), oNetRsc.GetUseage(), oNetRsc.GetType()
			If 'CONTAINER' $ oNetRsc.GetUseage()
				oNetRsc.SetUseage('CONTAINER')
				oNetRsc.BuildNETRESOURCE
				=GetMoreShare(oNetRsc.cNETRESOURCE, oHeapObj)
			Endif
		Endif
	Endfor
Enddo
=WNetCloseEnum(hEnum)
oHeapObj.DeAlloc(nBuffPtr)
Return

***********************************
Procedure GetMoreShare
Lparameter cNetRsc, oHeapObj
Local oNR, hEnum
oNR = Createobj('NETRESOURCE',oHeapObj)
hEnum = 0
=WNetOpenEnum(2,0,3,cNetRsc,@hEnum)
Local nResult, nBuffPtr, nBufSize, nCnt, cBuff, i
nResult = 0
nBuffPtr = oHeapObj.Alloc(4000)
Do While nResult = 0
	oHeapObj.CopyTo(nBuffPtr, Space(4000))
	nCnt = 25
	nBufSize = 4000
	nResult = WNetEnumResource(@hEnum, @nCnt, nBuffPtr, @nBufSize)
	cBuff = oHeapObj.CopyFrom(nBuffPtr)
	For i = 0 To nCnt-1
		oNR.cNETRESOURCE = Subst(cBuff,(32 * i + 1),32)
		oNR.ParseNETRESOURCE()
		If ! Isnull(oNR.GetRemoteName())
			If oNR.GetType()='DISK'
				? oNR.GetLocalName(), oNR.GetRemoteName(),oNR.GetProviderName(), oNR.GetUseage(), oNR.GetType()
				?oNR.GetRemoteName()
			Endif
			If 'CONTAINER' $ oNR.GetUseage()
				oNR.SetUseage('CONTAINER')
				oNR.BuildNETRESOURCE
				=GetMoreShare(oNR.cNETRESOURCE, oHeapObj)
			Endif
		Endif
	Endfor
Enddo
=WNetCloseEnum(hEnum)
oHeapObj.DeAlloc(nBuffPtr)
Return

***********************************************
Define Class heap As Custom
	Protected inHandle
	inHandle = Null
	Protected inNumAllocsActive
	inNumAllocsActive = 0
	Name = "heap"
	Dimension iaAllocs[1,3]

	Procedure Alloc
	Lparameter nSize
	Declare Integer HeapAlloc In WIN32API As HAlloc;
		INTEGER hHeap, ;
		INTEGER dwFlags, ;
		INTEGER dwBytes
	Declare Integer HeapSize In WIN32API As HSize ;
		INTEGER hHeap, ;
		INTEGER dwFlags, ;
		INTEGER lpcMem
	Local nPtr
	With This
		nPtr = HAlloc(.inHandle, 0, @nSize)
		If nPtr # 0
			.inNumAllocsActive = .inNumAllocsActive + 1
			Dimension .iaAllocs[.inNumAllocsActive,3]
			.iaAllocs[.inNumAllocsActive,1] = nPtr
			.iaAllocs[.inNumAllocsActive,2] = HSize(.inHandle, 0, nPtr)
			.iaAllocs[.inNumAllocsActive,3] = .T.
		Else
			nPtr = Null
		Endif
	Endwith
	Return nPtr
	Endproc

	Function AllocBLOB
	Lparameter cBStringToCopy
	Local nAllocPtr
	With This
		nAllocPtr = .Alloc(Len(cBStringToCopy))
		.CopyTo(nAllocPtr,cBStringToCopy)
	Endwith
	Return nAllocPtr
	Endfunc

	Function AllocString
	Lparameter cString
	Return This.AllocBLOB(cString + Chr(0))
	Endfunc

	Function AllocInitAs
	Lparameter nSizeOfBuffer, nByteValue
	If Type('nByteValue') # 'N' Or ! Between(nByteValue,0,255)
		nByteValue = 0
	Endif
	Return This.AllocBLOB(Replicate(Chr(nByteValue),nSizeOfBuffer))
	Endfunc

	Procedure DeAlloc
	Lparameter nPtr
	Declare Integer HeapFree In WIN32API As HFree ;
		INTEGER hHeap, ;
		INTEGER dwFlags, ;
		INTEGER lpMem
	Local nCtr, lSucceeds
	lSucceeds = .F.
	With This
		For nCtr = 1 To .inNumAllocsActive
			If .iaAllocs[nCtr,1] = nPtr
				If .iaAllocs[nCtr,3]
					=HFree(.inHandle, 0, nPtr)
					.iaAllocs[nCtr,3] = .F.
				Endif
				lSucceeds = .T.
				Exit
			Endif
		Endfor
	Endwith
	Return lSucceeds
	Endproc


	Procedure CopyTo
	Lparameter nPtr, cSource
	Declare RtlMoveMemory In WIN32API As RtlCopy ;
		INTEGER nDestBuffer, ;
		STRING @pVoidSource, ;
		INTEGER nLength
	Local nCtr, lSucceeds
	lSucceeds = .F.
	With This
		For nCtr = 1 To .inNumAllocsActive
			If .iaAllocs[nCtr,1] = nPtr
				If .iaAllocs[nCtr,3]
					lSucceeds = .T.
					Exit
				Endif
			Endif
		Endfor
		If lSucceeds
			=RtlCopy((.iaAllocs[nCtr,1]), ;
				cSource, ;
				MIN(Len(cSource),.iaAllocs[nCtr,2]))
		Endif
	Endwith
	Return lSucceeds
	Endproc

	Procedure CopyFrom
	Lparameter nPtr
	Declare RtlMoveMemory In WIN32API As RtlCopy ;
		STRING @DestBuffer, ;
		INTEGER pVoidSource, ;
		INTEGER nLength
	Local nCtr, lSucceeds
	lSucceeds = .F.
	With This
		For nCtr = 1 To .inNumAllocsActive
			If .iaAllocs[nCtr,1] = nPtr
				If This.iaAllocs[nCtr,3]
					lSucceeds = .T.
					Exit
				Endif
			Endif
		Endfor
		If lSucceeds
			Local uBuffer
			uBuffer = Repl(Chr(0),.iaAllocs[nCtr,2])
			=RtlCopy(@uBuffer, ;
				(.iaAllocs[nCtr,1]), ;
				(.iaAllocs[nCtr,2]))
		Else
			uBuffer = Null
		Endif
	Endwith
	Return uBuffer
	Endproc

	Procedure SizeOfBlock
	Lparameters nPtr
	Local nCtr, nSizeOfBlock
	nSizeOfBlock = Null
	With This
		For nCtr = 1 To .inNumAllocsActive
			If .iaAllocs[nCtr,1] = nPtr
				If This.iaAllocs[nCtr,3]
					nSizeOfBlock = .iaAllocs[nCtr,2]
					Exit
				Endif
			Endif
		Endfor
	Endwith
	Return nSizeOfBlock

	Procedure Destroy
	Declare HeapDestroy In WIN32API As HDestroy ;
		INTEGER hHeap

	Local nCtr
	With This
		For nCtr = 1 To .inNumAllocsActive
			If .iaAllocs[nCtr,3]
				.DeAlloc(.iaAllocs[nCtr,1])
			Endif
		Endfor
		HDestroy[.inHandle]
	Endwith
	DoDefault()
	Endproc


	Procedure Init
	Declare Integer HeapCreate In WIN32API As HCreate ;
		INTEGER dwOptions, ;
		INTEGER dwInitialSize, ;
		INTEGER dwMaxSize
	#Define SwapFilePageSize 4096
	#Define BlockAllocSize 2 * SwapFilePageSize
	With This
		.inHandle = HCreate(0, BlockAllocSize, 0)
		Dimension .iaAllocs[1,3]
		.iaAllocs[1,1] = 0
		.iaAllocs[1,2] = 0
		.iaAllocs[1,3] = .F.
		.inNumAllocsActive = 0
	Endwith
	Return (This.inHandle # 0)
	Endproc
Enddefine

************************************************
Function SetMem
Lparameters nPtr, cSource
Declare RtlMoveMemory In WIN32API As RtlCopy ;
	INTEGER nDestBuffer, ;
	STRING @pVoidSource, ;
	INTEGER nLength
RtlCopy(nPtr, ;
	cSource, ;
	LEN(cSource))
Return .T.

Function GetMem
Lparameters nPtr, nLength
Declare RtlMoveMemory In WIN32API As RtlCopy ;
	STRING @DestBuffer, ;
	INTEGER pVoidSource, ;
	INTEGER nLength
Local uBuffer
uBuffer = Repl(Chr(0),nLength)
=RtlCopy(@uBuffer, ;
	nPtr, ;
	nLength)
Return uBuffer

Function GetMemString
Lparameters nPtr
Declare Integer lstrcpyn In WIN32API As StrCpyN ;
	STRING @ lpDestString, ;
	INTEGER lpSource, ;
	INTEGER nMaxLength
Local uBuffer
uBuffer = Repl(Chr(0), 512)
If StrCpyN(@uBuffer, nPtr, 512) # 0
	uBuffer = Left(uBuffer, Max(0,At(Chr(0),uBuffer) - 1))
Else
	uBuffer = Null
Endif
Return uBuffer

Function DWORDToNum
Lparameter tcDWORD
Local b0,b1,b2,b3
b0=Asc(tcDWORD)
b1=Asc(Subs(tcDWORD,2,1))
b2=Asc(Subs(tcDWORD,3,1))
b3=Asc(Subs(tcDWORD,4,1))
Return ( ( (b3 * 256 + b2) * 256 + b1) * 256 + b0)

Function SHORTToNum
Lparameter tcInt
Local b0,b1,nRetVal
b0=Asc(tcInt)
b1=Asc(Subs(tcInt,2,1))
If b1<128
	nRetVal=b1 * 256 + b0
Else
	b1=255-b1
	b0=256-b0
	nRetVal= -( (b1 * 256) + b0)
Endif
Return nRetVal

Function WORDToNum
Lparameter tcWORD
Return (256 * Asc(Subst(tcWORD,2,1)) ) + Asc(tcWORD)

Function NumToDWORD
Lparameter tnNum
Local x,N,i,b0[4]
x=Int(tnNum)
For i=3 To 0 Step -1
	b0[i+1]=Int(x/(256^i))
	x=Mod(x,(256^i))
Endfor
Return Chr(b0[1])+Chr(b0[2])+Chr(b0[3])+Chr(b0[4])

Function NumToSHORT
Lparameter tnNum
Local b0,b1,x
If tnNum>=0
	x=Int(tnNum)
	b1=Int(x/256)
	b0=Mod(x,256)
Else
	x=Int(-tnNum)
	b1=255-Int(x/256)
	b0=256-Mod(x,256)
	If b0=256
		b0=0
		b1=b1+1
	Endif
Endif
Return Chr(b0)+Chr(b1)

Function NumToWORD
Lparameter tnNum
Local x
x=Int(tnNum)
Return Chr(Mod(x,256))+Chr(Int(x/256))

Function AllocNetAPIBuffer
Lparameter nSize
If Type('nSize') # 'N' Or nSize <= 0
	Return Null
Endif
If ! 'NT' $ Os()
	Return Null
Endif
Declare Integer NetApiBufferAllocate In NETAPI32.Dll ;
	INTEGER dwByteCount, ;
	INTEGER lpBuffer
Local nBufferPointer
nBufferPointer = 0
If NetApiBufferAllocate(Int(nSize), @nBufferPointer) # 0
	nBufferPointer = Null
Endif
Return nBufferPointer

Function DeAllocNetAPIBuffer
Lparameter nPtr
If Type('nPtr') # 'N'
	Return .F.
Endif
If ! 'NT' $ Os()
	Return .F.
Endif
Declare Integer NetApiBufferFree In NETAPI32.Dll ;
	INTEGER lpBuffer
Return (NetApiBufferFree(Int(nPtr)) = 0)

Function CopyDoubleToString
Lparameter nDoubleToCopy
Declare RtlMoveMemory In WIN32API As RtlCopyDbl ;
	STRING @DestString, ;
	DOUBLE @pVoidSource, ;
	INTEGER nLength
Local cString
cString = Space(8)
=RtlCopyDbl(@cString, nDoubleToCopy, 8)
Return cString

Function DoubleToNum
Lparameter cDoubleInString
Declare RtlMoveMemory In WIN32API As RtlCopyDbl ;
	DOUBLE @DestNumeric, ;
	STRING @pVoidSource, ;
	INTEGER nLength
Local nNum
nNum = 0.000
=RtlCopyDbl(@nNum, cDoubleInString, 8)
Return nNum

****************************************
Define Class NETRESOURCE As Custom
	Protected oHeapObj, cType, cDisplayType, cUseage, cLocalName, cRemoteName, cProviderName, nHeapAlloc
	oHeapObj = Null
	nHeapAlloc = Null
	cScope = 'GLOBALNET'
	cType = 'ANY'
	cDisplayType = 'GENERIC'
	cUseage = 'CONNECTABLE'
	cLocalName = ''
	cRemoteName = ''
	cProviderName = ''
	cNETRESOURCE = ''

	Procedure Init
	Lparameters oHeapObj, cScope, cType, cDisplayType , cUseage, cLocalName, cRemoteName, cProviderName
	If Type('oHeap') # 'O' Or Isnull(oHeapObj)
		This.oHeapObj = Createobj('Heap')
	Else
		This.oHeapObj = oHeapObj
	Endif
	With This
		.SetScope(cScope)
		.SetType(cType)
		.SetDisplayType(cDisplayType)
		.SetUseage(cUseage)
		.SetLocalName(cLocalName)
		.SetRemoteName(cRemoteName)
		.SetProviderName(cProviderName)
	Endwith
	Return .T.
	Endproc

	Procedure Destroy
	If ! Isnull(This.nHeapAlloc)
		This.oHeapObj.DeAlloc(This.nHeapAlloc)
		This.nHeapAlloc = Null
	Endif
	This.oHeapObj = ''
	DoDefault()
	Endproc

	Function SetLocalName
	Lparameter cLocalName
	If Type('cLocalName') = 'C'
		This.cLocalName = cLocalName
		Return .T.
	Else
		This.cLocalName = ''
		Return .F.
	Endif
	Endfunc

	Function GetLocalName
	Return This.cLocalName
	Endfunc

	Function SetRemoteName
	Lparameter cRemoteName
	If Type('cRemoteName') = 'C'
		This.cRemoteName = cRemoteName
		Return .T.
	Else
		This.cRemoteName = ''
		Return .F.
	Endif
	Endfunc

	Function GetRemoteName
	Return This.cRemoteName
	Endfunc

	Function SetProviderName
	Lparameter cProviderName
	If Type('cProviderName') = 'C'
		This.cProviderName = cProviderName
		Return .T.
	Else
		This.cProviderName = ''
		Return .F.
	Endif
	Endfunc

	Function GetProviderName
	Return This.cProviderName
	Endfunc

	Function SetScope
	Lparameter cScope
	Local lResult
	lResult = .F.
	If Type('cScope') = 'C' And Inlist(Upper(cScope),'CONNECTED','GLOBALNET','REMEMBERED')
		This.cScope = Upper(cScope)
		lResult = .T.
	Else
		This.cScope = 'GLOBALNET'
	Endif
	Return lResult
	Endfunc

	Function GetScope
	Return This.cScope
	Endfunc

	Protected Function ScopeConvert
		Lparameter uScopeValue
		Local uReturnValue
		If Type('uScopeValue') = 'N'
			Do Case
			Case uScopeValue = 1
				uReturnValue = 'CONNECTED'
			Case uScopeValue = 2
				uReturnValue = 'GLOBALNET'
			Case uScopeValue = 3
				uReturnValue = 'REMEMBERED'
			Otherwise
				uReturnValue = 'UNKNOWN '+Transform(uScopeValue,'@0')
			Endcase
		Else
			Do Case
			Case Upper(uScopeValue) = 'CONNECTED'
				uReturnValue = 1
			Case Upper(uScopeValue) = 'GLOBALNET'
				uReturnValue = 2
			Case Upper(uScopeValue) = 'REMEMBERED'
				uReturnValue = 3
			Otherwise
				uReturnValue = -1
			Endcase
		Endif
		Return uReturnValue
		Endfunc

	Function SetType
	Lparameter cType
	Local lResult
	lResult = .F.
	If Type('cType') = 'C' And Inlist(Upper(cType),'ANY','DISK','PRINTER')
		This.cType = Upper(cType)
		lResult = .T.
	Else
		This.cType = 'ANY'
	Endif
	Return lResult
	Endfunc

	Function GetType
	Return This.cType
	Endfunc

	Protected Function TypeConvert
		Lparameter uTypeValue
		Local uReturnValue
		If Type('uTypeValue') = 'N'
			Do Case
			Case uTypeValue = 0
				uReturnValue = 'ANY'
			Case uTypeValue = 1
				uReturnValue = 'DISK'
			Case uTypeValue = 2
				uReturnValue = 'PRINTER'
			Otherwise
				uReturnValue = 'UNKNOWN '+Transform(uTypeValue,'@0')
			Endcase
		Else
			Do Case
			Case Upper(uTypeValue) = 'ANY'
				uReturnValue = 0
			Case Upper(uTypeValue) = 'DISK'
				uReturnValue = 1
			Case Upper(uTypeValue) = 'PRINTER'
				uReturnValue = 2
			Otherwise
				uReturnValue = -1
			Endcase
		Endif
		Return uReturnValue
		Endfunc

	Function SetDisplayType
	Lparameter cDisplayType
	Local lResult
	lResult = .F.
	If Type('cDisplayType') = 'C' And Inlist(Upper(cDisplayType),'GENERIC','DOMAIN','SERVER','SHARE','FILE','GROUP','NETWORK','ROOT','SHAREDADMIN','DIRECTORY','NDS_TREE','NDSCONTAINER')
		This.cDisplayType = Upper(cDisplayType)
		lResult = .T.
	Else
		This.cDisplayType = 'GENERIC'
	Endif
	Return lResult
	Endfunc

	Function GetDisplayType
	Return This.cDisplayType
	Endfunc

	Protected Function DisplayTypeConvert
		Lparameter uDisplayTypeValue
		Local uReturnValue
		If Type('uDisplayTypeValue') = 'N'
			Do Case
			Case uDisplayTypeValue = 0
				uReturnValue = 'GENERIC'
			Case uDisplayTypeValue = 1
				uReturnValue = 'DOMAIN'
			Case uDisplayTypeValue = 2
				uReturnValue = 'SERVER'
			Case uDisplayTypeValue = 3
				uReturnValue = 'SHARE'
			Case uDisplayTypeValue = 4
				uReturnValue = 'FILE'
			Case uDisplayTypeValue = 5
				uReturnValue = 'GROUP'
			Case uDisplayTypeValue = 6
				uReturnValue = 'NETWORK'
			Case uDisplayTypeValue = 7
				uReturnValue = 'ROOT'
			Case uDisplayTypeValue = 8
				uReturnValue = 'SHAREDADMIN'
			Case uDisplayTypeValue = 9
				uReturnValue = 'DIRECTORY'
			Case uDisplayTypeValue = 10
				uReturnValue = 'NDS_TREE'
			Case uDisplayTypeValue = 11
				uReturnValue = 'NDSCONTAINER'
			Otherwise
				uReturnValue = 'UNKNOWN '+Transform(uDisplayTypeValue,'@0')
			Endcase
		Else
			Do Case
			Case uDisplayTypeValue = 'GENERIC'
				uReturnValue = 0
			Case uDisplayTypeValue = 'DOMAIN'
				uReturnValue = 1
			Case uDisplayTypeValue = 'SERVER'
				uReturnValue = 2
			Case uDisplayTypeValue = 'SHARE'
				uReturnValue = 3
			Case uDisplayTypeValue = 'FILE'
				uReturnValue = 4
			Case uDisplayTypeValue = 'GROUP'
				uReturnValue = 5
			Case uDisplayTypeValue = 'NETWORK'
				uReturnValue = 6
			Case uDisplayTypeValue = 'ROOT'
				uReturnValue = 7
			Case uDisplayTypeValue = 'SHAREDADMIN'
				uReturnValue = 8
			Case uDisplayTypeValue = 'DIRECTORY'
				uReturnValue = 9
			Case uDisplayTypeValue = 'NDS_TREE'
				uReturnValue = 10
			Case uDisplayTypeValue = 'NDSCONTAINER'
				uReturnValue = 11
			Otherwise
				uReturnValue = -1
			Endcase
		Endif
		Return uReturnValue
		Endfunc

	Function SetUseage
	Lparameter cUseage
	Local lResult,cParms,cParseString
	lResult = .F.
	cParms = ''
	If Type('cUseage') = 'C'
		cParseString = Upper(cUseage)
		If cParseString = 'ALL'
			cParms = 'ALL'
			lResult = .T.
		Else
			If 'CONNECTABLE' $ cParseString
				lResult = .T.
				cParms = 'CONNECTABLE+'
			Endif
			If 'CONTAINER' $ cParseString
				lResult = .T.
				cParms = cParms + 'CONTAINER+'
			Endif
			If 'NOLOCALDEVICE' $ cParseString
				lResult = .T.
				cParms = cParms + 'NOLOCALDEVICE+'
			Endif
			If 'SIBLING' $ cParseString
				lResult = .T.
				cParms = cParms + 'SIBLING+'
			Endif
			If 'ATTACHED' $ cParseString
				lResult = .T.
				cParms = cParms + 'ATTACHED+'
			Endif
			If lResult
				cParms = Left(cParms, Len(cParms) - 1)
			Else
				cParms = 'ALL'
			Endif
			This.cUseage = cParms
		Endif
	Else
		This.cUseage = 'CONNECTABLE'
	Endif
	Return lResult
	Endfunc

	Function GetUseage
	Return This.cUseage
	Endfunc

	Protected Function UseageConvert
		Lparameter uUseageValue
		Local uReturnValue, cParms
		If Type('uUseageValue') = 'N'
			cParms = ''
			If uUseageValue = 31
				uReturnValue = 'ALL'
			Else
				If Bitand(uUseageValue,1) # 0
					cParms = 'CONNECTABLE+'
				Endif
				If Bitand(uUseageValue,2) # 0
					cParms = cParms + 'CONTAINER+'
				Endif
				If Bitand(uUseageValue,4) # 0
					cParms = cParms + 'NOLOCALDEVICE+'
				Endif
				If Bitand(uUseageValue,8) # 0
					cParms = cParms + 'SIBLING+'
				Endif
				If Bitand(uUseageValue,16) # 0
					cParms = cParms + 'ATTACHED+'
				Endif
				If Bitand(uUseageValue,0x7FFFFFE0) # 0
					cParms = cParms + 'UNKNOWN '+Transform(Bitand(uUseageValue,0x7FFFFFE0),'@0') + '+'
				Endif
				If Len(cParms) > 0
					uReturnValue = Left(cParms, Len(cParms) - 1)
				Else
					uReturnValue = 'NONE'
				Endif
			Endif
		Else
			cParms = Upper(uUseageValue)
			uReturnValue = 0
			If cParms = 'ALL'
				uReturnValue = 31
			Else
				If 'CONNECTABLE' $ cParms
					uReturnValue = uReturnValue + 1
				Endif
				If 'CONTAINER' $ cParms
					uReturnValue = uReturnValue + 2
				Endif
				If 'NOLOCALDEVICE' $ cParms
					uReturnValue = uReturnValue + 4
				Endif
				If 'SIBLING' $ cParms
					uReturnValue = uReturnValue + 8
				Endif
				If 'ATTACHED' $ cParms
					uReturnValue = uReturnValue + 16
				Endif
			Endif
		Endif
		Return uReturnValue
		Endfunc

	Function BuildNETRESOURCE
	With This
		If ! Isnull(.nHeapAlloc)
			.oHeapObj.DeAlloc(.nHeapAlloc)
			.nHeapAlloc = Null
		Endif
		Local cNETRESOURCE, nRemoteNameOffset, nProviderNameOffset, nAllocSize, cBuffer
		cBuffer = .cLocalName + Chr(0)
		nRemoteNameOffset = Len(cBuffer)
		cBuffer = cBuffer + .cRemoteName + Chr(0)
		nProviderNameOffset = Len(cBuffer)
		cBuffer = cBuffer + .cProviderName + Chr(0)
		.nHeapAlloc = .oHeapObj.AllocBLOB(cBuffer)
		.cNETRESOURCE = NumToDWORD(.ScopeConvert(.cScope)) + ;
			NumToDWORD(.TypeConvert(.cType)) + ;
			NumToDWORD(.DisplayTypeConvert(.cDisplayType)) + ;
			NumToDWORD(.UseageConvert(.cUseage)) + ;
			NumToDWORD(.nHeapAlloc) + ;
			NumToDWORD(.nHeapAlloc + nRemoteNameOffset) + ;
			NumToDWORD(0) + ;
			NumToDWORD(.nHeapAlloc + nProviderNameOffset)
	Endwith
	Return .T.
	Endfunc

	Function ParseNETRESOURCE
	With This
		If Len(.cNETRESOURCE) < 32
			Return .F.
		Else
			.cScope = .ScopeConvert(DWORDToNum(.cNETRESOURCE))
			.cType = .TypeConvert(DWORDToNum(Subst(.cNETRESOURCE,5)))
			.cDisplayType = .DisplayTypeConvert(DWORDToNum(Subst(.cNETRESOURCE,9)))
			.cUseage = .UseageConvert(DWORDToNum(Subst(.cNETRESOURCE,13)))
			Local nPtr
			nPtr = DWORDToNum(Subst(.cNETRESOURCE,17))
			If nPtr # 0
				.cLocalName = GetMemString(nPtr)
			Else
				.cLocalName = ''
			Endif
			nPtr = DWORDToNum(Subst(.cNETRESOURCE,21))
			If nPtr # 0
				.cRemoteName = GetMemString(nPtr)
			Else
				.cRemoteName = ''
			Endif
			nPtr = DWORDToNum(Subst(.cNETRESOURCE,29))
			If nPtr # 0
				.cProviderName = GetMemString(nPtr)
			Else
				.cProviderName = ''
			Endif
		Endif
		Return .T.
	Endwith
	Endfunc
Enddefine
