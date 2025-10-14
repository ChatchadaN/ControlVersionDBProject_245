-- =============================================
-- Author:		<Author, Sadanan B.>
-- Create date: <Create Date, 30 09 2025>
-- Description:	<Description, Get flow patterns>
-- =============================================
CREATE PROCEDURE [material].[sp_set_pickup_repack]

		  @barcode				VARCHAR(50)
		, @quantity				INT  
		, @pack_size			INT 
		, @emp_id				INT			= 1
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	EXEC [APIStoredProVersionDB].[material].[sp_set_pickup_repack_001]
			  @barcode		= @barcode	
			, @quantity		= @quantity	
			, @pack_size	= @pack_size
			, @emp_id		= @emp_id





END
