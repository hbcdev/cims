LPARAMETERS l_cDataDir

ON ERROR errproc()

#DEFINE CR 	CHR(13)+CHR(10)
#DEFINE  LOGFILE	"C:\tablelog.txt"
STRTOFILE(CR+CR+TRANSFORM(DATETIME())+CR+CR,LOGFILE,1)
CLOSE DATABASES all
CLEAR
SET EXCLUSIVE OFF
SET DELETED OFF
l_cCurrDir = SYS(5) + SYS(2003)

IF !EMPTY(l_cDataDir)
	CD (l_cDataDir)
ELSE
	CD ?
ENDIF

ntables=ADIR(latables,'*.DBF')
l_nStartSeconds = SECONDS()

STRTOFILE("Data folder scanned - " + SYS(5) + SYS(2003) + CR + CR,LOGFILE,1)

FOR ii=1 TO ntables
	nstart=SECONDS()
	USE latables[ii,1] SHARED IN 1
	STRTOFILE(latables[ii,1]+": ",LOGFILE,1)
	ntag=ATAGINFO(latags)
	FOR xx=1 TO ntag
		lok=.T.
		SET ORDER TO (latags[xx,1]) ASCENDING
		WAIT WINDOW "Scanning tag - " + ;
					latags[xx,1] + ;
					" in " + ;
					latables[ii,1] NOWAIT NOCLEAR
					
		nreccount=RECCOUNT()
		nrecs=0
		SCAN  && do the fastest check first
			nrecs=nrecs+1
		ENDSCAN

		IF nrecs#nreccount AND EMPTY(latags[xx,4])
			STRTOFILE("Record count failed for tag "+ latags[xx,1]+ ;
						" in table "+latables[ii,1]+CR,LOGFILE,1)
			lok=.F.
			EXIT
		ENDIF
	ENDFOR
	IF lok
		FOR xx=1 TO ntag
			lok=.T.
			SET ORDER TO (latags[xx,1]) ASCENDING
			coldindexexp=NULL
			SCAN

				IF EVALUATE(latags[xx,3]) < coldindexexp
					STRTOFILE("ascending failed for tag "+ latags[xx,1]+;
						" in table "+latables[ii,1]+CR,LOGFILE,1)
					lok=.F.
					EXIT
				ENDIF
				coldindexexp=EVALUATE(latags[xx,3])
			ENDSCAN
		IF lok=.f.
			EXIT
		ENDIF
		ENDFOR
	ENDIF
	nend=SECONDS()
	tot=nend-nstart
	STRTOFILE([Total time for this table: ]+TRANSFORM(tot)+CR,LOGFILE,1)
ENDFOR
l_nEndSeconds = SECONDS()

=STRTOFILE(CR + CR + "Total Scan time - " + ;
			TRANSFORM(l_nEndSeconds - l_nStartSeconds) +;
			" seconds" + CR,LOGFILE,1)
			
CLOSE DATABASES all
WAIT CLEAR

CD (l_cCurrDir)

MODIFY FILE (LOGFILE)

FUNCTION errproc
#DEFINE CR 	CHR(13)+CHR(10)
=STRTOFILE(CR + "ERROR: "+MESSAGE() + CR,LOGFILE,1)
