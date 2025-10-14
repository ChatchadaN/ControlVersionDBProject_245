
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_trans_lots_details]	-- Add the parameters for the stored procedure here	
	@lot_no VARCHAR(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	-- ########## VERSION 001 ##########
	EXEC [APIStoredProVersionDB].[dbo].[sp_get_trans_lots_details_001] 
		@lot_no = @lot_no;
	-- ########## VERSION 001 ##########
END
