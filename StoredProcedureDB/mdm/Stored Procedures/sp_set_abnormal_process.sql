-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_set_abnormal_process]
	-- Add the parameters for the stored procedure here
	@ab_detail_name VARCHAR(MAX)
	, @process VARCHAR(MAX)
	, @created_by INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN
		INSERT INTO [APCSProDB].[trans].[abnormal_processes]
        ([abnormal_detail_id],[process_id],[created_at],[created_by])
        VALUES(@ab_detail_name, @process, GETDATE(), @created_by)
	END
END
