
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_appove_skill]
	/* Input Parameters */
	@PLAN_ID BIGINT
	,@STATUS VARCHAR(10)
	,@ROLE VARCHAR (10)
	,@EMP_NUM VARCHAR(50)
	,@PLAN_YEAR SMALLINT
AS
SET NOCOUNT ON

/* Variable Declaration 
	,
	@EMPNUM varchar(50),
	@EMPNAME varchar(100)*/
DECLARE @SQLQuery AS NVARCHAR(4000)
DECLARE @ParamDefinition AS NVARCHAR(2000)




/* Build the Transact-SQL String with the input parameters */
SET @SQLQuery = 'SELECT        APCSProDB.ctrlic.approve_skill.approve_id, APCSProDB.ctrlic.approve_skill.ex_trans_id, CAST(APCSProDB.ctrlic.approve_skill.approve_date AS date) AS approve_date, 
    CAST(APCSProDB.ctrlic.approve_skill.qc_approve_date AS date) AS qc_approve_date, CAST(APCSProDB.ctrlic.approve_skill.check_date AS date) AS check_date, APCSProDB.ctrlic.exam_plan.qc_approve_user, 
    CASE WHEN apcsprodb.ctrlic.approve_skill.check_date IS NULL THEN ''WAIT_CHECK'' WHEN apcsprodb.ctrlic.approve_skill.approve_date IS NULL 
    THEN ''WAIT_APPROVE'' WHEN apcsprodb.ctrlic.approve_skill.qc_approve_date IS NULL THEN ''WAIT_QC_APPROVE'' WHEN apcsprodb.ctrlic.approve_skill.approve_date IS NOT NULL AND 
    apcsprodb.ctrlic.approve_skill.qc_approve_date IS NOT NULL THEN ''COMPLEATED'' END AS status, APCSProDB.man.view_user_organizations.division_id, APCSProDB.man.view_user_organizations.department_id, 
    APCSProDB.man.view_user_organizations.section_id, APCSProDB.man.users.full_name, APCSProDB.man.users.emp_num, APCSProDB.ctrlic.exam_trans.plan_id, APCSProDB.ctrlic.exam_plan.plan_desc, 
    APCSProDB.man.divisions.name AS division, APCSProDB.man.departments.name AS department, APCSProDB.man.sections.name AS section, APCSProDB.ctrlic.user_profile.start_date AS work_date, do_users.full_name AS do_user, 
    check_users.full_name AS check_user, approve_users.full_name AS approve_user, qc_users.full_name AS qc_user, lic1.ref_desc AS current_skill, lic2.ref_desc AS old_skill,APCSProDB.ctrlic.approve_skill.SEND_DATE as do_date
FROM    APCSProDB.man.divisions INNER JOIN
       APCSProDB.man.user_organizations INNER JOIN
       APCSProDB.man.view_user_organizations ON APCSProDB.man.user_organizations.organization_id = APCSProDB.man.view_user_organizations.id ON 
       APCSProDB.man.divisions.id = APCSProDB.man.view_user_organizations.division_id INNER JOIN
       APCSProDB.man.departments ON APCSProDB.man.view_user_organizations.department_id = APCSProDB.man.departments.id INNER JOIN
      APCSProDB.man.sections ON APCSProDB.man.view_user_organizations.section_id = APCSProDB.man.sections.id RIGHT OUTER JOIN
  APCSProDB.man.users INNER JOIN
  APCSProDB.ctrlic.approve_skill INNER JOIN
  APCSProDB.ctrlic.exam_trans ON APCSProDB.ctrlic.approve_skill.ex_trans_id = APCSProDB.ctrlic.exam_trans.ex_trans_id INNER JOIN
  APCSProDB.ctrlic.exam_plan ON APCSProDB.ctrlic.exam_trans.plan_id = APCSProDB.ctrlic.exam_plan.plan_id ON APCSProDB.man.users.id = APCSProDB.ctrlic.exam_trans.user_id ON 
  APCSProDB.man.user_organizations.user_id = APCSProDB.ctrlic.exam_trans.user_id LEFT OUTER JOIN
  APCSProDB.man.users AS do_users ON APCSProDB.ctrlic.exam_plan.do_user = do_users.id LEFT OUTER JOIN
  APCSProDB.man.users AS approve_users ON APCSProDB.ctrlic.approve_skill.approve_user = approve_users.id LEFT OUTER JOIN
  APCSProDB.man.users AS check_users ON APCSProDB.ctrlic.approve_skill.check_user = check_users.id LEFT OUTER JOIN
  APCSProDB.man.users AS qc_users ON APCSProDB.ctrlic.approve_skill.qc_user = qc_users.id LEFT OUTER JOIN
  APCSProDB.ctrlic.ref_value AS lic2 ON APCSProDB.ctrlic.approve_skill.old_skill = lic2.ref_id LEFT OUTER JOIN
  APCSProDB.ctrlic.ref_value AS lic1 ON APCSProDB.ctrlic.approve_skill.current_skill = lic1.ref_id LEFT OUTER JOIN
  APCSProDB.ctrlic.user_profile ON APCSProDB.ctrlic.exam_trans.user_id = APCSProDB.ctrlic.user_profile.user_id'

IF @PLAN_YEAR IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' WHERE (apcsprodb.ctrlic.exam_plan.PLAN_YEAR = @PLAN_YEAR) '

IF @PLAN_ID IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' And (apcsprodb.ctrlic.exam_plan.PLAN_ID = @PLAN_ID) '



IF @STATUS ='NOT_COMPLEATE'
		SET @SQLQuery = @SQLQuery + ' AND (apcsprodb.ctrlic.approve_skill.check_date IS NULL OR ctrlic.approve_skill.approve_date IS NULL OR ctrlic.approve_skill.qc_approve_date IS NULL)'
	ELSE IF @STATUS='WAIT_CHECK'
			SET @SQLQuery = @SQLQuery + ' AND (apcsprodb.ctrlic.approve_skill.check_date IS NULL )'
	ELSE IF @STATUS ='WAIT_APPROVE'
		SET @SQLQuery = @SQLQuery + ' AND (apcsprodb.ctrlic.approve_skill.check_date IS NOT NULL and APCSProDB.ctrlic.approve_skill.approve_date IS NULL )'
	ELSE IF @STATUS='WAIT_QC_APPROVE'
		SET @SQLQuery = @SQLQuery + ' AND (apcsprodb.ctrlic.approve_skill.approve_date IS NOT NULL AND APCSProDB.ctrlic.approve_skill.qc_approve_date IS NULL)'
	ELSE IF @STATUS='COMPLEATED'
			SET @SQLQuery = @SQLQuery + ' AND (apcsprodb.ctrlic.approve_skill.approve_date IS NOT NULL AND APCSProDB.ctrlic.approve_skill.qc_approve_date IS NOT NULL)'

--IF @EMP_NUM IS NOT NULL
--	SET @SQLQuery = @SQLQuery + ' And (apcsprodb.man.users.emp_num = ''' + @EMP_NUM + ''')'


IF @ROLE ='DO' AND @EMP_NUM IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' AND (do_users.emp_num = ''' + @EMP_NUM + ''')'
	ELSE IF @ROLE='CHECK' AND @EMP_NUM IS NOT NULL
		SET @SQLQuery = @SQLQuery + ' AND (check_users.emp_num = ''' + @EMP_NUM + ''')'
	ELSE IF @ROLE='QC_APPROVE' AND @EMP_NUM IS NOT NULL
		SET @SQLQuery = @SQLQuery + ' AND (qc_users.emp_num = ''' + @EMP_NUM + ''')'
    ELSE IF @ROLE='USER' AND @EMP_NUM IS NOT NULL
		SET @SQLQuery = @SQLQuery + ' AND (apcsprodb.man.users.emp_num = ''' + @EMP_NUM + ''')'



	--	print @SQLQuery
/* Specify Parameter Format for all input parameters included 
     in the stmt */
SET @ParamDefinition = '@PLAN_ID BIGINT
	,@STATUS VARCHAR(10)
	,@ROLE VARCHAR (10)
	,@EMP_NUM VARCHAR(50)
	,@PLAN_YEAR SMALLINT'

/* Execute the Transact-SQL String with all parameter value's 
       Using sp_executesql Command */
EXECUTE sp_Executesql @SQLQuery
	,@ParamDefinition
	,@PLAN_ID 
	,@STATUS 
	,@ROLE 
	,@EMP_NUM 
	,@PLAN_YEAR 
IF @@ERROR <> 0
	GOTO ErrorHandler

SET NOCOUNT OFF

RETURN (0)

ErrorHandler:

RETURN (@@ERROR)