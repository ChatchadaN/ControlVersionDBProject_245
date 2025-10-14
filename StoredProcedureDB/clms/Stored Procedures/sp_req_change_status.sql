-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [clms].[sp_req_change_status]
@req_chg_id int
,@req_chg_date as varchar(10)
,@req_sec_id int
,@eq_id int
,@chg_type varchar(6)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
SET NOCOUNT ON;
	DECLARE @SQLQuery AS NVARCHAR(4000)
	DECLARE @ParamDefinition AS NVARCHAR(2000)

    -- Insert statements for procedure here
set @SQLQuery ='SELECT       reqchg.req_chg_id, reqchg.req_chg_date, eq.eq_name, eq.eq_num, eq.prod_no,ref.ref_desc AS model, sections_1.name AS use_section, 
                         sections_3.name AS chk_section, reqchg.chg_type, reqchg.chg_type_date, div.name AS req_div, dept.name AS req_dept, sections_2.name AS req_section, 
                         reqchg.ext_borrow_locate, reqchg.remark, sections_4.name AS sec_from, APCSProDB.man.sections.name AS sec_to, users_4.name AS ctr_user, users_1.name AS head_user, 
                         users_2.name AS head_trnf_user, APCSProDB.man.users.name AS ctr_trnf_user, users_3.name AS resp_user, users_5.name AS appr_user,
						 cast( reqchg.resp_date as date) as resp_date, cast(reqchg.appr_date as date) as appr_date, 
                         cast(reqchg.send_apprdate as date) as send_apprdate, cast(reqchg.ctr_date as date) as ctr_date, cast( reqchg.head_date as date) as head_date, 
						 cast(reqchg.ctr_trnf_date as date) as ctr_trnf_date, cast(reqchg.head_trnf_date as date) as head_trnf_date
FROM            APCSProDB.man.sections AS sections_3 RIGHT OUTER JOIN
                         APCSProDB.man.divisions as div RIGHT OUTER JOIN
                         APCSProDB.clms.cb_equip as eq INNER JOIN
                         APCSProDB.clms.req_chgeq_status as reqchg ON eq.eq_id = reqchg.eq_id LEFT OUTER JOIN
                         APCSProDB.man.users AS users_2 ON reqchg.head_trnf_user = users_2.id LEFT OUTER JOIN
                         APCSProDB.man.users AS users_4 ON reqchg.ctr_user = users_4.id LEFT OUTER JOIN
                         APCSProDB.man.users AS users_5 ON reqchg.appr_user = users_5.id LEFT OUTER JOIN
                         APCSProDB.man.users AS users_3 ON reqchg.resp_user = users_3.id LEFT OUTER JOIN
                         APCSProDB.man.users ON reqchg.ctr_trnf_user = APCSProDB.man.users.id LEFT OUTER JOIN
                         APCSProDB.man.users AS users_1 ON reqchg.head_user = users_1.id LEFT OUTER JOIN
                         APCSProDB.man.sections AS sections_2 ON reqchg.req_sec_id = sections_2.id LEFT OUTER JOIN
                         APCSProDB.man.sections ON reqchg.section_to_id = APCSProDB.man.sections.id LEFT OUTER JOIN
                         APCSProDB.man.sections AS sections_4 ON reqchg.section_from_id = sections_4.id LEFT OUTER JOIN
                         APCSProDB.man.departments as dept ON reqchg.req_dept_id = dept.id ON div.id = reqchg.req_div_id ON sections_3.id = eq.chk_sec_id LEFT OUTER JOIN
                         APCSProDB.clms.cb_ref_value as ref ON eq.qe_model_id =ref.ref_id LEFT OUTER JOIN
                         APCSProDB.man.sections AS sections_1 ON eq.use_sec_id = sections_1.id WHERE 1=1'

IF @req_chg_id IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' And (reqchg.req_chg_id = @req_chg_id)'

IF @req_chg_date IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' And (cast(reqchg.req_chg_date as date) = @req_chg_date)'

IF @req_sec_id IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' And (reqchg.req_sec_id = @req_sec_id)'


IF @eq_id IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' And (reqchg.eq_id = @eq_id)'

IF @chg_type IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' And (reqchg.chg_type = @chg_type)'	



SET @ParamDefinition = '@req_chg_id int
,@req_chg_date as varchar(10)
,@req_sec_id int
,@eq_id int
,@chg_type varchar(6)'

/* Execute the Transact-SQL String with all parameter value's 
       Using sp_executesql Command */
EXECUTE sp_Executesql @SQLQuery
	,@ParamDefinition
	,@req_chg_id
	,@req_chg_date
	,@req_sec_id 
	,@eq_id 
	,@chg_type 

IF @@ERROR <> 0
	GOTO ErrorHandler

SET NOCOUNT OFF

RETURN (0)

ErrorHandler:

RETURN (@@ERROR)


END

