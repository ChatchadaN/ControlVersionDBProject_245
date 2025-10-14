-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_rcs_records_excel]
	-- Add the parameters for the stored procedure here
	@start_date	varchar(16)
	,@end_date	varchar(16)
	,@rackName	varchar(5)
	,@pkg		varchar(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	EXEC [dbo].[sp_get_rcs_records_excel_ver002]
	@start_date		= @start_date
	,@end_date		= @end_date
	,@rackName		= @rackName
	,@pkg			= @pkg

END
