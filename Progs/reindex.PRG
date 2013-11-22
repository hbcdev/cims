lnTagCount = ATAGINFO(laTag)
PUBLIC lcIndexlist
lcIndexList = ""
FOR i = 1 TO TAGCOUNT()
	lcIndexFile = LEFT(DBF(),LEN(DBF())-4)+"_"+laTag[i,1]
	lcExp = laTag[i,3]
	lcTag = laTag[i,1]
	*INDEX ON &lcExp TO &lcIndexFile COMPACT ADDITIVE 
	lcIndexList = lcIndexList+lcIndexFile+".idx,"
ENDFOR
*lcIndexList = LEFT(lcIndexList,LEN(lcIndexList)-1)

 	