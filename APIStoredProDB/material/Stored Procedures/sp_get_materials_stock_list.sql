
-- =============================================
-- Author:		NUCHA
-- Create date: 2022/07/01
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_get_materials_stock_list]

		@location_id	INT			--= 9
	  , @from_date		DATETIME    --= '2025-07-08' 
	  , @to_date		DATETIME	--= '2025-07-09'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	
	-- ########## VERSION 001 ##########  
		EXEC [APIStoredProVersionDB].[material].[sp_get_materials_stock_list_001]
		@location_id	=@location_id
		, @from_date	= @from_date	
		, @to_date		= @to_date	
		 
	-- ########## VERSION 001 ##########

END
