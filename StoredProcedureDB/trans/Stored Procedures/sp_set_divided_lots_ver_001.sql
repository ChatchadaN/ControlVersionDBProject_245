-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,Update Call Table Interface to Is Server 2023/02/02 time : 11.24 ,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_divided_lots_ver_001]
	-- Add the parameters for the stored procedure here
	@lot_no VARCHAR(10),
	@type_action INT --1: insert ,2: update create text ,3: update send text
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @lot_id INT

	IF (@type_action = 1)
	BEGIN
		SELECT CAST([lots].[lot_no] AS VARCHAR(10)) AS [lot_no]
		FROM [APCSProDWH].[atom].[divided_lots]
		INNER JOIN [APCSProDB].[trans].[lots]
			ON [divided_lots].[lot_id] = [lots].[id]
		WHERE [divided_lots].[is_create_text] = 0;
	END
	ELSE IF (@type_action = 2)
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
	ELSE IF (@type_action = 3)
	BEGIN
		SET @lot_id = (SELECT [id] FROM [APCSProDB].[trans].[lots] WHERE [lot_no] = @lot_no);

		IF (@lot_id IS NOT NULL)
		BEGIN
			UPDATE [APCSProDWH].[atom].[divided_lots]
			SET [divided_lots].[is_send_text] = 1
				, [updated_at] = GETDATE()
				, [updated_by] = 1339
			WHERE [lot_id] = @lot_id;
		END
	END
END
