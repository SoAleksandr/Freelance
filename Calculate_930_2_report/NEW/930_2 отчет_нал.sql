--------------------------------930_2 отчет_нал---------------------------------

--Query_1 Установка значений

--23.11.2008
--Наличный расчет
--Расчет по БПК
--Бердянск Коммунаров ДЭ магазин
--Расширенный по счетам

Begin
  sa.Pa_Context.Set_Application_Ctx('p_date',to_char( :p_date,'DD.MM.YYYY'));
  sa.Pa_Context.Set_Application_Ctx('p_bnl',to_char( :p_bnl ));
  sa.Pa_Context.Set_Application_Ctx('p_nal',to_char( :p_nal ));
  sa.Pa_Context.Set_Application_Ctx('p_crd',to_char( :p_crd ));
  sa.Pa_Context.Set_Application_Ctx('p_ext_dept',to_char( :p_podr ));
  sa.Pa_Context.Set_Application_Ctx('p_ext_entity',to_char( :p_ext_entity ));
end;

--Query_2 Итоговые суммы по подрозделениям (Начитка в основную таблицу)

WITH
   l_pay1 AS (
    SELECT /*+first_rows*/
      l.entity_id as Entity_id
      ,p.report_date AS oper_date
      ,p.dept_id AS Slave_dept_id
      ,p.dept_id AS master_dept_id
      ,sum(decode(l.link_direction,0,-1,1)*DECODE(d.direction,-1,0,l.payment_sum)) as summa_p2
      ,sum(decode(l.link_direction,0,-1,1)*DECODE(d.direction,1,0,l.payment_sum))  as summa_up2
      ,case when d.code='NAL' and ipt.code = 'BNL'
         then sum(decode(l.link_direction,0,-1,1)*DECODE(d.direction,-1,0,l.payment_sum))
         else 0 end as summa_ppc2
      ,case when d.code='NAL' and ipt.code = 'BNL'
         then sum(decode(l.link_direction,0,-1,1)*DECODE(d.direction,1,0,l.payment_sum))
         else 0 end as summa_uppc2
      ,case when d.code = 'NAL' and ipt.code = 'BNL' then 1 else 0 end as is_ppc
      ,case when d.code = 'CRD' then 1 else 0 end as is_crd
      ,case when d.code = 'NAL' and not (ipt.code = 'BNL' and d.code='NAL') then 1 else 0 end as is_nal
      ,case when d.code = 'BNL' or (ipt.code = 'BNL' and d.code='NAL') then 1 else 0 end as is_bnl
      FROM sa.e_payment_link l, sa.e_payment p, sa.d_payment_type d,sa.e_ihead h,sa.d_payment_type ipt
      WHERE l.payment_id=p.ID
         AND p.payment_type_id=d.ID
         AND l.payment_type='PAY'
         AND l.entity_type='INV'
         AND l.entity_id=h.id
         AND h.payment_type_id=ipt.id
         AND report_date=TO_DATE (Sys_context ('application', 'p_date'),'DD.MM.YYYY')
         AND p.dept_id IN (SELECT ID FROM sa.d_dept WHERE dept_type IN ('SHOP','SERV_DEPT' ))
       Group by
            l.entity_id
            ,p.report_date
            ,p.dept_id
            ,d.code
            ,ipt.code )
            
--------------------------------------------------------------------------------

   ,l_pay2 as (select Entity_Id
                   ,Oper_Date
                   ,Slave_Dept_Id
                   ,Master_Dept_Id
                   ,Is_Crd
                   ,Is_Nal
                   ,Is_Bnl
                   ,sum(Summa_P2) as Summa_P2
                   ,sum(Summa_Up2) as Summa_Up2
                   ,sum(Summa_Ppc2) as Summa_Ppc2
                   ,sum(Summa_Uppc2) as Summa_Uppc2
               from (select Entity_Id
                           ,Oper_Date
                           ,Slave_Dept_Id
                           ,Master_Dept_Id
                           ,Summa_P2
                           ,Summa_Up2
                           ,Summa_Ppc2
                           ,Summa_Uppc2
                           ,Is_Crd
                           ,Is_Nal
                           ,Is_Bnl
                       from l_Pay1 u
                      WHERE (u.Is_Crd = 1 and To_Number(Sys_Context('application', 'p_crd')) = 1)
                         or ((u.Is_Nal = 1 or u.Is_Ppc = 1) and
                            To_Number(Sys_Context('application', 'p_nal')) = 1)
                         or (u.Is_Bnl = 1 and To_Number(Sys_Context('application', 'p_bnl')) = 1)) Up2
              group by Entity_Id
                      ,Oper_Date
                      ,Slave_Dept_Id
                      ,Master_Dept_Id
                      ,Is_Crd
                      ,Is_Nal
                      ,Is_Bnl)
   ,l_upload AS
   (
SELECT
ENTITY_ID
,OPER_DATE
,min(SLAVE_DEPT_ID) as SLAVE_DEPT_ID
,MASTER_DEPT_ID
,SUM(summa_h) AS summa_h2
,SUM(summa_uh) AS SUMMA_UH2
,is_nal
,is_bnl
,is_crd
FROM
  (
SELECT
ENTITY_ID
,oper_date
,md AS MASTER_DEPT_ID
,ds AS  SLAVE_DEPT_ID
,DECODE(direction,1,SUM(summa),0) AS summa_h
,DECODE(direction,-1,SUM(summa),0) AS SUMMA_UH
,type_id
,is_nal
,is_bnl
,is_crd
FROM
  (
SELECT
  h.ID
  ,h.invoice_id AS entity_id
  ,h.doc_date AS oper_date
  ,decode(h.payment_type_id,43,1,44,1,cash) as cash
  ,df.ID AS df
  ,dt.ID AS dt
  ,NVL(dt.ID,df.ID) ds
  ,CASE WHEN h.Type_id in (110,8) then (SELECT d1.ID FROM sa.d_dept d1 WHERE d1.k_object=dst.k_firm)
        When h.Type_id not in (110,8) and dt.id is null then df.parent_id
        else dt.parent_id end as md
  ,DECODE(df.ID,NULL,-1,1) AS direction
  ,ROUND(h.summa,2) AS summa
  ,h.type_id
  ,case when h.payment_type_id in (43,44) then 0 else decode(h.cash, 1,1,0) end as is_nal
  ,case when h.payment_type_id in (43,44) then 0 else decode(h.cash, 0,1,0) end as is_bnl
  ,decode(h.payment_type_id,43,1,44,1,0) as is_crd
  FROM sa.v_full_dhead h, sa.l_dept_firm dff,sa.l_dept_firm dft,sa.D_SUBJ dsf,sa.D_SUBJ dst, sa.d_dept df , sa.d_dept dt, sa.e_ihead ih
  WHERE
      h.from_dept_id=dff.ID(+)
  AND h.to_dept_id=dft.ID(+)
  AND dff.dept_id=df.ID(+)
  AND dft.dept_id=dt.ID(+)
  AND h.from_dept_id=dsf.ID
  AND h.to_dept_id=dst.ID
  AND (dff.ID+dft.ID) IS NULL
  AND h.doc_state='ПРОВ'
  AND h.invoice_id=ih.id
  AND h.type_id NOT IN (3,28,228)
  AND h.Doc_date = TO_DATE (Sys_context ('application', 'p_date'),'DD.MM.YYYY')
  AND h.invoice_id is not null
  ) h1
WHERE md IN (SELECT ID FROM sa.d_dept WHERE dept_type IN ('SHOP','SERV_DEPT'))
    and ((is_crd = 1 and TO_Number(Sys_context('application', 'p_crd'))=1)
      or (is_nal = 1 and TO_Number(Sys_context('application', 'p_nal'))=1)
      or (is_bnl = 1 and TO_Number(Sys_context('application', 'p_bnl'))=1))
GROUP BY entity_id,oper_date,ds,md,direction,cash,type_id,is_nal,is_bnl,is_crd
)
GROUP BY entity_id,oper_date,MASTER_DEPT_ID,is_nal,is_bnl,is_crd
   ) 
select entity_id
      ,oper_date
      ,master_dept_id
      ,slave_dept_id
      ,summa_i0
      ,summa_p0
      ,summa_h0
      ,summa_p2
      ,summa_h2
      ,summa_h0_p0
      ,summa_p0_h1
      ,summa_h0_p1
      ,summa_h0_NOTp0
      ,summa_p0_NOTh0
      ,summa_up2
      ,summa_uh2
      ,summa_rh1
      ,summa_rp1
      ,summa_rh0
      ,summa_rp0
      ,summa_p1_NOTh0
      ,summa_h1_NOTp0
      ,summa_p2_NotH0
      ,summa_h2_NotP0
      ,summa_h1_p1
      ,summa_ppc2
      ,summa_uppc2
      ,nvl((select s.name from sa.d_dept s where s.id=u3.slave_dept_id),'Неопределенное подразделение отгрузки') as slave_dept_name
      ,(select s.name from sa.d_dept s where s.id=u3.master_dept_id) master_dept_name      
from ( 
       SELECT entity_id
             ,oper_date
             ,master_dept_id
             ,slave_dept_id
             ,sum(summa_i0) as summa_i0
             ,sum(summa_p0) as summa_p0
             ,sum(summa_h0) as summa_h0
             ,sum(summa_p2) as summa_p2
             ,sum(summa_h2) as summa_h2
             ,sum(least(decode(sign(summa_h2-summa_rp1),1,summa_h2-summa_rp1,0),decode(sign(summa_p2-summa_rh1),1,summa_p2-summa_rh1,0))) as summa_h0_p0
             ,sum(least(summa_p2,summa_rh1)) as summa_p0_h1
             ,sum(least(summa_h2,summa_rp1)) as summa_h0_p1
             ,sum(summa_h0_NOTp0) as summa_h0_NOTp0
             ,sum(summa_p0_NOTh0) as summa_p0_NOTh0
             ,sum(summa_up2) as summa_up2
             ,sum(summa_uh2) as summa_uh2
             ,sum(summa_rh1) as summa_rh1
             ,sum(summa_rp1) as summa_rp1
             ,sum(summa_rh0) as summa_rh0
             ,sum(summa_rp0) as summa_rp0
             ,sum(summa_p1_NOTh0) as summa_p1_NOTh0
             ,sum(summa_h1_NOTp0) as summa_h1_NOTp0
             ,sum(least(summa_p0_NOTh0,summa_p2)) as summa_p2_NotH0
             ,sum(least(summa_h0_NOTp0,summa_h2)) as summa_h2_NotP0
             ,sum(least(summa_h1,summa_p1)) as summa_h1_p1
             ,sum(summa_ppc2) as summa_ppc2
             ,sum(summa_uppc2) as summa_uppc2
       FROM (SELECT decode(TO_Number (Sys_context ('application', 'p_ext_entity')),1,entity_id,0) as entity_id
                   ,oper_date
                   ,decode(TO_Number (Sys_context ('application', 'p_ext_dept')),1,slave_dept_id,master_dept_id) as slave_dept_id
                   ,master_dept_id
                   ,summa_i0
                   ,summa_h0
                   ,summa_p0
                   ,least(summa_h0,summa_p0) as summa_h0_p0
                   ,summa_h1
                   ,summa_p1
                   ,summa_p2
                   ,summa_h2
                   ,greatest(summa_h0-summa_p0,0) as summa_h0_NOTp0
                   ,greatest(summa_p0-summa_h0,0) as summa_p0_NOTh0
                   ,summa_up2
                   ,summa_uh2
                   ,case when summa_h1>summa_p1 then summa_h1-summa_p1 else 0 end as summa_rh1
                   ,case when summa_p1>summa_h1 then summa_p1-summa_h1 else 0 end as summa_rp1
                   ,case when summa_h0>summa_p0 then summa_h0-summa_p0 else 0 end as summa_rh0
                   ,case when summa_p0>summa_h0 then summa_p0-summa_h0 else 0 end as summa_rp0
                   ,greatest(summa_P1-summa_H0,0) as summa_p1_NOTh0
                   ,greatest(summa_H1-summa_P0,0) as summa_h1_NOTp0
                   ,summa_ppc2
                   ,summa_uppc2
             FROM (SELECT entity_id
                         ,slave_dept_id
                         ,master_dept_id
                         ,oper_date
                         ,case when TO_Number(Sys_context('application', 'p_nal'))=1 and (summa_ppc2<>0 or summa_uppc2<>0) then 0 else sa.pa_invoice.Get_Invoice_Sum(entity_id) end as Summa_I0
                         ,case when TO_Number(Sys_context('application', 'p_nal'))=1 and (summa_ppc2<>0 or summa_uppc2<>0) then 0
                         else (select nvl(sum(decode(l.link_direction,0,-1,1)*DECODE(d.direction,-1,0,l.payment_sum)),0) from sa.e_payment p, sa.e_payment_link l,sa.d_payment_type d where p.payment_type_id=d.id and l.payment_id=p.id and l.payment_type='PAY' and l.entity_type='INV' and l.entity_id=u.entity_id and p.report_date+0<=trunc(oper_date)) end as summa_p0                            
                         ,case when TO_Number(Sys_context('application', 'p_nal'))=1 and (summa_ppc2<>0 or summa_uppc2<>0) then 0
                         else (select nvl(sum(d.summa),0)  from sa.v_invoice_documents d where d.type_id not in (5,6) and d.invoice_id = u.entity_id and d.l_type = 'L' and d.doc_date+0<=trunc(oper_date)) end as summa_h0
                         ,case when TO_Number(Sys_context('application', 'p_nal'))=1 and (summa_ppc2<>0 or summa_uppc2<>0) then 0
                         else (select nvl(sum(decode(l.link_direction,0,-1,1)*DECODE(d.direction,-1,0,l.payment_sum)),0) from sa.e_payment p, sa.e_payment_link l,sa.d_payment_type d where p.payment_type_id=d.id and l.payment_id=p.id and l.payment_type='PAY' and l.entity_type='INV' and l.entity_id=u.entity_id and p.report_date+0<trunc(oper_date)) end as summa_p1
                         ,case when TO_Number(Sys_context('application', 'p_nal'))=1 and (summa_ppc2<>0 or summa_uppc2<>0) then 0
                         else (select nvl(sum(d.summa),0)  from sa.v_invoice_documents d where d.type_id not in (5,6) and d.invoice_id = u.entity_id and d.l_type = 'L' and d.doc_date+0<trunc(oper_date)) end as summa_h1
                         ,case when TO_Number(Sys_context('application', 'p_nal'))=1 and (summa_ppc2<>0 or summa_uppc2<>0) then 0 else summa_p2 end as summa_p2 
                         ,case when TO_Number(Sys_context('application', 'p_nal'))=1 and (summa_ppc2<>0 or summa_uppc2<>0) then 0 else summa_h2 end as summa_h2 
                         ,case when TO_Number(Sys_context('application', 'p_nal'))=1 and (summa_ppc2<>0 or summa_uppc2<>0) then 0 else summa_up2 end as summa_up2 
                         ,case when TO_Number(Sys_context('application', 'p_nal'))=1 and (summa_ppc2<>0 or summa_uppc2<>0) then 0 else summa_uh2 end as summa_uh2 
                         ,summa_ppc2
                         ,summa_uppc2
                   FROM (SELECT p.entity_id
                               ,p.oper_date
                               ,NVL(p.summa_p2,0) AS summa_p2
                               ,h.slave_dept_id
                               ,p.master_dept_id
                               ,NVL(h.summa_h2,0) AS summa_h2
                               ,NVL(p.summa_up2,0) AS summa_up2
                               ,NVL(h.summa_uh2,0) AS summa_uh2
                               ,NVL(p.summa_ppc2,0) as summa_ppc2
                               ,NVL(p.summa_uppc2,0) as summa_uppc2
                         FROM l_pay2 p LEFT OUTER JOIN l_upload h ON p.entity_id=h.entity_id
                         UNION
                         SELECT h.entity_id
                               ,h.oper_date
                               ,NVL(p.summa_p2,0) AS summa_p2
                               ,h.slave_dept_id
                               ,h.master_dept_id
                               ,NVL(h.summa_h2,0) AS summa_h2
                               ,NVL(p.summa_up2,0) AS summa_up2
                               ,NVL(h.summa_uh2,0) AS summa_uh2
                               ,NVL(p.summa_ppc2,0) as summa_ppc2
                               ,NVL(p.summa_uppc2,0) as summa_uppc2
                         FROM l_upload h LEFT OUTER JOIN l_pay2 p ON p.entity_id=h.entity_id
                      ) u, sa.e_ihead ih1
                    where u.entity_id=ih1.id
                 )
            ) u2
       GROUP BY oper_date
               ,entity_id
               ,slave_dept_id
               ,master_dept_id) u3
where u3.master_dept_id= :p_dept or :p_dept is null;

--Query_3 Сальдо на утро и на вечер

select
 (select name from d_dept where id=:p_dept) as dept_name
 ,TO_DATE (Sys_context ('application', 'p_date'),'DD.MM.YYYY') as date_doc
 ,Sys_context ('application', 'p_nal') as is_nal
 ,Sys_context ('application', 'p_bnl') as is_bnl
 ,Sys_context ('application', 'p_crd') as is_crd
,(select sa.c_string(decode(rownum,1,'',',')||nal_type)  from
(select 'Наличный расчет' as nal_type
from dual
where Sys_context ('application', 'p_nal')='1'
union all
select 'Безналичный расчет' as nal_type
from dual
where Sys_context ('application', 'p_bnl')='1'
union all
select 'Расчет по БПК' as nal_type
from dual
where Sys_context ('application', 'p_crd')='1') u) as nal_type
, sa.pa_balance.fu_get_money_rest(:p_date, :p_dept) as saldo_evening
, (SELECT rest_summa
        FROM sa_arx.e_money_rest
       WHERE ID = (SELECT MAX(ID)
                     FROM sa_arx.e_money_rest
                    WHERE report_date = TRUNC(SYSDATE) - 1 and dept_id=:p_dept)) as saldo_morning
, sysdate as print_date
 from dual;
 
--Query_4 Сумма возаратов по предоплатам кредитов.

SELECT
    SUM(Nvl(decode(f.Fiscal_Type_Id,9,Summa,0),0)) as fiskal_z
    ,SUM(Nvl(decode(f.Fiscal_Type_Id,3,Summa,0),0)) as fiskal_upload
    FROM e_Fiscal_Info f
   WHERE f.Doc_Date = :p_date
     AND f.Fiscal_Type_Id in (3,9)
     AND Dept_Id = :p_dept;

--Query_5 Общая сумма возвратов по БПК

select
 sum(sum_pay) as crd_z
,sum(sum_cancel+sum_return) as crd_upload
from sa.e_bank_pos_info
where 1=1
and dept_id= :p_dept
and report_date= :p_date
having Sys_context ('application', 'p_crd')='1'

--Query_6 Сумма оплат и возвратов по подразделению

select sum(decode(t.direction,1,p.Summa,0)) as summa_plus
      ,sum(decode(t.direction,-1,p.Summa,0)) as summa_minus
      ,d.name
  from Sa.e_Payment      p
  ,Sa.d_Payment_Type t
  ,Sa.v_Kass_Option  k
      ,sa.d_dept d
 where p.Payment_Type_Id = t.Id
 AND Decode(t.Code, 'NAL', 1, 'NAL_OUT', 1, 'CRD', 1, 0) = 1
 and Report_Date = :p_date
 and Option_Name = 'KASSA_NUM'
 and p.Pos_Number = k.VALUE
 and p.dept_id=d.id
 --and Sys_context ('application', 'p_nal')=1
 and exists (select 1
    from Sa.v_Kass_Option
   where Option_Name = 'USE_DEPT'
     and value = 6818
     and Ip = k.Ip)
group by d.name;
