-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_update_ocr_qc_state_ver_002]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@lot_no varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @user_id INT;
	DECLARE @lot_id INT;
	DECLARE @lot_step_no INT;
	DECLARE @lot_job_id INT;
	DECLARE @lot_marking_id INT;

	SELECT @user_id = [id]
	FROM [APCSProDB].[man].[users]
	WHERE [users].[emp_num] = @username

	SELECT @lot_id = [id]
	, @lot_step_no = [step_no]
	, @lot_job_id = [act_job_id]
	FROM [APCSProDB].[trans].[lots]
	WHERE [lots].[lot_no] = @lot_no

	IF EXISTS(SELECT [lot_marking_verify].[id]
	FROM [APCSProDB].[trans].[lot_marking_verify]
	WHERE [lot_marking_verify].[lot_id] = @lot_id
	AND [lot_marking_verify].[step_no] = @lot_step_no)
	BEGIN
		UPDATE [APCSProDB].[trans].[lot_marking_verify]
		SET [is_pass] = 0
		, [value] = NULL
		, [marking_picture_id] = NULL
		, [created_at] = GETDATE()
		, [created_by] = @user_id
		, [updated_at] = GETDATE()
		, [updated_by] = @user_id
		, [job_id] = @lot_job_id
		, [lot_process_record_id] = NULL
		, [recheck_count] = 0
		, [step_no] = @lot_step_no
		WHERE [lot_id] = @lot_id
		AND [step_no] = @lot_step_no;

		SELECT @lot_marking_id = [id]
		FROM [APCSProDB].[trans].[lot_marking_verify]
		WHERE [lot_id] = @lot_id
		AND [step_no] = @lot_step_no;

		INSERT INTO [APCSProDB].[trans].[lot_marking_verify_records]
		([lot_marking_id]
		, [lot_id]
		, [is_pass]
		, [value]
		, [marking_picture_id]
		, [created_at]
		, [created_by]
		, [updated_at]
		, [updated_by]
		, [job_id]
		, [lot_process_record_id]
		, [recheck_count]
		, [step_no])
		VALUES(@lot_marking_id
		, @lot_id
		, 0
		, NULL
		, NULL
		, GETDATE()
		, @user_id
		, GETDATE()
		, @user_id
		, @lot_job_id
		, NULL
		, 0
		, @lot_step_no);
	END
	ELSE
	BEGIN
		INSERT INTO [APCSProDB].[trans].[lot_marking_verify]
		([lot_id]
		, [is_pass]
		, [value]
		, [marking_picture_id]
		, [created_at]
		, [created_by]
		, [updated_at]
		, [updated_by]
		, [job_id]
		, [lot_process_record_id]
		, [recheck_count]
		, [step_no])
		VALUES(@lot_id
		, 0
		, NULL
		, NULL
		, GETDATE()
		, @user_id
		, GETDATE()
		, @user_id
		, @lot_job_id
		, NULL
		, 0
		, @lot_step_no);
		SELECT @lot_marking_id = SCOPE_IDENTITY();

		INSERT INTO [APCSProDB].[trans].[lot_marking_verify_records]
		([lot_marking_id]
		, [lot_id]
		, [is_pass]
		, [value]
		, [marking_picture_id]
		, [created_at]
		, [created_by]
		, [updated_at]
		, [updated_by]
		, [job_id]
		, [lot_process_record_id]
		, [recheck_count]
		, [step_no])
		VALUES(@lot_marking_id
		, @lot_id
		, 0
		, NULL
		, NULL
		, GETDATE()
		, @user_id
		, GETDATE()
		, @user_id
		, @lot_job_id
		, NULL
		, 0
		, @lot_step_no);
	END

	UPDATE [APCSProDB].[trans].[lots]
	SET [quality_state] = 10
	WHERE [lot_no] = @lot_no
	AND [quality_state] = 0
END
