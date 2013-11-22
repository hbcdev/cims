USE policy2plan order pol_plan IN 0


DIMENSION plan[6,2], new_pol[11,1]

plan[1,1] = "BUI0310"
plan[2,1] = "BUI0311"
plan[3,1] = "BUI0312"
plan[4,1] = "BUI0313"
plan[5,1] = "BUI0314"
plan[6,1] = "BUI0315"
*
plan[1,2] = "A"
plan[2,2] = "1A"
plan[3,2] = "2A"
plan[4,2] = "3A"
plan[5,2] = "4A"
plan[6,2] = "5A"
*
new_pol[1,1] = "0503002-HI"
new_pol[2,1] = "0503003-HI"
new_pol[3,1] = "0503005-HI"
new_pol[4,1] = "0503006-HI"
new_pol[5,1] = "0503007-HI"
new_pol[6,1] = "0503008-HI"
new_pol[7,1] = "0503009-HI"
new_pol[8,1] = "0503010-HI"
new_pol[9,1] = "0503012-HI"
new_pol[10,1] = "0503013-HI"
new_pol[11,1] = "0503014-HI"
*
SELECT policy2plan

FOR i = 1 TO 11
	FOR j  = 1 TO 6
		lcPlan = "BUI"+new_pol[i,1]+REPLICATE(" ",30-LEN(new_pol[i,1]))+plan[j,2]
		IF !SEEK(lcPlan, "policy2plan", "pol_plan")
			?lcPlan
			INSERT INTO policy2plan (fundcode, policy_no, plan, plan_id, eff_date, exp_date) ;
			VALUES ("BUI", new_pol[i,1], plan[j,2], plan[j, 1], {^2005-03-01}, {^2006-03-01})
		ENDIF 	
	ENDFOR 
ENDFOR 		
		