-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [clms].[sp_result_calibration_in_main]
@req_id int,
@cb_date varchar(10),
@eq_id int,
@do_user int,
@req_user int,
@req_sec_id int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @SQLQuery AS NVARCHAR(4000)
	DECLARE @ParamDefinition AS NVARCHAR(2000)

    -- Insert statements for procedure here
set @SQLQuery ='SELECT        reqchk.req_id, eq.eq_name,eq.eq_num, eq.prod_no , cb_ref_value_2.ref_desc AS sup_name,sec.name AS chk_sec, cb_ref_value_1.ref_desc AS model, reqchk.req_remark, reqchk.req_date, 
                         reqchk.chk_finish_date, reqchk.chk_locate, reqchk.chk_locate_name, reqchk.chk_remark, reqchk.chk_result, reqchk.req_topic, div.name AS req_div, 
                         dept.name AS req_dept, sections_1.name AS req_section, reqchk.ctr_date, reqchk.chk_date, reqchk.resp_chk_date, reqchk.resp_main_date, 
                         cb_equip_1.eq_name AS eq_use_name,cb_equip_1.eq_num as eq_use_num, APCSProDB.clms.cb_ref_value.ref_desc AS use_sup_name, cb_ref_value_3.ref_desc AS use_model, cb_equip_1.prod_no AS use_prod_no, APCSProDB.man.users.name AS do_user, 
                         users_2.name AS appr_do_user, users_1.name AS confirm_user, 
						 cast (reqchk.do_date as date) as do_date, 
						 cast(reqchk.appr_do_date as date) as appr_do_date, 
						 cast(reqchk.confirm_date as date) as confirm_date,
						reqchk.have_info, reqchk.cb_date,
						reqchk.eq_apperance,reqchk.eq_ng_desc,reqchk.env_hum,reqchk.env_temp,users_3.name as req_user,reqchk.std_no
FROM           APCSProDB.clms.cb_ref_value AS cb_ref_value_2 RIGHT OUTER JOIN
                         APCSProDB.man.users RIGHT OUTER JOIN
                         APCSProDB.clms.req_chkeq as reqchk INNER JOIN
                         APCSProDB.clms.cb_equip as eq ON reqchk.eq_id = eq.eq_id  LEFT OUTER JOIN
                         APCSProDB.man.sections as sec ON reqchk.chk_sec_id =sec.id  LEFT OUTER JOIN
                         APCSProDB.man.users AS users_3 ON reqchk.req_user = users_3.id LEFT OUTER JOIN
                         APCSProDB.man.users AS users_1 ON reqchk.confirm_user = users_1.id LEFT OUTER JOIN
                         APCSProDB.man.users AS users_2 ON reqchk.appr_do_user = users_2.id ON APCSProDB.man.users.id = reqchk.do_user LEFT OUTER JOIN
                         APCSProDB.clms.cb_equip AS cb_equip_1 INNER JOIN
                         APCSProDB.clms.req_chkeq_used as equse ON cb_equip_1.eq_id = equse.eq_id INNER JOIN
                         APCSProDB.clms.cb_ref_value ON cb_equip_1.eq_sup_id = APCSProDB.clms.cb_ref_value.ref_id INNER JOIN
                         APCSProDB.clms.cb_ref_value AS cb_ref_value_3 ON cb_equip_1.qe_model_id = cb_ref_value_3.ref_id ON reqchk.req_id = equse.req_id LEFT OUTER JOIN
                         APCSProDB.man.sections AS sections_1 ON reqchk.req_sec_id = sections_1.id LEFT OUTER JOIN
                         APCSProDB.man.departments as dept ON reqchk.req_dept_id = dept.id LEFT OUTER JOIN
                         APCSProDB.man.divisions as div ON reqchk.req_div_id = div.id LEFT OUTER JOIN
                         APCSProDB.clms.cb_ref_value AS cb_ref_value_1 ON eq.qe_model_id = cb_ref_value_1.ref_id ON cb_ref_value_2.ref_id = eq.eq_sup_id
WHERE reqchk.chk_locate =''IN'''

IF @req_id IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' And (reqchk.req_id = @req_id)'

IF @cb_date IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' And (cast(reqchk.cb_date as date) = @cb_date)'


IF @eq_id IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' And (reqchk.eq_id = @eq_id)'

IF @do_user IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' And (reqchk.do_user = @do_user)'

IF @req_user IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' And (reqchk.req_user = @req_user)'

IF @req_sec_id IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' And (reqchk.req_sec_id = @req_sec_id)'

SET @ParamDefinition = '@req_id int,
@cb_date varchar(10),
@eq_id int,
@do_user int,
@req_user int,
@req_sec_id int'

/* Execute the Transact-SQL String with all parameter value's 
       Using sp_executesql Command */
EXECUTE sp_Executesql @SQLQuery
	,@ParamDefinition
	,@req_id, 
@cb_date ,
@eq_id ,
@do_user ,
@req_user ,
@req_sec_id  

IF @@ERROR <> 0
	GOTO ErrorHandler

SET NOCOUNT OFF

RETURN (0)

ErrorHandler:

RETURN (@@ERROR)
END
