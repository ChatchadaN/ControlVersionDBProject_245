-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_set_flow_details]
	@flow_pattern_id INT = 0,
    @step_no INT = 0,
    @operation_category tinyint,
	@state_name nvarchar(30) = NULL,
	@operation_name nvarchar(30) = NULL,
    @waiting_hours INT,
    @limit_time_until1 tinyint,
    @time_limit1 INT,
    @is_used tinyint,
	@emp_code VARCHAR(6)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	EXEC [APIStoredProVersionDB].[material].[sp_set_flow_details_001]
			@flow_pattern_id = @flow_pattern_id,
			@step_no = @step_no,
			@operation_category = @operation_category,
			@state_name = @state_name,
			@operation_name = @operation_name,
			@waiting_hours = @waiting_hours,
			@limit_time_until1 = @limit_time_until1,
			@time_limit1 = @time_limit1,
			@is_used = @is_used,
			@emp_code = @emp_code	

END
