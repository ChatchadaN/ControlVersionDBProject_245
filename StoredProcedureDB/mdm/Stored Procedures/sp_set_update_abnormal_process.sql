-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_set_update_abnormal_process]
	-- Add the parameters for the stored procedure here
	@abnormal_detail_id INT
	, @process_id INT


AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN
		DELETE [APCSProDB].[trans].[abnormal_processes]
        WHERE [abnormal_detail_id] = @abnormal_detail_id AND [process_id] = @process_id
	END
END
