CLOSE ALL 
lcSourceFile = GETFILE("TXT")
IF EMPTY(lcSourceFile)
	RETURN 
ENDIF 
lcDbf = STRTRAN(lcSourceFile, ".TXT", ".DBF")
*************************************
*
CREATE CURSOR curEstimate (datafile C(1), mainclass C(1), agentno N(7,0), agentbranch C(3), typeclaim C(1), claimtype C(3), time I, notify_no C(15), notifydate D, ;
	claimno C(25), policyno C(30), cardno C(25), occurdate D, occurtime C(8), paidtype C(250), paidamt N(13,2), paidother N(13,2), hospcode C(25), hospname C(200), custid C(20), title C(30), ;
	name C(50), surname C(100), address C(250), district C(100), province C(100), postcode C(5), accaddr C(250), coverdesc C(200), cewdesc C(200), indication C(250), ;
	treatment C(250), paidtime I, illcode C(25), illname C(100), paidtypecode C(20), paidname C(160), paiddes C(60), paidtypeacc C(250), remark C(250), polcover C(1), result C(250), l_update D)
*
?lcSourceFile
lcDate = SUBSTR(JUSTFNAME(lcSourceFile),12,8)
ldDate = CTOD(SUBSTR(lcDate, 7,2)+"/"+SUBSTR(lcDate,5,2)+"/"+LEFT(lcDate, 4))
lnLines = ALINES(laTextArray,FILETOSTR(lcSourceFile))
lnFieldCounts = FCOUNT()-1
FOR i = 2 TO lnLines
	WAIT WINDOW TRANSFORM(i-1, "@Z 99,999") NOWAIT 
	SCATTER TO laData BLANK 
	lcTemp = laTextArray[i]
	FOR j = 1 TO lnFieldCounts
		laData[j] = STRTRAN(IIF(AT("|",lcTemp) = 0, lcTemp, LEFT(lcTemp,AT("|",lcTemp)-1)),'"','')
		laData[j] = STRTRAN(laData[j], '"','')	
		DO CASE 
		CASE j = 8
			laData[j] = SUBSTR(laData[j],5,15)
		CASE INLIST(j, 9, 13)
			laData[j] = IIF(ISNULL(laData[j]), {}, CTOD(laData[j]))
		CASE INLIST(j ,7, 16,17,33)
			laData[j] = VAL(laData[j])			
		ENDCASE  	
		*
		IF AT("|",lcTemp) # 0
			lcTemp = SUBSTR(lcTemp,AT("|",lcTemp)+1)
		ENDIF 	
	ENDFOR 
	laData[43] = ldDate
	INSERT INTO curEstimate FROM ARRAY laData
ENDFOR 
*		
BROWSE 

IF MESSAGEBOX("ต้องการอัพเดทเข้าระบบเคลม หรือไม่",4+256+32,"Update to Claim") = 7
	RETURN 
ENDIF 

llNotFound = .F.
SELECT curEstimate
GO TOP 
SCAN 
	SCATTER MEMVAR 
	WAIT WINDOW m.notify_no NOWAIT 
	UPDATE cims!claim SET ;
		claim.claim_no = m.claimno ;
	WHERE claim.notify_no = m.notify_no
	IF _TALLY = 0
		llNotFound = .T.	
		DELETE 
	ENDIF 	
ENDSCAN 
IF llNotFound
	BROWSE FOR DELETED()
	COPY TO (ADDBS(JUSTPATH(lcSourceFile))+"Error_"+STRTRAN(JUSTFNAME(lcSourceFile), "TXT", "XLS")) TYPE XL5 
ENDIF 				
			