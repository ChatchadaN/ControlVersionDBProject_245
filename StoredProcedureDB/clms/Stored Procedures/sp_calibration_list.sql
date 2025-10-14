-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [clms].[sp_calibration_list]
@req_date varchar(10),
@req_sec_id int,
@chk_user_id int,
@ctr_user_id int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @SQLQuery AS NVARCHAR(4000)
	DECLARE @ParamDefinition AS NVARCHAR(2000)
    -- Insert statements for procedure here
	set @SQLQuery ='SELECT        reqchk.req_id,convert(varchar(6),reqchk.req_date,112 ) year_month, reqchk.req_topic, eq.eq_name, eq.eq_num, eq.eq_num_old, eq.mc_no, 
                         eq.location_use, APCSProDB.clms.cb_ref_value.ref_desc AS model, eq.prod_no, eq.next_chk_date, eq.last_chk_date, 
                         CAST(reqchk.req_date AS date) AS req_date, reqchk.cb_date as chk_finish_date, users_3.name AS ctr_user, users_1.name AS chk_user, users_2.name AS resp_chk_user, 
                         users_4.name AS resp_main_user, CAST(reqchk.ctr_date AS date) AS ctr_date, CAST(reqchk.chk_date AS date) AS chk_date, 
                         CAST(reqchk.resp_chk_date AS date) AS resp_chk_date, CAST(reqchk.resp_main_date AS date) AS resp_main_date,
						 div.name as div, dept.name as dept,sec.name as sec, sections_1.name as use_sec ,sections_2.name as chk_sec,eq.regis_date
FROM            APCSProDB.man.sections AS sec RIGHT OUTER JOIN
                         APCSProDB.man.departments AS dept RIGHT OUTER JOIN
                         APCSProDB.man.sections AS sections_1 RIGHT OUTER JOIN
                         APCSProDB.clms.req_chkeq AS reqchk INNER JOIN
                         APCSProDB.clms.cb_equip AS eq ON reqchk.eq_id = eq.eq_id INNER JOIN
                         APCSProDB.clms.cb_ref_value ON eq.qe_model_id = APCSProDB.clms.cb_ref_value.ref_id LEFT OUTER JOIN
                         APCSProDB.man.users ON reqchk.ctr_user = APCSProDB.man.users.id LEFT OUTER JOIN
                         APCSProDB.man.users AS users_1 ON reqchk.chk_user = users_1.id LEFT OUTER JOIN
                         APCSProDB.man.users AS users_3 ON reqchk.ctr_user = users_3.id LEFT OUTER JOIN
						 APCSProDB.man.users AS users_4 ON reqchk.resp_main_user = users_4.id LEFT OUTER JOIN
                         APCSProDB.man.users AS users_2 ON reqchk.resp_chk_user = users_2.id ON sections_1.id = reqchk.use_sec_id LEFT OUTER JOIN
                         APCSProDB.man.divisions AS div ON reqchk.req_div_id = div.id ON dept.id = reqchk.req_dept_id ON sec.id = reqchk.req_sec_id LEFT OUTER JOIN
                         APCSProDB.man.sections AS sections_2 ON reqchk.chk_sec_id = sections_2.id where 1=1 '

IF @req_date IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' And (cast(reqchk.req_date as date) = @req_date)'

IF @req_sec_id IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' And (reqchk.req_sec_id = @req_sec_id)'

IF @chk_user_id IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' And (reqchk.chk_user = @chk_user_id)'

IF @ctr_user_id IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' And (reqchk.ctr_user = @ctr_user_id)'

SET @ParamDefinition = '@req_date varchar(10),
@req_sec_id int,
@chk_user_id int,
@ctr_user_id int'

/* Execute the Transact-SQL String with all parameter value's 
       Using sp_executesql Command */
EXECUTE sp_Executesql @SQLQuery
	,@ParamDefinition
	,@req_date ,
@req_sec_id ,
@chk_user_id ,
@ctr_user_id  

IF @@ERROR <> 0
	GOTO ErrorHandler

SET NOCOUNT OFF

RETURN (0)

ErrorHandler:

RETURN (@@ERROR)
						
END
