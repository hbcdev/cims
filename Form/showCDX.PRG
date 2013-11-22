FOR nCount = 1 TO 254
   IF !EMPTY(TAG(nCount))  && Checks for tags in the index
	   lcKey = "INDEX ON "+KEY(nCount)+" TAG "+ TAG(nCount)
  	=STRTOFILE(lcKey, "claim_key.txt") 	
   ELSE
      EXIT  && Exit the loop when no more tags are found
   ENDIF
ENDFOR