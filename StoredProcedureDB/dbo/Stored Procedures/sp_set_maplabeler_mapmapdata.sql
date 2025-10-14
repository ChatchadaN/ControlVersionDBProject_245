-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_maplabeler_mapmapdata]
	-- Add the parameters for the stored procedure here
	@LotNo varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	UPDATE [DBx].[dbo].[MAP_MAPData]
	SET Remark = 'LotCancel'
	WHERE LotNo = @LotNo AND Process = 'OS' AND ProcessMode = 'OS_NEW'
END
