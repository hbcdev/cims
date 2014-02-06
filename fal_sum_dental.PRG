use d:\report\fal\fal_clmipd_reimb_01112013_30112013.dbf alias fal
select fal
=afields(laField)
lcdbf = strtran(dbf(), "IPD","DEN")
create table (lcDbf) from array laField

select pol_no, cust_id, admit from fal where bro_no = "D" group by pol_no, cust_id, admit into cursor _grp
if _TALLY = 0
	return 
endif 

select _grp
go top 
do while !eof()
	scatter memvar 
	do sumAll	
	select _grp
	skip
enddo 			
*************************		
procedure sumAll

lnSelect = select()

select * ;
from fal ;
where pol_no = m.pol_no and cust_id = m.cust_id and admit = m.admit ;
into cursor _fal

select _fal
scatter memvar memo 
store "" to m.icd_10, m.indication, m.treatment, m.remark
store 0 to m.hosp_amt, m.discount, m.non_cover, m.benf_paid, m.exgratia, ;
	m.a_sf, m.d_sf, m.o_sf, m.p_sf, m.e_sf, m.c_sf, m.n_sf, ;
	m.a_et, m.d_et, m.o_et, m.p_et, m.e_et, m.c_et, m.n_et, ;
	m.a_acc, m.d_acc, m.o_acc, m.p_acc, m.e_acc, m.c_acc, m.n_acc, ;
	m.a_wr, m.d_wr, m.o_wr, m.p_wr, m.e_wr, m.c_wr, m.n_wr, ;
	m.a_rc, m.d_rc, m.o_rc, m.p_rc, m.e_rc, m.c_rc, m.n_rc, ;
	m.a_sl, m.d_sl, m.o_sl, m.p_sl, m.e_sl, m.c_sl, m.n_sl
scan 
	m.hosp_amt = m.hosp_amt + _fal.hosp_amt
	m.discount = m.discount + _fal.discount
	m.non_cover = m.non_cover + _fal.non_cover
	m.benf_paid = m.benf_paid + _fal.benf_paid
	m.exgratia = m.exgratia + _fal.exgratia
	m.icd_10 = alltrim(m.icd_10) + "," + alltrim(_fal.icd_10)
	m.indication = alltrim(m.indication) + alltrim(_fal.Indication) + "("+_fal.Not_no+")"
	m.treatment = alltrim(m.treatment) +  alltrim(_fal.Treatment) + "("+_fal.Not_no+")"
	m.remark = alltrim(m.remark) + alltrim(_fal.Remark) + "("+_fal.Not_no+")"

	m.a_sf = m.a_sf + _fal.a_sf
	m.d_sf = m.d_sf + _fal.d_sf
	m.o_sf = m.o_sf + _fal.o_sf
	m.p_sf = m.p_sf + _fal.p_sf
	m.e_sf = m.e_sf + _fal.e_sf
	m.c_sf = m.c_sf + _fal.c_sf
	m.n_sf = m.n_sf + _fal.n_sf
			
	m.a_et = m.a_et + _fal.a_et
	m.d_et = m.d_et + _fal.d_et
	m.o_et = m.o_et + _fal.o_et
	m.p_et = m.p_et + _fal.p_et
	m.e_et = m.e_et + _fal.e_et
	m.c_et = m.c_et + _fal.c_et
	m.n_et = m.n_et + _fal.n_et

	m.a_acc = m.a_acc + _fal.a_acc
	m.d_acc = m.d_acc + _fal.d_acc
	m.o_acc = m.o_acc + _fal.o_acc
	m.p_acc = m.p_acc + _fal.p_acc
	m.e_acc = m.e_acc + _fal.e_acc
	m.c_acc = m.c_acc + _fal.c_acc
	m.n_acc = m.n_acc + _fal.n_acc

	m.a_wr = m.a_wr + _fal.a_wr
	m.d_wr = m.d_wr + _fal.d_wr
	m.o_wr = m.o_wr + _fal.o_wr
	m.p_wr = m.p_wr + _fal.p_wr
	m.e_wr = m.e_wr + _fal.e_wr
	m.c_wr = m.c_wr + _fal.c_wr
	m.n_wr = m.n_wr + _fal.n_wr

	m.a_rc = m.a_rc + _fal.a_rc
	m.d_rc = m.d_rc + _fal.d_rc
	m.o_rc = m.o_rc + _fal.o_rc
	m.p_rc = m.p_rc + _fal.p_rc
	m.e_rc = m.e_rc + _fal.e_rc
	m.c_rc = m.c_rc + _fal.c_rc
	m.n_rc = m.n_rc + _fal.n_rc

	m.a_sl = m.a_sl + _fal.a_sl
	m.d_sl = m.d_sl + _fal.d_sl
	m.o_sl = m.o_sl + _fal.o_sl
	m.p_sl = m.p_sl + _fal.p_sl
	m.e_sl = m.e_sl + _fal.e_sl
	m.c_sl = m.c_sl + _fal.c_sl
	m.n_sl = m.n_sl + _fal.n_sl
endscan 
insert into (lcDbf) from memvar

use in _fal
select (lnSelect)