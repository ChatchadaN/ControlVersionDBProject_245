-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [clms].[sp_check_sheet]
	/* Input Parameters */
	@eq_num varchar(50)
	,@eq_id int
	,@ctr_sec_id int 
	,@use_sec_id int
AS

BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @SQLQuery AS NVARCHAR(4000)
	DECLARE @ParamDefinition AS NVARCHAR(2000)

    -- Insert statements for procedure here
set @SQLQuery ='SELECT   sht.sheet_id,eq.eq_id, eq.eq_name, eq.eq_num, sec.name AS ctr_section, sections_1.name AS use_section, 
                         CAST(sht.check_date AS date) AS check_date, YEAR(sht.check_date) AS check_year, sht.is_bend, sht.is_rust, 
                         sht.is_chipped, sht.is_distorted, sht.is_lost_shape, sht.is_broken, sht.remark, 
                         sht.result, u.name AS checker
FROM            APCSProDB.man.users as u INNER JOIN
                         APCSProDB.clms.cb_equip as eq INNER JOIN
                         APCSProDB.clms.check_sheet sht ON eq.eq_id = sht.eq_id ON u.id = sht.checker_id LEFT OUTER JOIN
                         APCSProDB.man.sections as sec ON sht.ctr_sec_id = sec.id LEFT OUTER JOIN
                         APCSProDB.man.sections AS sections_1 ON sht.use_sec_id = sections_1.id WHERE 1=1'

IF @eq_num IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' And (eq.eq_num = @eq_num)'

IF @eq_id IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' And (eq.eq_id = @eq_id)'

IF @ctr_sec_id IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' And (sht.ctr_sec_id = @ctr_sec_id)'

IF @use_sec_id IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' And (sht.use_sec_id = @use_sec_id)'

SET @ParamDefinition = '@eq_num varchar(50)
	,@eq_id int
	,@ctr_sec_id int 
	,@use_sec_id int'

/* Execute the Transact-SQL String with all parameter value's 
       Using sp_executesql Command */
EXECUTE sp_Executesql @SQLQuery
	,@ParamDefinition
	,@eq_num 
	,@eq_id 
	,@ctr_sec_id  
	,@use_sec_id 

IF @@ERROR <> 0
	GOTO ErrorHandler

SET NOCOUNT OFF

RETURN (0)

ErrorHandler:

RETURN (@@ERROR)

END
