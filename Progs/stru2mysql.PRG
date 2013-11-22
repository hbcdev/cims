#DEFINE		CR 		CHR(13)
#DEFINE		TABB 		CHR(9)

LPARAMETERS tcAlias
LOCAL lcOut, lnF, lcField, lcType, lnLen, lnDec, ln8Len, lcFile, lnCnt, aa[1]

IF NOT EMPTY(tcAlias)
	SELECT (tcAlias)
ENDIF

lcOut = ""

lnF = AFIELDS(aa)
FOR lnCnt = 1 TO lnF
	lcField = LOWER(aa[lnCnt, 1])
	lcType = aa[lnCnt, 2]
	lnLen = aa[lnCnt, 3]
	lnDec = aa[lnCnt, 4]

	ln8Len = next8(lnLen)

	lcOut = lcOut + TABB
	DO CASE
		CASE lcType == "C"
			lcOut = lcOut + lcField + [ varchar (] + TRANSFORM(ln8Len) + [) not null default '', ]
			
		CASE lcType == "I"
			DO CASE
				CASE lnLen < 4
					lcOut = lcOut + lcField + [ tinyint unsigned not null default 0, ]
				CASE lnLen < 8
					lcOut = lcOut + lcField + [ int unsigned not null default 0, ]
				OTHERWISE
					lcOut = lcOut + lcField + [ mediumint unsigned not null default 0, ]
			ENDCASE

		CASE INLIST(lcType, "N", "Y")
			IF lnDec = 0
				DO CASE
					CASE lnLen < 4
						lcOut = lcOut + lcField + [ tinyint unsigned not null default 0, ]
					CASE lnLen < 8
						lcOut = lcOut + lcField + [ int unsigned not null default 0, ]
					OTHERWISE
						lcOut = lcOut + lcField + [ mediumint unsigned not null default 0, ]
				ENDCASE
			ELSE
				lcOut = lcOut + lcField + [ decimal (] + TRANSFORM(ln8Len) + [, ] + TRANSFORM(lnDec) + [) not null default 0, ]
			ENDIF

		CASE lcType == "T"
			lcOut = lcOut + lcField + [ datetime not null, ]

		CASE lcType == "D"
			lcOut = lcOut + lcField + [ date not null, ]

		CASE lcType == "M"
			lcOut = lcOut + lcField + [ text not null default '', ]

		CASE lcType == "L"
			lcOut = lcOut + lcField + [ tinyint unsigned not null default '0', ]
	ENDCASE

	IF lnCnt = lnF
		* Last entry; strip the comma
		lcOut = SUBSTR(lcOut, 1, LEN(lcOut)-2)
	ELSE
		lcOut = lcOut + CR
	ENDIF
ENDFOR


lcFile = [make] + LOWER(ALIAS()) + [.sql]
STRTOFILE([create table ] + LOWER(ALIAS()) + [ (] + CR + lcOut + CR + [)], lcFile)

MODIFY FILE (lcFile) NOWAIT


RETURN


FUNCTION next8(tnVal)
	LOCAL lnExtra
	lnExtra = tnVal % 8
	IF lnExtra > 0
		lnExtra = 8 - lnExtra
	ENDIF

	RETURN tnVal + lnExtra
ENDFUNC
