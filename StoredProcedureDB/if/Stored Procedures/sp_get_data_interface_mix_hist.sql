-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [if].[sp_get_data_interface_mix_hist]
	-- Add the parameters for the stored procedure here
	--@FromDate DATETIME,
	--@ToDate DATETIME
	@FromDate VARCHAR(20),
	@ToDate VARCHAR(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	EXEC [StoredProcedureDB].[if].[sp_get_data_interface_mix_hist_003]
		@FromDate = @FromDate,
		@ToDate = @ToDate
END
