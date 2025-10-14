-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_data_lcl_from_excel]
	-- Add the parameters for the stored procedure here
	@id int = NULL
	, @device_id int
	, @job_id int
	, @box_no varchar(10)
	, @ucl decimal(18,6)
    , @avg decimal(18,6)
    , @lcl decimal(18,6)
    , @std_deviation decimal(18,6)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	IF (@id IS NULL)
	BEGIN
		-- update lcl master
		UPDATE [APCSProDB].[trans].[lcl_masters]
		SET [ucl] = @ucl
			,[avg] = @avg
			,[lcl] = @lcl
			,[std_deviation] = @std_deviation
			,[update_at] = getdate()
			,[updated_by] = 1
		WHERE [device_id] = @device_id
			AND [job_id] = @job_id
			AND [box_no] = @box_no
			AND [is_released] = 1

		-- insert lcl master records
		INSERT INTO [APCSProDB].[trans].[lcl_master_records]
		(
			[lcl_master_id]
			,[device_id]
			,[job_id]
			,[ucl]
			,[avg]
			,[lcl]
			,[std_deviation]
			,[box_no]
			,[is_auto]
			,[is_released]
			,[created_at]
			,[created_by]
			,[update_at]
			,[updated_by]
		)
		SELECT 
			[id]
			,[device_id]
			,[job_id]
			,[ucl]
			,[avg]
			,[lcl]
			,[std_deviation]
			,[box_no]
			,[is_auto]
			,[is_released]
			,[created_at]
			,[created_by]
			,[update_at]
			,[updated_by]
		FROM [APCSProDB].[trans].[lcl_masters]
		WHERE [device_id] = @device_id
			AND [job_id] = @job_id
			AND [box_no] = @box_no
			AND [is_released] = 1
	END
	ELSE BEGIN
		-- update lcl master
		UPDATE [APCSProDB].[trans].[lcl_masters]
		SET [ucl] = @ucl
			,[avg] = @avg
			,[lcl] = @lcl
			,[std_deviation] = @std_deviation
			,[update_at] = getdate()
			,[updated_by] = 1
		WHERE [lcl_masters].[id] = @id
			AND [lcl_masters].[device_id] = @device_id
			AND [lcl_masters].[job_id] = @job_id
			AND [lcl_masters].[box_no] = @box_no
			AND [lcl_masters].[is_released] = 1

		-- insert lcl master records
		INSERT INTO [APCSProDB].[trans].[lcl_master_records]
		(
			[lcl_master_id]
			,[device_id]
			,[job_id]
			,[ucl]
			,[avg]
			,[lcl]
			,[std_deviation]
			,[box_no]
			,[is_auto]
			,[is_released]
			,[created_at]
			,[created_by]
			,[update_at]
			,[updated_by]
		)
		SELECT 
			[id]
			,[device_id]
			,[job_id]
			,[ucl]
			,[avg]
			,[lcl]
			,[std_deviation]
			,[box_no]
			,[is_auto]
			,[is_released]
			,[created_at]
			,[created_by]
			,[update_at]
			,[updated_by]
		FROM [APCSProDB].[trans].[lcl_masters]
		WHERE [lcl_masters].[id] = @id
			AND [lcl_masters].[device_id] = @device_id
			AND [lcl_masters].[job_id] = @job_id
			AND [lcl_masters].[box_no] = @box_no
			AND [lcl_masters].[is_released] = 1
	END
END
