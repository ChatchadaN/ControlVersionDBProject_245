-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_get_machine_permit]
	-- Add the parameters for the stored procedure here
	@lotId as int,@mcId as int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	declare	@permitId int,@rowCount int
	

	SELECT @permitId = df.permitted_machine_id FROM [APCSProDB].[trans].[lots] AS tl with (NOLOCK)
	INNER JOIN [APCSProDB].[method].[device_flows] as df with (NOLOCK) ON (tl.device_slip_id = df.device_slip_id AND tl.step_no = df.step_no) 
	WHERE tl.id = @lotId

	if((@permitId) is NOT NULL)
	BEGIN
		SELECT @rowCount = COUNT(*) FROM [APCSProDB].[mc].[permitted_machine_machines] AS PMM with (NOLOCK) WHERE PMM.machine_id = @mcId AND PMM.permitted_machine_id = @permitId
		if(@rowCount = 1)
		BEGIN
			SELECT '1' AS Result , '' AS [Message]
		END ELSE
		BEGIN
			SELECT '9000' AS Result , 'Machine not Pass' AS [Message]
		END
	END ELSE
	BEGIN
		SELECT '0' AS Result , 'This device not have permission' AS [Message]
	END
	

END
