-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE dbo.sp_get_maplabeler_stripmap
	-- Add the parameters for the stored procedure here
	@LotNo varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT *
	FROM [StripMapDB].[dbo].[tbl_StripMap]
	WHERE AssyLotNo like @LotNo + '%'
END
