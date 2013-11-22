* History of program:
* I have an application running at a factory where computers are used to control drilling and Welding machines etc.
* My part of the project was for the workstations at each machine to be able to pass timesheet data to the back office.
* Ocasionally the application would fail with corrupt data.
* The first time it happened I had to work fast to get the machines up and running and they were three quarters of the way
* through a shift so a quick and dirty program was written to restore the data.
* As soon as it became obvious that this was not an isolated incedent, I looked into why the corruption was happening.
* I found that sometimes a machine would fault and take down the supply to the adjacent computer so I suggested that UPS be bought for each machine
* This was rejected at the time because of the cost with the number of machines.
* One UPS was purchased but although it kept the workstation live the fault caused it to crash
* I decided to let the application check on startup for corrupted tables and if any failed cause the App on the other workstations to shut down
* The method I used was to place a timer in the startup program which checked a file every 5 minutes for its existance.
* The Workstation discovering the corruption would create a Zero Byte file and then keep checking for any workstation still running
* It checked this by looking at the Log On history file to see if anyone was still logged on.
* Once there where no more users logged on it ran a program to repair any corrup tables.  
* The program used follows the constants required for each table calculated mannually and then save as repairdocument.prg, repairreference.prg etc.
* It was my intention at the time to find a way of automatically calculation the constants from the header and field information. 
* But I never got round to it, any one wanting to have a go please help yourselves but please let me know the details.
* I have had cases at other sites where I have not been able to repair corrupted data as the records seem to have had
* corrupted data inserted or records which have lost part of there data causing the data to be offset at some point when browsing them.
* At the above site this problem has never been found and at least once a month the repairs have to be done and always work.
* If someone is in the middle of entering data when another workstation crashes the they loose the record they were trying to post and have to renter it.
* All workstations know a crash has occured so are aware of the need to check there last entry. (The apps not running any more)


LOCAL cFileToRepair,nHandle,lSafety,cHeader

IF SET("Safety") = "ON"

	lSafety = .T.
	SET SAFETY OFF
	
ENDIF

cFileToRepair = "C:\Pitstop\Accountsdata\2005\Referenc.dbf" && Name and location of the corrupt table

nHandle = FOPEN(cFileToRepair,2) && Open in raw mode

cHeader = FREAD(nHandle,392) && Collect and reject the first so many bytes which hold the header and field information

CD "C:\Pitstop\Accountsdata\2005"

CREATE TABLE oldReferenc.dbf ;
	(DocNo N(8) ,;
	Account C(12) ,;
	Ammount N(12,2))
	&& Create copy of the corrupt table

INDEX ON Account TAG Account
INDEX ON DocNo TAG DocNo
	
DO WHILE !FEOF(nHandle)

	cHeader = FGETS(nHandle,33) && Collect each record adding 1 byte for the deleted flag byte
	cDeleted = SUBSTR(cHeader,1,1) && The positions are know from the structure of the old table
	m.DocNo = VAL(SUBSTR(cHeader,2,8))
	m.Account = SUBSTR(cHeader,10,12)
	m.Ammount = VAL(SUBSTR(cHeader,22,12))

	INSERT INTO oldReferenc FROM MEMVAR
	
	IF cDeleted <> ' '
	
		DELETE
		
	ENDIF
	
ENDDO

FCLOSE(nHandle)

SELECT oldReferenc
USE

IF lSafety

	SET SAFETY ON
	
ENDIF

* The calling program then checks for corruption by examing the field data (In this case thge account field hold a - and a /
* I.e. "01-021/01" or "O1-024/" so its easy to check for thos two chars in every account field
* IF OK it erases the old dbf and cdx files and copies oldreferec.dbf to referenc.dbf etc.
