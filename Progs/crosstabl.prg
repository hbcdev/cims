**************************************************
*-- Class:        crosstabl (c:\app\libs\top.vcx)
*-- ParentClass:  custom
*-- BaseClass:    custom
*-- Time Stamp:   03/22/99 10:03:11 PM

*-- Cross-table with multi-column.                   
* 
*
* This class is developed for use instead of VFPXTAB when the source table :
* - is very large 
* - contents unsorted data
* - or you want to process a few of data-columns at once.

*!*	Usage :
*!*	oXTab = createobject('crosstabl')
*!*	oXTab.runXTab([cSourceTable] , [cDestTable],;
*!*	[xRowField], [xColField],;
*!*	[ xValField | cListOfValFields, [cListOfColumnsNames]],;
*!*	[nMaxSizeOfColumName],  [cListOfColumnFunctions])

*!*	cSourceTable - a alias to process .			
*!*		Default: current alias
*!*				
*!*	cDestTable - a name of cross-table.			
*!*		Default: newtbl
*!*		
*!*	xRowField  - Number or name of row's field
*!*		Default:    1

*!*	xColField - Number or name of col's field
*!*		Default:    2
*!*		
*!*	xValField 
*!*		a. "single" Number or name of value's field
*!*			Default:    3
*!*		
*!*		b. "multi" List of column's names with data delimited with semi-colon (;)
*!*		
*!*	cListOfColumnsNames - optional

*!*	nMaxSizeOfColumName - optional
*!*		Description: you may change this parameter
*!*		if you want to use more then 10 symbols in column's name -
*!*		cursor will be created istead of table
*!*		
*!*	cListOfColumnFunctions - optional
*!*		Default: "1" for every column
*!*		1 - sum
*!*		2 - count
*!*		3 - min
*!*		4 - max
*!*		5 - avg
*!*	 	delimeted with semi-colon (;)

*!*	Example: 
*!*	thisform.ct.runXTab('tmpserv',,'vzip','serv','sum;sum;taxsum',"cnt",20,"2")

*!*	cursor 'NewTbl' will be created, where 
*!*	- field [Zip of custom] used as row,
*!*	- field [Service code] - as column's name
*!*	- group of columns for each [Service code]
*!*		cnt_(###)    - count of serv
*!*		sum_(###)    - sum of sum
*!*		taxsum_(###) - sum of taxes
*!*		
*!*	thisform.ct.runXTab('tmpserv',,'vzip','serv','sum;sum;sum;sum',"cnt;sum;max;avg",20,"2;1;4;5")


DEFINE CLASS crosstabl AS custom


	Height = 18
	Width = 23
	*-- Specifies the alias used for each table or view associated with a Cursor object.
	PROTECTED als
	als = ""
	*-- tmp-string
	PROTECTED cstr
	cstr = ""
	*-- Name of cross-table
	PROTECTED newtbl
	newtbl = "newTbl"
	PROTECTED nlasterror
	nlasterror = 0
	*-- Pseudo name for columns
	PROTECTED colname
	colname = "N"
	*-- Field's number of column-field in this.als
	PROTECTED ncol
	ncol = 2
	*-- Columns.Defauult : 1
	PROTECTED ncolumns
	ncolumns = 1
	PROTECTED badchars
	badchars = ""
	*-- if > 10, then Create cursor. Default - table
	PROTECTED colnamelen
	colnamelen = 10
	PROTECTED ngrpname
	ngrpname = 0
	*-- Multi-column's SELECT
	PROTECTED cselectsql
	cselectsql = ""
	*-- functions, that used in SELECT SQL
	PROTECTED calcfunc
	calcfunc = "sum;cnt;min;max;avg"
	Name = "crosstabl"

	*-- Field's number of row-field in this.als
	PROTECTED nrow

	*-- Sum-field's number for simple x-table
	PROTECTED nxsum

	*-- Name of row's field
	PROTECTED rowfield

	*-- Name of column's field
	PROTECTED colfield
	PROTECTED sumfield
	PROTECTED rowtype
	PROTECTED rowlen
	PROTECTED rowprec

	*-- Precision for column's sum
	PROTECTED colprec

	*-- Sign to create x-table with multi-columns
	PROTECTED multifld

	*-- temp value - how many psitions is used for group's number
	PROTECTED n4grp

	*-- is there any User-deifned Column's names ?
	PROTECTED lusrdefnames
	PROTECTED avals[1,1]


	*-- Create temporaty columns' cursors and structure for cross-table
	PROTECTED PROCEDURE createfish
		LOCAL cAls, cColField, cFieldSum, cRowField
		cAls = this.als
		cColField = THIS.Colfield
		cRowField = this.Rowfield

		cFieldSum =  field(this.nxSum, this.als)

		IF vartype(eval(cAls+'.'+cFieldSum)) <> 'N'
			this.nLastError = -1
			RETURN
		ENDIF

		* for large tables
		select distinct &cColField as col from (cAls) into cursor csPreCol

		SELECT distinct col ,;
			this.colname + padr(strtran(reduce(lower(transform(col)),this.badChars)," ","_"),8) as RealCol ;
			from csPrecol into table csCol

		INDEX on col tag col
		INDEX on RealCol tag RealCol unique
		SET order to RealCol

		this.cStr = "Create table " + this.newTbl + " FREE (" + ;
			cRowField + " " + this.Rowtype + "(" + ltrim(str(this.rowLen)) + ;
			iif(this.rowPrec > 0, "," + ltrim(str(this.rowPrec)), "") + ")"

		SELECT csCol
		GO TOP
		cColField = ", " &&+ this.Colname

		LOCAL cTyp
		IF this.colPrec <> 0
			cTyp = " b(" + ltrim(str(this.colPrec)) + ")"
		ELSE
			cTyp = " i"
		ENDIF

		SCAN next int(253/this.nColumns)
			this.cStr = this.cStr + cColField + RealCol + cTyp
		ENDSCAN

		this.cStr = this.cStr + ")"
		SELECT 0
		LOCAL cCreateTbl
		cCreateTbl = this.cStr
		&cCreateTbl
		LOCAL cIdx
		cIdx = cRowField
		INDEX on &cIdx tag row
	ENDPROC


	*-- Calculate a table
	PROTECTED PROCEDURE process
		LOCAL cRowFld,cColFld, cSumFld, cColName

		cRowFld = this.Rowfield
		cColFld = this.ColField
		cSumFld = this.Sumfield

		SELECT &cRowFld as row,;
			b.realcol as Col,;
			sum(&cSumFld) as val ;
			from (this.als) join csCol b on &cColFld = b.col group by 1,2 into cursor csProcess

		SET relation to row into (this.newtbl) &&, col into csCol
		cRowFld = this.newtbl + '.' + cRowFld

		LOCAL cTalk
		cTalk = set('talk')
		SET talk off

		SCAN
			cColName  = this.newtbl+'.' + col &&field(recno('csCol')+1, this.newtbl)

			IF eof(this.newtbl)
				APPEND blank in this.newtbl
				REPLACE &cRowFld with csProcess.row,;
				 &cColName with csProcess.val
			ELSE
				REPLACE &cColName with eval(cColName)+csProcess.val
			ENDIF
		ENDSCAN

		SET talk &cTalk
		SELECT (this.newtbl)
	ENDPROC


	*-- Make cross-table
	PROTECTED PROCEDURE go
		this.createfish()

		IF This.nLastError == 0
			this.process()
		ENDIF
	ENDPROC


	*-- Setting of properties
	PROTECTED PROCEDURE preprocess
		LPARAM cAls, cNewTbl, lxRow, lxCol, lxSum, lcSumName, lnNameLen, lxDoWhat
		LOCAL array aF(1)
		LOCAL lnF, lcF

		this.ColNameLen = iif(empty(lnNameLen), ;
		this.ColNameLen, lnNameLen)

		this.Als     = iif(empty(cAls) , alias(), cAls)
		this.NewTbl  = iif(empty(cNewTbl) , this.NewTbl, cNewTbl)
		=afields(aF, this.Als)

		IF !inlist(vartype(lxRow), 'N', 'C')
			lxRow	 = 1
		ENDIF

		this.preField(lxRow, @lnF, @lcF, @aF)
		this.nRow	  = lnF
		this.RowField = lcF
		this.rowType  = aF[this.nRow, 2]
		this.rowLen   = aF[this.nRow, 3]
		this.rowPrec  = aF[this.nRow, 4]

		IF !inlist(vartype(lxCol), 'N', 'C')
			lxCol	 = 2
		ENDIF

		this.preField(lxCol, @lnF, @lcF, @aF)
		this.nCol	  = lnF
		this.ColField = lcF

		IF !inlist(vartype(lxSum), 'N', 'C')
			lxSum	 = 3
		ENDIF

		IF vartype(lxSum) == 'C'
			this.nColumns = words(lxSum, ";")
		ENDIF

		this.multiFld = this.nColumns > 1

		IF this.multiFld
			this.multiCols(lxSum, @aF, lcSumName, lxDoWhat)
		ELSE
			this.preField(lxSum, @lnF, @lcF, @aF)
			this.nxSum	  = lnF
			this.SumField = lcF
			this.colPrec  = aF[this.nxSum, 4]
		ENDIF

		this.Colname = iif(this.lUsrDefNames, "", aF[this.nCol,2]+"_")

		RETURN this.nLastError
	ENDPROC


	*-- a method for setting of row-,column-, sum- properties
	PROTECTED PROCEDURE prefield
		LPARAM lxFld, lnField, lcField, aF

		IF vartype(lxFld) == 'N'
			lnField	  = lxFld
			lcField = field(lnField, this.als)
		ELSE
			lcField = upper(lxFld)
			lnField = ceiling(ascan(aF, lcField)/alen(aF, 2))
		ENDIF
	ENDPROC


	PROCEDURE runxtab
		lparam cAls, cNewTbl, lxRow, lxCol, lxSum, lxSumName, lnColLen, lxDoWhat
		local lRet
		=mysusp()

		if vartype(lxSumname) == 'L' and !empty(lxSumname)
			lxSumname = lxSum
		endif

		this.preProcess(cAls, cNewTbl, lxRow, lxCol, lxSum, lxSumName, lnColLen, lxDoWhat) 

		if this.nLastError == 0
			if this.MultiFld
				this.goMulti()
			else
				this.go()
			endif
		endif

		lRet = this.nLastError == 0
		this.nLastError = 0

		if lRet
			this.closeTmp()
		endif

		return lRet
	ENDPROC


	*-- Make multi-columns cross-table
	PROTECTED PROCEDURE gomulti
		this.createMulti()

		IF This.nLastError == 0
			this.processMulti()
		ENDIF
	ENDPROC


	*-- get "SQL create table" and "SELECT SQL" - for demo
	PROCEDURE getcreatesql
		lparam lWhat

		return iif( lWhat, this.cSelectSQL, this.cStr)
	ENDPROC


	*-- Create array of multiple columns properties
	PROTECTED PROCEDURE multicols
		LPARAM lxFld, aF, lcSumName, lcFunc
		LOCAL i, lcField, lnField, lnCols
		lxFld = upper(lxFld)

		this.lUsrDefNames = vartype(lcSumName) == 'C'
		lcFunc = iif(empty(lcFunc), "", lcFunc)

		if this.lUsrDefNames
			lcSumName = upper(lcSumname)
		else
			lcSumName = upper(lxFld)
		endif

		FOR i = 1 to words(lxFld, ';')
			IF this.nLastError == 0
				lcField = wordnum(lxFld, i, ';')
				lnField = ceiling(ascan(aF, lcField)/alen(aF, 2))

				IF lnField > 0
					DIMEN this.avals(i, 4)
					this.avals[i, 1] = lcField
					this.avals[i, 2] = iif(aF[lnField, 4] <> 0,;
						" b(" + ltrim(str(aF[lnField, 4])) + ")", " i")

					lcField = wordnum(lcSumName, i, ';')
						this.avals[i,3] = iif(empty(lcField), this.avals[i,1], lcField)
						this.nGrpName = max(this.nGrpName,;
					 len(this.aVals(i,iif(empty(lcField), 2,3))))
					 
					lcField	= wordNum(lcFunc, i, ';')

					if isdigit(lcField)
						lcField = wordnum(this.CalcFunc, val(lcField), ';')

						if empty(lcField)
							this.avals(i, 4) = 'sum'
						else
							this.avals(i, 4) = lcField
						endif
					else
						this.avals(i, 4) = 'sum'
					endif
				ENDIF
			ENDIF
		NEXT


		this.nColumns = alen(this.avals, 1)

		if this.lUsrDefNames
			this.changeSameCols(3)
		endif
	ENDPROC


	*-- Calculate a multi-table
	PROTECTED PROCEDURE processmulti
		LOCAL i, cSelectSQL

		cSelectSQL = "SELECT " + this.Rowfield + " as row," + ;
			"b.realcol as Col"

		FOR i = 1 to this.nColumns
			cSelectSQL = cSelectSQL + ", " + ;
			this.aVals[i,4] +"(" + this.aVals[i,1] + ") as " + ;
				this.aVals[i,1]
		NEXT

		cSelectSQL = cSelectSQL + ;
			" from " + this.als + " a join csCol b on a." + ;
			this.colField + " = b.col group by 1,2 into cursor csProcess"

		this.cSelectSQL = cSelectSQL
		&cSelectSQL

		this.changeSameCols(1)

		SET relation to row into (this.newtbl)

		LOCAL cTalk
		cTalk = set('talk')
		SET talk off

		LOCAL cRowFld, cColName, cValue

		cRowFld = this.newtbl + '.' + this.Rowfield

		FOR i = 1 to this.nColumns
			cValue  = "csProcess."+this.aVals[i,1]

			SCAN
				cColName  = this.newtbl+'.' + iif(this.lUsrDefNames,;
					this.aVals[i,3] + '_' + rtrim(left(col, this.n4Grp)),;
					rtrim(left(col, this.n4Grp)) + ltrim(str(i)))

				IF eof(this.newtbl)
					APPEND blank in this.newtbl
					REPLACE &cRowFld with csProcess.row,;
						&cColName with eval(cValue)

				ELSE
					REPLACE &cColName with eval(cColName)+eval(cValue)
				ENDIF
			ENDSCAN

		NEXT

		SET talk &cTalk
		SELECT (this.newtbl)
	ENDPROC


	*-- Create temporaty columns' cursors and structure for multi-cross-table
	PROTECTED PROCEDURE createmulti
		LOCAL cAls, cColField, cRowField, lnPadLen
		cAls = this.als
		cColField = THIS.Colfield
		cRowField = this.Rowfield

		* for large tables
		select distinct &cColField as col from (cAls) into cursor csPreCol

		IF this.lUsrDefNames
			lnPadLen = this.ColNameLen - 2 && Type_

			SELECT distinct col ,;
				this.colname + padr(strtran(reduce(lower(transform(col)),this.badChars)," ","_"),lnPadLen) as RealCol ;
				from csPreCol into table csCol
		ELSE
			lnPadLen = this.ColNameLen - this.nGrpname && Free Name

			SELECT distinct &cColField as col ,;
				padr(strtran(reduce(lower(transform(&cColField)),this.badChars)," ","_"), lnPadLen) as RealCol ;
				from csPreCol into cursor csCol
		ENDIF

		INDEX on col tag col
		INDEX on RealCol tag RealCol unique
		SET order to RealCol

		IF this.ColNameLen > 10
			* Have to do CURSOR, Free table's field name <= 10 char
			this.cStr = "Create cursor " + this.newTbl + " ("
		ELSE

			this.cStr = "Create table " + this.newTbl + " FREE ("
		ENDIF

		this.cStr = this.cStr + ;
			cRowField + " " + this.Rowtype + "(" + ltrim(str(this.rowLen)) + ;
			iif(this.rowPrec > 0, "," + ltrim(str(this.rowPrec)), "") + ")"

		SELECT csCol
		GO TOP
		cColField = ", " &&+ this.Colname

		LOCAL i

		this.n4Grp = fsize('RealCol') - iif(this.lUsrDefNames,;
			 this.nGrpname + 1,;
			 ceiling(this.nColumns/10))

		SCAN next int(253/this.nColumns)
			FOR i = 1 to this.nColumns
				IF this.lUsrDefNames
					this.cStr = this.cStr + cColfield + ;
						this.aVals[i,3] + '_' + rtrim(left(RealCol, this.n4Grp)) + this.aVals[i,2]
				ELSE
					this.cStr = this.cStr + ;
						cColField + rtrim(left(RealCol, this.n4Grp)) + ltrim(str(i)) + this.aVals[i,2]
				ENDIF
			NEXT
		ENDSCAN

		this.cStr = this.cStr + ")"
		SELECT 0
		LOCAL cCreateTbl
		cCreateTbl = this.cStr
		&cCreateTbl
		LOCAL cIdx
		cIdx = cRowField
		INDEX on &cIdx tag row
	ENDPROC


	*-- Columns with the same names will be changed as well as in select SQL
	PROTECTED PROCEDURE changesamecols
		lparam lnCol

		if empty(lnCol)
			lnCol = 1
		endif

		if !this.lUsrDefNames and lnCols == 3
			return
		endif

		local cChkStr, i, lnCnt, j, cSrch
		cChkStr = ""

		for i = 1 to this.nColumns
			cChkStr = cChkStr + "#" + this.aVals[i, lnCol]
		next 

		for i = 1 to this.nColumns
			cSrch = this.aVals[i, lnCol]

			if occurs("#" + cSrch, cChkStr) > 1
				lnCnt = 1

				this.aVals[i, lnCol] = cSrch + '_A'

				for j = i + 1 to this.nColumns
					if this.aVals[j, lnCol] == cSrch
						this.aVals[j, lnCol] = cSrch + '_' + chr(65+lnCnt)
						lnCnt = lnCnt + 1
					endif
				next
			endif
		next
	ENDPROC


	*-- Close temporary tables
	PROTECTED PROCEDURE closetmp
		use in csPreCol
		use in csCol
		use in csProcess
	ENDPROC


	PROCEDURE Error
		LPARAMETERS nError, cMethod, nLine
		this.nLastError = nError
		if messagebox(str(nError)+chr(13)+cMethod+chr(13)+str(nLine)+chr(13)+message(), 5) == 2
			CANCEL
		endif

		return .f.
	ENDPROC


	PROCEDURE Init
		this.badChars = ;
		'/,-=:;!@#$%&*.<>()?[]\'+;
		'+'+CHR(34)+CHR(39)

		&&this.preProcess(cAls, cNewTbl, lnRow, lnCol, lxSum)

		return this.nLastError
	ENDPROC


ENDDEFINE
*
*-- EndDefine: crosstabl
**************************************************
