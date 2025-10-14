-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_Leadtime]
	-- Add the parameters for the stored procedure here
	@id as int 
	,@leadtime as decimal(9,1)
	,@Is_SameValue as int = 1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

     --Insert statements for procedure here
	IF(@Is_SameValue = 0) --same
	BEGIN
		UPDATE APCSProDWH.wip_control.monitoring_items
		SET 
		 alarm_value = @leadtime
		, target_value = @leadtime
		, warn_value = @leadtime
		, updated_at = (SELECT GETDATE())
		, updated_by = 1271
		WHERE id = @id
	END
	ELSE
	BEGIN
		UPDATE APCSProDWH.wip_control.monitoring_items
		SET 
		 alarm_value = @leadtime
		, updated_at = (SELECT GETDATE())
		, updated_by = 1271
		WHERE id = @id
	END
END
