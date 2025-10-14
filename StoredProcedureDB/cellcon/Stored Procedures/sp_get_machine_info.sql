-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE cellcon.sp_get_machine_info
	-- Add the parameters for the stored procedure here
	@MCId int = NULL,
	@MCNo varchar(20) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT *
	FROM APCSProDB.mc.machines
	WHERE id = @MCId OR name = @MCNo
END
