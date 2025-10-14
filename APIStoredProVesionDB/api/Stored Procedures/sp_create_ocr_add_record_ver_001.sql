-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_create_ocr_add_record_ver_001]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@lot_no varchar(10)
	,	@mark varchar(MAX)
	,	@image varchar(MAX)
	,	@is_pass int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @user_id INT;
	DECLARE @lot_id INT;
	DECLARE @image_id INT;
	DECLARE @lot_marking_id INT;

	SELECT @user_id = [id]
	FROM [APCSProDB].[man].[users]
	WHERE [users].[emp_num] = @username

	SELECT @lot_id = [id]
	FROM [APCSProDB].[trans].[lots]
	WHERE [lots].[lot_no] = @lot_no

	INSERT INTO [APCSProDBFile].[ocr].[lot_marking_verify_picure]
	([picture_data]
	, [created_at]
	, [created_by]
	, [updated_at]
	, [updated_by])
	VALUES
	(CAST(N'' AS xml).value('xs:base64Binary(sql:variable("@image"))', 'varbinary(max)')
	, GETDATE()
	, @user_id
	, GETDATE()
	, @user_id);
	SELECT @image_id = SCOPE_IDENTITY();

	INSERT INTO [APCSProDB].[trans].[lot_marking_verify]
    ([lot_id]
	, [is_pass]
	, [value]
	, [marking_picture_id]
	, [created_at]
	, [created_by]
	, [updated_at]
	, [updated_by])
	VALUES(@lot_id
	, @is_pass
	, @mark
	, @image_id
	, GETDATE()
	, @user_id
	, GETDATE()
	, @user_id);
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
	, [updated_by])
	VALUES(@lot_marking_id
	, @lot_id
	, @is_pass
	, @mark
	, @image_id
	, GETDATE()
	, @user_id
	, GETDATE()
	, @user_id);

	UPDATE [APCSProDB].[trans].[lots]
	SET [quality_state] = 0
	WHERE [lot_no] = @lot_no
	AND [quality_state] = 10;
END
