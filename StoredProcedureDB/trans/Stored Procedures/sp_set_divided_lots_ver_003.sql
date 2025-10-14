
CREATE PROCEDURE [trans].[sp_set_divided_lots_ver_003]
	-- Add the parameters for the stored procedure here
	@lot_no VARCHAR(10),
	@type_action INT, --1: update create text , 2: update send text, 3: update send text (error)
	@comment VARCHAR(100) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @lot_id INT
	
	IF (@type_action = 1)
	BEGIN
		SET @lot_id = (SELECT [id] FROM [APCSProDB].[trans].[lots] WHERE [lot_no] = @lot_no);

		IF (@lot_id IS NOT NULL)
		BEGIN
			UPDATE [APCSProDWH].[atom].[divided_lots]
			SET [divided_lots].[is_create_text] = 1
				, [updated_at] = GETDATE()
				, [updated_by] = 1339
			WHERE [lot_id] = @lot_id;
		END
	END
	ELSE IF (@type_action = 2)
	BEGIN
		SET @lot_id = (SELECT [id] FROM [APCSProDB].[trans].[lots] WHERE [lot_no] = @lot_no);

		IF (@lot_id IS NOT NULL)
		BEGIN
			UPDATE [APCSProDWH].[atom].[divided_lots]
			SET [divided_lots].[is_send_text] = 1
				, [comment] = @comment
				, [updated_at] = GETDATE()
				, [updated_by] = 1339
			WHERE [lot_id] = @lot_id;
		END
	END
	ELSE IF (@type_action = 3)
	BEGIN
		SET @lot_id = (SELECT [id] FROM [APCSProDB].[trans].[lots] WHERE [lot_no] = @lot_no);

		IF (@lot_id IS NOT NULL)
		BEGIN
			UPDATE [APCSProDWH].[atom].[divided_lots]
			SET [comment] = @comment
				, [updated_at] = GETDATE()
				, [updated_by] = 1339
			WHERE [lot_id] = @lot_id;
		END
	END
END
