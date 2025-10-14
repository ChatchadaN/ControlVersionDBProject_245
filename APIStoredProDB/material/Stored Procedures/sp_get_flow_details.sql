-- =============================================
-- Author:		<Author, Yutida P.>
-- Create date: <Create Date, 16 July 2025>
-- Description:	<Description, Get flow patterns>
-- =============================================
CREATE PROCEDURE [material].[sp_get_flow_details]
	@flow_pattern_id INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	EXEC [APIStoredProVersionDB].[material].[sp_get_flow_details_ver_001]
			@flow_pattern_id = @flow_pattern_id


END
