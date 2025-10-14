-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_scheduler_tp_setup_mc] 
	-- Add the parameters for the stored procedure here
	@pkg_id as int = 1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT *
	FROM DBx.dbo.scheduler_tp_qa_mc_setup
	WHERE is_gdic = @pkg_id
END
