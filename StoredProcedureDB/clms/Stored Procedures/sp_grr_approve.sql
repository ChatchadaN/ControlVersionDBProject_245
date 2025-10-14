-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [clms].[sp_grr_approve]
@grr_id int,
@chk_at varchar(10),
@sec_id int,
@do_user int,
@chk_user int,
@eq_id int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @SQLQuery AS NVARCHAR(4000)
	DECLARE @ParamDefinition AS NVARCHAR(2000)
    -- Insert statements for procedure here
	set @SQLQuery ='SELECT    grr.grr_id, APCSProDB.man.divisions.name AS div, dept.name AS depte, APCSProDB.man.sections.name AS section, eq.eq_name, eq.eq_num, ref_value_1.ref_desc AS model, grr.chk_at, 
                         ps.name AS process, ref_value_2.ref_desc AS chk_method, APCSProDB.ctrlic.ref_value.ref_desc AS chk_topic, grr.err_val_desc, grr.err_val, grr.for_use, eq.prod_no, 
                         users_1.name AS chk_user1, users_2.name AS chk_user2, APCSProDB.man.users.name AS chk_user3, users_3.name AS do_user, users_4.name AS head_div_user, users_5.name AS resp_user, users_6.name AS head_aff_user, 
                         users_7.name AS head_qc_user, users_8.name AS pe_div_user, grr.do_date, grr.head_div_date, grr.resp_date, grr.aff_date, grr.qc_date, grr.pe_date, grr.ndc_val, 
                         grr.grr_tol, grr.grr_tv, grr.min_pass, grr.min_pass_cond, grr.max_pass_cond, grr.max_not_pass, grr.max_ndc,grr.prod_name,grr.grr_ctrled_no,grr.appr_remark,grr.chk_type
FROM          APCSProDB.man.departments as  dept RIGHT OUTER JOIN
                         APCSProDB.ctrlic.ref_value AS ref_value_2 RIGHT OUTER JOIN
                         APCSProDB.man.users AS users_1 RIGHT OUTER JOIN
                         APCSProDB.man.users  RIGHT OUTER JOIN
                         APCSProDB.clms.cb_equip as  eq INNER JOIN
                         APCSProDB.clms.cb_grr as grr ON eq.eq_id = grr.eq_id LEFT OUTER JOIN
                         APCSProDB.man.users AS users_8 ON grr.pe_div_user = users_8.id LEFT OUTER JOIN
                         APCSProDB.man.users AS users_7 ON grr.head_qc_user = users_7.id LEFT OUTER JOIN
                         APCSProDB.man.users AS users_6 ON grr.head_aff_user = users_6.id LEFT OUTER JOIN
                         APCSProDB.man.users AS users_5 ON grr.resp_user = users_5.id LEFT OUTER JOIN
                         APCSProDB.man.users AS users_4 ON grr.head_div_user = users_4.id LEFT OUTER JOIN
                         APCSProDB.man.users AS users_3 ON grr.do_user = users_3.id ON APCSProDB.man.users.id = grr.chk3_user LEFT OUTER JOIN
                         APCSProDB.man.users AS users_2 ON grr.chk2_user = users_2.id ON users_1.id = grr.chk1_user LEFT OUTER JOIN
                         APCSProDB.ctrlic.ref_value ON grr.chk_topic = APCSProDB.ctrlic.ref_value.ref_id ON ref_value_2.ref_id = grr.chk_method LEFT OUTER JOIN
                         APCSProDB.method.processes As ps ON grr.process_id = ps.id LEFT OUTER JOIN
                         APCSProDB.ctrlic.ref_value AS ref_value_1 ON eq.qe_model_id = ref_value_1.ref_id LEFT OUTER JOIN
                         APCSProDB.man.sections ON grr.sec_id = APCSProDB.man.sections.id LEFT OUTER JOIN
                         APCSProDB.man.divisions ON grr.div_id = APCSProDB.man.divisions.id ON dept.id = grr.dept_id WHERE 1=1 '

IF @eq_id IS NOT NULL AND @eq_id > 0
	SET @SQLQuery = @SQLQuery + ' And (eq.eq_id  = @eq_id)'

IF @grr_id IS NOT NULL AND @grr_id > 0
	SET @SQLQuery = @SQLQuery + ' And (grr.grr_id  = @grr_id)'

IF @chk_at IS NOT NULL AND @chk_at <> ''
	SET @SQLQuery = @SQLQuery + ' And (cast(grr.chk_at as date) = @chk_at)'

IF @sec_id IS NOT NULL  AND @sec_id > 0
	SET @SQLQuery = @SQLQuery + ' And (grr.sec_id = @sec_id)'

IF @do_user IS NOT NULL AND @do_user > 0
	SET @SQLQuery = @SQLQuery + ' And (grr.do_user = @do_user)'

IF @chk_user IS NOT NULL  AND @chk_user > 0
	SET @SQLQuery = @SQLQuery + ' And (grr.chk1_user = @chk_user OR grr.chk2_user = @chk_user OR grr.chk3_user = @chk_user   )'



SET @ParamDefinition = '@grr_id int,
@chk_at varchar(10),
@sec_id int,
@do_user int,
@chk_user int,
@eq_id int'

/* Execute the Transact-SQL String with all parameter value's 
       Using sp_executesql Command */
EXECUTE sp_Executesql @SQLQuery
	,@ParamDefinition
	,@grr_id,
@chk_at,
@sec_id,
@do_user,
@chk_user,
@eq_id    

IF @@ERROR <> 0
	GOTO ErrorHandler

SET NOCOUNT OFF

RETURN (0)

ErrorHandler:

RETURN (@@ERROR)
END
