-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [clms].[sp_req_serv_calibration]
@req_id int,
@req_date varchar(10),
@req_sec_id int,
@chk_user_id int,
@ctr_user_id int,
@chk_locate varchar(3),
@eq_id int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @SQLQuery AS NVARCHAR(4000)
	DECLARE @ParamDefinition AS NVARCHAR(2000)
    -- Insert statements for procedure here
	set @SQLQuery ='SELECT        reqchk.req_id, eq.eq_name, eq.prod_no, eq.eq_num, cb_ref_value_1.ref_desc AS sup_name, cb_ref_value_1.ref_desc AS model, sec.name AS ctr_section, sections_2.name AS use_section, reqchk.req_remark, reqchk.req_date, 
                         reqchk.chk_finish_date, reqchk.chk_locate, reqchk.chk_locate_name, reqchk.chk_remark, reqchk.chk_result, reqchk.req_topic, div.name AS req_div, dept.name AS req_dept, sections_1.name AS req_section, 
                         users_1.name AS ctr_user, users_4.name AS chk_user, users_2.name AS resp_chk_user, users_3.name AS resp_main_user, users_4.name AS do_user, CAST(reqchk.ctr_date AS date) AS ctr_date, 
                         CAST(reqchk.chk_date AS date) AS chk_date, CAST(reqchk.resp_chk_date AS date) AS resp_chk_date, CAST(reqchk.resp_main_date AS date) AS resp_main_date, CAST(reqchk.do_date AS date) AS date
FROM            APCSProDB.clms.cb_ref_value AS cb_ref_value_1 RIGHT OUTER JOIN
                         APCSProDB.man.sections AS sections_2 RIGHT OUTER JOIN
                         APCSProDB.man.users AS users_4 RIGHT OUTER JOIN
                         APCSProDB.clms.req_chkeq AS reqchk INNER JOIN
                         APCSProDB.clms.cb_equip AS eq ON reqchk.eq_id = eq.eq_id ON users_4.id = reqchk.do_user LEFT OUTER JOIN
                         APCSProDB.man.users AS users_3 ON reqchk.resp_main_user = users_3.id LEFT OUTER JOIN
                         APCSProDB.man.users AS users_2 ON reqchk.resp_chk_user = users_2.id LEFT OUTER JOIN
                         APCSProDB.man.users AS users_1 ON reqchk.ctr_user = users_1.id LEFT OUTER JOIN
                         APCSProDB.man.sections AS sections_1 ON reqchk.req_sec_id = sections_1.id LEFT OUTER JOIN
                         APCSProDB.man.departments AS dept ON reqchk.req_dept_id = dept.id LEFT OUTER JOIN
                         APCSProDB.man.divisions AS div ON reqchk.req_div_id = div.id ON sections_2.id = reqchk.use_sec_id LEFT OUTER JOIN
                         APCSProDB.man.sections AS sec ON reqchk.use_sec_id = sec.id ON cb_ref_value_1.ref_id = eq.qe_model_id LEFT OUTER JOIN
                         APCSProDB.clms.cb_ref_value ON eq.eq_sup_id = cb_ref_value_1.ref_id   WHERE 1=1 '

IF @eq_id IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' And (reqchk.eq_id  = @eq_id)'

IF @req_id IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' And (reqchk.req_id  = @req_id)'

IF @req_date IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' And (cast(reqchk.req_date as date) = @req_date)'

IF @req_sec_id IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' And (reqchk.req_sec_id = @req_sec_id)'

IF @chk_user_id IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' And (reqchk.chk_user = @chk_user_id)'

IF @ctr_user_id IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' And (reqchk.ctr_user = @ctr_user_id)'

IF @chk_locate IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' And (reqchk.chk_locate = @chk_locate)'

SET @ParamDefinition = '@req_id int,
@req_date varchar(10),
@req_sec_id int,
@chk_user_id int,
@ctr_user_id int,
@chk_locate varchar(3),
@eq_id int'

/* Execute the Transact-SQL String with all parameter value's 
       Using sp_executesql Command */
EXECUTE sp_Executesql @SQLQuery
	,@ParamDefinition
	,@req_id 
	,@req_date ,
	@req_sec_id ,
	@chk_user_id ,
	@ctr_user_id ,
	@chk_locate,
	@eq_id    

IF @@ERROR <> 0
	GOTO ErrorHandler

SET NOCOUNT OFF

RETURN (0)

ErrorHandler:

RETURN (@@ERROR)
END
