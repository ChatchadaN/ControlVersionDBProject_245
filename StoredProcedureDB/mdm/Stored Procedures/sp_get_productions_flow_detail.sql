



-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_productions_flow_detail]
	-- Add the parameters for the stored procedure here
	@id AS INT = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN
		SELECT [flow_pattern_id] 
		,[state_name]
		,[operation_name]
		,[step_no] 
		,[operation_category] 
		,[waiting_hours] 
		,[limit_time_until1] 
		,[time_limit1] 
		,[is_used] 
		,[comment_01]
		,[created_at] 
		,[created_by]
		FROM [APCSProDB].[material].[flow_details]
		WHERE (flow_pattern_id LIKE '%' AND @id = 0) OR (flow_pattern_id = @id AND @id <> 0)
	END
END