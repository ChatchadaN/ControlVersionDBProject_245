-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_scheduler_accumulate_tmp]
	---- Add the parameters for the stored procedure here
	@Month as VARCHAR(10) 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT temp.DeviceName , temp.DeviceFTName,temp.AccumulateValue,temp.Month
	FROM DBx.dbo.scheduler_accumulate_tmp as temp
	where temp.Month = @Month
END
