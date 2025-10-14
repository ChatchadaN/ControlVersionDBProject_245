-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_scheduler_ssop-b10w_matchflow]
	-- Add the parameters for the stored procedure here
	@Device AS VARCHAR(30) = null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT * FROM DBx.dbo.[scheduler_SSOP-B10W_MatchFlow] where FTDeivce = @Device
END
