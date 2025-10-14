-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [clms].[sp_req_calibration_external]
@req_id int
,@chk_locate_name varchar(150)
,@eq_id int
,@extdo_user int
,@req_date varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @SQLQuery AS NVARCHAR(4000)
	DECLARE @ParamDefinition AS NVARCHAR(2000)
    -- Insert statements for procedure here
	set @SQLQuery ='SELECT        reqchk.req_id, eq.eq_name, eq.eq_num, eq.prod_no, cb_ref_value_1.ref_desc AS sup_name, cb_ref_value_1.ref_desc AS model, sections_2.name AS ctr_section, sections_2.name AS chk_section, reqchk.req_remark, 
                         reqchk.req_date, reqchk.cb_date as chk_finish_date, reqchk.chk_locate, reqchk.chk_locate_name, reqchk.chk_remark, reqchk.chk_result, reqchk.req_topic, div.name AS req_div, dept.name AS req_dept, sections_1.name AS req_section, 
                         CAST(reqchk.chk_date AS date) AS chk_date, users_2.name AS extdo_user, users_3.name AS extresp_main_user, users_1.name AS extresp_main_user2, users_4.name AS ext_headctr_user, CAST(reqchk.extdo_date AS date) 
                         AS extdo_date, CAST(reqchk.extresp_main_date AS date) AS extresp_main_date, CAST(reqchk.ext_headctr_date AS date) AS ext_headctr_date, CAST(reqchk.extresp_main_date2 AS date) AS extresp_main_date2, reqret.chk_id, 
                         reqret.seq_no, reqret.chk_sch_id, reqret.chk_topic, reqret.unit, reqret.chk_point_desc, reqret.chk_desc, reqret.std_desc, reqret.edit_desc, reqret.period_desc,sch.std_no
FROM            APCSProDB.man.divisions AS div RIGHT OUTER JOIN
                         APCSProDB.clms.req_chkeq_result AS reqret INNER JOIN APCSProDB.clms.chk_shc as sch
						 ON reqret.chk_sch_id = sch.chk_sch_id
						  RIGHT OUTER JOIN
                         APCSProDB.clms.req_chkeq AS reqchk INNER JOIN
                         APCSProDB.clms.cb_equip AS eq ON reqchk.eq_id = eq.eq_id ON reqret.req_id = reqchk.req_id LEFT OUTER JOIN
                         APCSProDB.man.users AS users_4 ON reqchk.ext_headctr_user = users_4.id LEFT OUTER JOIN
                         APCSProDB.man.users AS users_1 ON reqchk.extresp_main_user2 = users_1.id LEFT OUTER JOIN
                         APCSProDB.man.users AS users_3 ON reqchk.extresp_main_user = users_3.id LEFT OUTER JOIN
                         APCSProDB.man.users AS users_2 ON reqchk.extdo_user = users_2.id LEFT OUTER JOIN
                         APCSProDB.man.sections AS sections_1 ON reqchk.req_sec_id = sections_1.id LEFT OUTER JOIN
                         APCSProDB.man.departments AS dept ON reqchk.req_dept_id = dept.id ON div.id = reqchk.req_div_id LEFT OUTER JOIN
                         APCSProDB.man.sections AS sections_2 ON reqchk.chk_sec_id = sections_2.id LEFT OUTER JOIN
                         APCSProDB.clms.cb_ref_value AS cb_ref_value_1 ON eq.qe_model_id = cb_ref_value_1.ref_id
WHERE        (reqchk.chk_locate = ''EXT'')'

IF @req_id  IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' And (reqchk.req_id = @req_id)'

IF @req_date  IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' And (cast( reqchk.req_date as date) = @req_date)'




IF @eq_id IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' And (reqchk.eq_id = @eq_id)'

IF @extdo_user IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' And (reqchk.extdo_user = @extdo_user)'



SET @ParamDefinition = '@req_id int,
@chk_locate_name varchar(150)
,@eq_id int
,@extdo_user int
,@req_date varchar(10)'

/* Execute the Transact-SQL String with all parameter value's 
       Using sp_executesql Command */
EXECUTE sp_Executesql @SQLQuery
	,@ParamDefinition
	,@req_id
	,@chk_locate_name 
,@eq_id 
,@extdo_user
,@req_date    

IF @@ERROR <> 0
	GOTO ErrorHandler

SET NOCOUNT OFF

RETURN (0)

ErrorHandler:

RETURN (@@ERROR)
END
