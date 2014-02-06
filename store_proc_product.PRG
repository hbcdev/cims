********************************************************
FUNCTION insertProduct()

lnSelect = SELECT()
llRetVal = .f.

scatter memo memvar
TEXT TO lcUpdate noshow 
	update [cimsdb].[dbo].[product] set [fund_id] = ?m.fund_id, [fundcode] = ?m.fundcode, [prod_id] = ?m.prod_id, [prod_type] = ?m.prod_type, [prod_cat] = ?m.prod_cat,
	[prod_title] = ?m.prod_title, [description] = ?m.description, [age_from] = ?m.age_from, [age_to] = ?m.age_to, [grace] = ?m.grace, [wait] = ?m.wait, [exclusion_wait] = ?m.exclusion_wait,
	[exclusion_cover] = ?m.exclusion_cover, [exclusion] = ?m.exclusion, [admis] = ?m.admis, [cover] = ?m.cover, [period] = ?m.period, [period_type] = ?m.period_type,
	[followup] = ?m.followup, [followup_type] = ?m.followup_type, [capitation] = ?m.capitation, [overall] = ?m.overall, [med_cover] = ?m.med_cover, [opd_cover] = ?m.opd_cover, 
	[ipd_cover] = ?m.ipd_cover,	[er_cover] = ?m.er_cover, [prov_used] = ?m.prov_used, [template] = ?m.template, [l_user] = ?m.l_user, [l_update] = ?m.l_update, 
	[hb_exclusion_wait] = ?m.hb_exclusion_wait, [period_per] = ?m.period_per, [followup_per] = ?m.followup_per, [wait_per] = ?m.wait_per, [exclusion_per] = ?m.exclusion_per,
	[chronic_wait] = ?m.chronic_wait, [chronic_per] = ?m.chronic_per, [exclcover_per] = ?m.exclcover_per where [fundcode] = ?m.fundcode and [prod_id] = ?m.prod_id
ENDTEXT 

TEXT TO lcInsert noshow 
	insert into [cimsdb].[dbo].[product] ([fund_id], [fundcode], [prod_id], [prod_type], [prod_cat], [prod_title], [description], [age_from],
	[age_to], [grace], [wait], [exclusion_wait], [exclusion_cover], [exclusion], [admis], [cover], [period], [period_type],
	[followup], [followup_type], [capitation], [overall], [med_cover], [opd_cover], [ipd_cover],	[er_cover], [prov_used],   
	[template],  [l_user], [l_update], [hb_exclusion_wait], [period_per], [followup_per], [wait_per], [exclusion_per],
	[chronic_wait], [chronic_per], [exclcover_per])
	values (?m.fund_id, ?m.fundcode, ?m.prod_id, ?m.prod_type, ?m.prod_cat, ?m.prod_title, ?m.description, ?m.age_from,
	?m.age_to, ?m.grace, ?m.wait, ?m.exclusion_wait, ?m.exclusion_cover, ?m.exclusion, ?m.admis, ?m.cover, ?m.period, ?m.period_type,
	?m.followup, ?m.followup_type, ?m.capitation, ?m.overall, ?m.med_cover, ?m.opd_cover, ?m.ipd_cover,	?m.er_cover, ?m.prov_used,   
	?m.template,  ?m.l_user, ?m.l_update, ?m.hb_exclusion_wait, ?m.period_per, ?m.followup_per, ?m.wait_per, ?m.exclusion_per,
	?m.chronic_wait, ?m.chronic_per, ?m.exclcover_per)		
ENDTEXT 

lnSql = SQLEXEC(gnConn, lcUpdate, "sqlresult", laSql)  
IF lnSql = 1
	IF laSql[2] > 0
		llRetval = .t.
	else
		lnSql = SQLEXEC(gnConn, lcInsert, "sqlresult", laSql)  	
		if lnSql = 1
			IF laSql[2] >= 0
				llRetval = .t.
			endif				
		else	
			=aerror(laError)	
			?"Insert Error:"+laError[2]
		endif	
	ENDIF 
else
	=aerror(laError)
	?"Update Error: "+laError[2]
ENDIF 		
IF USED("sqlresult")
	USE IN sqlresult
ENDIF 		

SELECT (lnSelect)
RETURN llRetVal
**********************************************
FUNCTION insertPlan()

lnSelect = SELECT()
llRetVal = .f.

SCATTER MEMO MEMVAR 
TEXT TO lcUpdate NOSHOW  
	update [cimsdb].[dbo].[plan] set [prod_id] = ?m.prod_id, [plan_id] = ?m.plan_id, [title] = ?m.title, [description] = ?m.description,
	[class] = ?m.class, [same_as] = ?m.same_as, [deductible] = ?m.deductible, [deductible_per] = ?m.deductible_per, [corepond] = ?m.corepond,
	[corepond_per] = ?m.corepond_per, [aggregate] = ?m.aggregate, [aggregate_oon] = ?m.aggregate_oon, [aggregate_per] = ?m.aggregate_per,
	[l_user] = ?m.l_user, [l_update] = ?m.l_update, [no_service] = ?m.no_service, [over_respond] = ?m.over_respond, [benefit_cover] = ?m.benefit_cover,
	[fxtype] = ?m.fxtype, [waiting] = ?m.waiting, [waiting_per] = ?m.waiting_per where [prod_id] = ?m.prod_id and [plan_id] = ?m.plan_id
ENDTEXT 	  
*
TEXT TO lcInsert NOSHOW  
	insert into [cimsdb].[dbo].[plan] ([prod_id], [plan_id], [title], [description], [class], [same_as], [deductible],
		[deductible_per], [corepond], [corepond_per], [aggregate], [aggregate_oon], [aggregate_per], [l_user], [l_update], 
		[no_service], [over_respond], [benefit_cover], [fxtype], [waiting], [waiting_per])
	values
		(?m.prod_id,?m.plan_id,?m.title,?m.description,?m.class,?m.same_as,?m.deductible,
		?m.deductible_per,?m.corepond,?m.corepond_per,?m.aggregate,?m.aggregate_oon,?m.aggregate_per,?m.l_user,?m.l_update,
		?m.no_service,?m.over_respond,?m.benefit_cover,?m.fxtype,?m.waiting,?m.waiting_per)
ENDTEXT 	  

lnSql = SQLEXEC(gnConn, lcUpdate, "sqlresult", laSql)  
IF lnSql = 1
	IF laSql[2] > 0
		llRetval = .t.
	else
		lnSql = SQLEXEC(gnConn, lcInsert, "sqlresult", laSql)  	
		if lnSql = 1
			IF laSql[2] >= 0
				llRetval = .t.
			else	
				=aerror(laError)					
			endif	
		else
			=aerror(laError)
			?laError[2]
		endif	
	ENDIF 
else
	=aerror(laError)
	?laError[2]	
ENDIF 		
IF USED("sqlresult")
	USE IN sqlresult
ENDIF 	  
SELECT (lnSelect)
RETURN llRetval
**********************************************
FUNCTION insertPlan2Cat()

lnSelect = SELECT()
llRetVal = .f.

SCATTER MEMO MEMVAR 

TEXT TO lcInsert NOSHOW
	insert into [cimsdb].[dbo].[plan2cat] ([plan_id],[cat_id],[description],[group],[subgroup],[subtype],[ismaingrp],
	   [issubmain],[benefit],[benefit2],[per],[benefit3],[aggregate],[condition],[l_user],[l_update],[cat_code])
	values
	(?m.plan_id, ?m.cat_id, ?m.description, ?m.group, ?m.subgroup, ?m.subtype, ?m.ismaingrp, ?m.issubmain,
	   ?m.benefit, ?m.benefit2, ?m.per, ?m.benefit3, ?m.aggregate, ?m.condition, ?m.l_user, ?m.l_update, ?m.cat_code)
ENDTEXT 	  

TEXT TO lcUpdate NOSHOW
	update [cimsdb].[dbo].[plan2cat] set [plan_id] = ?m.plan_id, [cat_id] = ?m.cat_id, [description] = ?m.description, [group] = ?m.group,	
		[subgroup] = ?m.subgroup, [subtype] = ?m.subtype, [ismaingrp] = ?m.ismaingrp, [issubmain] = ?m.issubmain, [benefit] = ?m.benefit, 
	    [benefit2] = ?m.benefit2, [per] = ?m.per, [benefit3] = ?m.benefit3, [aggregate] = ?m.aggregate, [condition] = ?m.condition, 
	    [l_user] = ?m.l_user, [l_update] = ?m.l_update, [cat_code] = ?m.cat_code where [plan_id] = ?m.plan_id and [cat_id] = ?m.cat_id
ENDTEXT 	  
lnSql = SQLEXEC(gnConn, lcUpdate, "sqlresult", laSql)  
IF lnSql = 1
	IF laSql[2] > 0
		llRetval = .t.
	else
		lnSql = SQLEXEC(gnConn, lcInsert, "sqlresult", laSql) 
		if lnSql = 1 	
			IF laSql[2] >= 0
				llRetval = .t.
			else	
				=aerror(laError)	
			endif	
		else
			=aerror(laError)
			?laError[2]						
		endif 	
	ENDIF 
else
	=aerror(laError)		
	?laError[2]							
ENDIF 		
IF USED("sqlresult")
	USE IN sqlresult
ENDIF 	  
SELECT (lnSelect)
RETURN llRetval
**********************************************
FUNCTION insertProdExclusion()

lnSelect = SELECT()
llRetVal = .f.

SCATTER MEMO MEMVAR 

TEXT TO lcUpdate NOSHOW
	update [cimsdb].[dbo].[product_exclusion] set [prod_id] = ?m.prod_id, [excltype] = ?m.excltype, [exclno] = ?m.exclno, [icd10] = ?m.icd10,
		[detail] = ?m.detail, [detailthai] = ?m.detailthai, [l_user] = ?m.l_user, [l_update] = ?m.l_update where [prod_id] = ?m.prod_id and [exclno] = ?m.exclno	
ENDTEXT 	  

TEXT TO lcInsert NOSHOW
	insert into [cimsdb].[dbo].[product_exclusion] ([prod_id],[excltype],[exclno],[icd10],[detail],[detailthai],[l_user],[l_update])
	values (?m.prod_id,?m.excltype,?m.exclno,?m.icd10,?m.detail,?m.detailthai,?m.l_user,?m.l_update)
ENDTEXT 	  

lnSql = SQLEXEC(gnConn, lcUpdate, "sqlresult", laSql)  
IF lnSql = 1
	IF laSql[2] > 0
		llRetval = .t.
	else
		lnSql = SQLEXEC(gnConn, lcInsert, "sqlresult", laSql)  	
		IF laSql[2] >= 0
			llRetval = .t.
		else	
			=aerror(laError)	
		endif	
	ENDIF 
ENDIF 		
IF USED("sqlresult")
	USE IN sqlresult
ENDIF 	  
SELECT (lnSelect)
RETURN llRetval
**********************************************
function saveProduct(tcFundCode, tcProdId)

if empty(tcFundCode) and empty(tcPlanId)
	return .f.
endif	

llRetVal = .T.
lnSelect = select()

select * from cims!product where fundcode = tcFundCode and prod_id = tcProdId into cursor _product
if _TALLY > 0
	select _product
	if insertProduct()
		lcProdId = _product.fundcode + _product.prod_id
		select * from cims!plan where prod_id = lcProdId into cursor _plan
		if _TALLY  > 0
			select _plan
			scan 
				if insertPlan()
					lcPlanId = _plan.plan_id
					select * from cims!plan2cat where plan_id = lcPlanId into cursor _plan2cat
					if _TALLY  > 0
						select _plan2cat
						scan 
							if insertPlan2Cat()
								llRetVal = .T.
							endif 
						endscan
					endif 
					use in _plan2cat		
				endif 
			endscan
		endif 
		use in _plan
	endif
endif 
use in _product
		
select (lnSelect)
return llRetVal			
**********************************************
function savePlan(tcPlanId)

if empty(tcPlanId)
	return .f.
endif	

llRetVal = .T.
lnSelect = select()

select * from cims!plan where plan_id = tcPlanId into cursor _plan
if _TALLY  > 0
	lnRecNo = 0
	select _plan
	scan 
		if insertPlan()
			lnRecNo = lnRecNo + 1
		endif 
	endscan
	llRetVal = lnRecNo > 0 
	if llRetVal
		select * from cims!plan2cat where plan_id = tcPlanId into cursor _plan2cat
		if _TALLY  > 0
			lnRecNo = 0
			select _plan2cat
			scan 
				if insertPlan2Cat()
					lnRecNo = lnRecNo + 1
				endif 
			endscan
			llRetVal = lnRecNo > 0 
		endif 
		use in _plan2cat		
	endif 	
endif 
use in _plan
select (lnSelect)
return llRetVal			
**********************************************
function saveProdExclusion(tcProdId)

if empty(tcProdId)
	return .f.
endif	

llRetVal = .T.
lnSelect = select()
select * from cims!product_exclusion where plan_id = tcPlanId into cursor _prodexclusion
if _TALLY  > 0
	lnRecNo = 0
	select _prodexclusion
	scan 
		if insertprodexclusion()
			lnRecNo = lnRecNo + 1
		endif 
	endscan
	llRetVal = lnRecNo > 0 
endif 
use in _prodexclusion
select (lnSelect)
return llRetVal			
