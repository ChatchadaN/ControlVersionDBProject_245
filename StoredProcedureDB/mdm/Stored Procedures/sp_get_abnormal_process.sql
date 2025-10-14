-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_abnormal_process]
	-- Add the parameters for the stored procedure here
	@abnormal_detail_id int = 0
	,@process_id int = 0

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SET @abnormal_detail_id = CASE WHEN  @abnormal_detail_id = 0 THEN NULL ELSE @abnormal_detail_id END  
	SET @process_id = CASE WHEN  @process_id = 0 THEN NULL ELSE @process_id  END  

    -- Insert statements for procedure here
	BEGIN
		SELECT [abnormal_detail_id]
		  ,_abdt.name as abnormal_detail
		  ,[process_id]
		  ,_pc.name AS processes
		  ,_abpc.[created_at]
		  ,[user2].[emp_num] AS created_by
		  ,_abpc.[updated_at]
		  ,[user1].[emp_num] AS updated_by
		FROM [APCSProDB].[trans].[abnormal_processes] AS _abpc
		INNER JOIN APCSProDB.trans.abnormal_detail AS _abdt ON _abdt.id = _abpc.abnormal_detail_id
		LEFT JOIN [APCSProDB].[man].[users]  AS user1 ON _abpc.[updated_by] = [user1].[id]
		LEFT JOIN [APCSProDB].[man].[users]  AS user2 ON _abpc.[created_by] = [user2].[id] 
		INNER JOIN APCSProDB.method.processes AS _pc ON _pc.id = _abpc.process_id
		WHERE (_abpc.[abnormal_detail_id] =  @abnormal_detail_id  OR  @abnormal_detail_id  IS NULL )
		AND ( _abpc.[process_id] = @process_id  OR @process_id  IS NULL )
	END
END
