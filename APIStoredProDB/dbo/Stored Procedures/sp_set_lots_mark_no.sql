
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_lots_mark_no]	-- Add the parameters for the stored procedure here	
	@lot_no VARCHAR(10)
	, @mark_no VARCHAR(50)
    , @is_update INT  -- 0:INSERT, 1:UPDATE
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	-- ########## VERSION 001 ##########
	EXEC [APIStoredProVersionDB].[dbo].[sp_set_lots_mark_no_001] 
		@lot_no = @lot_no
		, @mark_no = @mark_no
		, @is_update = @is_update;
	-- ########## VERSION 001 ##########
END
