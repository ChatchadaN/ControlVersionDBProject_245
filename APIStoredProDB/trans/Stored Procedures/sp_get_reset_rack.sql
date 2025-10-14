-- =============================================
-- Author:		NUCHA
-- Create date: 2022/06/29
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_reset_rack] 
	-- Add the parameters for the stored procedure here
	@lot_no AS VARCHAR(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
		
	-- ########## VERSION 001 ##########
	EXEC [APIStoredProVersionDB].[trans].[sp_get_reset_rack_001] @lot_no = @lot_no
	-- ########## VERSION 001 ##########
		
END
