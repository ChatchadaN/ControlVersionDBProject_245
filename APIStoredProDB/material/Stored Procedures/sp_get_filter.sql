-- =============================================
-- Author:		<Author, Yutida P.>
-- Create date: <Create Date, 16 July 2025>
-- Description:	<Description, Get flow patterns>
-- =============================================
CREATE PROCEDURE [material].[sp_get_filter]
		@filter_no		INT		--1 : time_unit , 2 : package_unit , 3 : matl_state , 4 : process_state , 5 : material location , 6: unit (oneworld) , 7 : po data 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	EXEC [APIStoredProVersionDB].[material].[sp_get_filter_001]
			@filter_no = @filter_no
END
