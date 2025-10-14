-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_set_scheduler_setup]
	-- Add the parameters for the stored procedure here
	@machine_no varchar(50)
	, @lot_no varchar(10) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	UPDATE [DBxDW].[dbo].[scheduler_temp]
	SET [seq_no] = [seq_no] - 1
	WHERE [scheduler_temp].[machine_name] = @machine_no and [scheduler_temp].[seq_no] is not null
END
