-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [clms].[sp_grr_control_ledger]
@year int
,@eq_id int
,@chk_date varchar(10)
,@ledger_no as varchar(20)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @SQLQuery AS NVARCHAR(4000)
	DECLARE @ParamDefinition AS NVARCHAR(2000)
    -- Insert statements for procedure here
set @SQLQuery ='SELECT        eq.grr_ctrled_no,year(grr.do_date) as do_year , grr.do_date, eq.eq_name,ref.ref_desc AS model, cb_ref_value_1.ref_type_code AS maker, 
                         eq.prod_no, cb_ref_value_2.ref_desc AS chk_medthod, grr.for_use, grr.prod_name, cb_ref_value_3.ref_desc AS chk_topic, grr.err_val, 
                         u.full_name AS chk1_user, users_1.full_name AS chk2_user, users_2.full_name AS chk3_user, grr.grr_val, grr.ndc_val, grr.grr_tol, 
                         grr.grr_tv, grr.grr_accep_status, grr.ndc_accep_status, eq.eq_num, ps.name AS process
FROM            APCSProDB.method.processes as ps INNER JOIN
                         APCSProDB.clms.cb_equip as eq INNER JOIN
                         APCSProDB.clms.cb_grr as  grr ON eq.eq_id = grr.eq_id INNER JOIN
                         APCSProDB.clms.cb_ref_value as ref ON eq.qe_model_id =ref.ref_id INNER JOIN
                         APCSProDB.clms.cb_ref_value AS cb_ref_value_1 ON eq.eq_sup_id = cb_ref_value_1.ref_id INNER JOIN
                         APCSProDB.clms.cb_ref_value AS cb_ref_value_2 ON grr.chk_method = cb_ref_value_2.ref_id INNER JOIN
                         APCSProDB.clms.cb_ref_value AS cb_ref_value_3 ON grr.chk_topic = cb_ref_value_3.ref_id ON ps.id = grr.process_id LEFT OUTER JOIN
                         APCSProDB.man.users AS users_2 ON grr.chk3_user = users_2.id LEFT OUTER JOIN
                         APCSProDB.man.users AS users_1 ON grr.chk2_user = users_1.id LEFT OUTER JOIN
                         APCSProDB.man.users as u ON grr.chk1_user = users_2.id WHERE 1=1 '

IF @year IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' And (year(grr.do_date) = @year)'

IF @eq_id IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' And (grr.eq_id = @eq_id)'

IF @chk_date IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' And (cast(grr.do_date as date)= @chk_date)'

IF @ledger_no IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' And (grr.grr_ctrled_no = @ledger_no)'

SET @ParamDefinition = '@year int
,@eq_id int
,@chk_date varchar(10)
,@ledger_no as varchar(20)'

/* Execute the Transact-SQL String with all parameter value's 
       Using sp_executesql Command */
EXECUTE sp_Executesql @SQLQuery
,@ParamDefinition
	,@year 
,@eq_id 
,@chk_date 
,@ledger_no  

IF @@ERROR <> 0
	GOTO ErrorHandler

SET NOCOUNT OFF

RETURN (0)

ErrorHandler:

RETURN (@@ERROR)

END
