CLOSE ALL 

lcDbFile = GETFILE("DBC", "Enter Database File", "Open",1, "Open Database")
lcTbFile = GETFILE("DBF", "Enter Provider Table ", "Open",1, "Open Provider Table")

IF EMPTY(lcDbFile) AND EMPTY(lcTbFile)
	RETURN 
ENDIF  	
*
OPEN DATABASE (lcDbFile)
**
llFound = .F.
*
USE provider  IN 0
SELECT provider
FOR i = 1 TO FCOUNT()
	IF "MID" = FIELD(i)
		llFound = .T.
	ENDIF 
ENDFOR 	
*
USE IN provider
*
IF !llFound
	ALTER TABLE cims!provider ADD mid C(16)
ENDIF 	
*
USE (lcTbFile) IN 0 ALIAS hospital
IF !USED("provider")
	USE provider IN 0
ENDIF 
*
SELECT hospital
SCAN 
	WAIT WINDOW TRANSFORM(RECNO(), "@Z 999") NOWAIT 
	IF SEEK(prov_id, "provider", "prov_id")
		REPLACE provider.mid WITH hospital.mid, ;
			provider.engname WITH hospital.engname, ;
			provider.class WITH hospital.class, ;
			provider.area WITH hospital.area, ;
			provider.addr_1 WITH hospital.addr_1, ;
			provider.province WITH hospital.province, ;
			provider.city WITH hospital.city, ;
			provider.postcode WITH hospital.postcode, ;
			provider.phone with hospital.phone			
	ENDIF 
ENDSCAN 
*			
*Update catcode to plan2cat

USE cims!category IN 0
USE cims!plan2cat IN 0 

SELECT plan2cat
SCAN 
	IF SEEK(cat_id, "category", "cat_id")
		REPLACE plan2cat.cat_code WITH category.cat_code
	ENDIF 
ENDSCAN 		
********************************
=MESSAGEBOX("Update Sucess")


