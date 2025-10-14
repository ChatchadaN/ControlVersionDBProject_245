-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_set_abnormal_detail_process]
	-- Add the parameters for the stored procedure here
	@name VARCHAR(MAX)
	, @is_disable INT
	, @abnormal_mode_id INT
	, @created_by VARCHAR(MAX)
	, @process INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @abnomal_details_id INT

    -- Insert statements for procedure here
	BEGIN
	
		IF(@process = 0)
		BEGIN
			INSERT INTO [APCSProDB].[trans].[abnormal_detail]
			([name]
			,[is_disable]
			,[abnormal_mode_id]
			,[created_at]
			,[created_by])
			VALUES (
			@name
			, @is_disable
			, @abnormal_mode_id
			, GETDATE()
			, @created_by
			)
		END
		ELSE
		BEGIN
			INSERT INTO [APCSProDB].[trans].[abnormal_detail]
			([name]
			,[is_disable]
			,[abnormal_mode_id]
			,[created_at]
			,[created_by])
			VALUES (
			@name
			, @is_disable
			, @abnormal_mode_id
			, GETDATE()
			, @created_by
			)
	
			SELECT @abnomal_details_id = SCOPE_IDENTITY() 

			INSERT INTO [APCSProDB].[trans].[abnormal_processes]
			([abnormal_detail_id]
			, [process_id]
			, [created_at]
			, [created_by])
			VALUES(
			@abnomal_details_id
			, @process
			, GETDATE()
			, @created_by)

		END

	END
END
