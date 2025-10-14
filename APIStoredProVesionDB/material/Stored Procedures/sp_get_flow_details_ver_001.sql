-- =============================================
-- Author:		<Author, Yutida P.>
-- Create date: <Create Date, 16 July 2025>
-- Description:	<Description, Get flow details>
-- =============================================
CREATE PROCEDURE [material].[sp_get_flow_details_ver_001]
	@flow_pattern_id INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT [flow_pattern_id]
		  ,[step_no]
		  ,[operation_category]
		  ,[state_name]
		  ,[operation_name]
		  ,[waiting_hours]
		  ,[limit_time_until1]
		  ,[time_limit1]
		  ,[is_used]
		  ,[created_at]
		  ,[created_by]
		  ,[updated_at]
		  ,[updated_by]
	  FROM [APCSProDB].[material].[flow_details]
	  -- WHERE ([flow_pattern_id] = @flow_pattern_id OR ISNULL(@flow_pattern_id,0) = 0)
	  WHERE [flow_pattern_id] = @flow_pattern_id
	  AND [is_used] = 1


END
