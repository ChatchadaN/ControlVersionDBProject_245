-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [clms].[sp_result_calibration_in_sup]
@req_id int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
DECLARE @SQLQuery AS NVARCHAR(4000)
	DECLARE @ParamDefinition AS NVARCHAR(2000)

    -- Insert statements for procedure here
set @SQLQuery ='SELECT       reqret.chk_id, reqchk.req_id, reqret.seq_no, reqret.chk_sch_id, reqret.chk_topic, reqret.unit, reqret.chk_point_desc, 
                         reqret.chk_desc, reqret.chk_val, reqret.std_val, reqret.min_val, reqret.max_val, reqret.chk_type, 
                         reqret.chk_val_af, reqret.chk_status
FROM            APCSProDB.clms.req_chkeq_result  as reqret RIGHT OUTER JOIN
                         APCSProDB.clms.req_chkeq as reqchk ON reqret.req_id = reqchk.req_id
WHERE        (reqchk.chk_locate = ''IN'')'

IF @req_id IS NOT NULL
	SET @SQLQuery = @SQLQuery + ' And (reqret.req_id = @req_id)'



SET @ParamDefinition = '@req_id int'

/* Execute the Transact-SQL String with all parameter value's 
       Using sp_executesql Command */
EXECUTE sp_Executesql @SQLQuery
	,@ParamDefinition
	,@req_id  

IF @@ERROR <> 0
	GOTO ErrorHandler

SET NOCOUNT OFF

RETURN (0)

ErrorHandler:

RETURN (@@ERROR)
END
