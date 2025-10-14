
-- =============================================
-- Author:		<Author, Sadanun B>
-- Create date: <Create Date, 2025/07/31>
-- Description:	<Description, Get Productions>
-- =============================================
CREATE PROCEDURE [material].[sp_get_stock_in_pc]
		 @location_id			INT 
		, @production_id		INT				= 0
		, @pono					NVARCHAR(100)	= ''
		, @categories_id		INT				= 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	EXEC [APIStoredProVersionDB].[material].[sp_get_stock_in_pc_001]
		 @location_id			= @location_id	
		, @production_id		=  @production_id
		, @pono					=  @pono			
		, @categories_id		=  @categories_id

END
