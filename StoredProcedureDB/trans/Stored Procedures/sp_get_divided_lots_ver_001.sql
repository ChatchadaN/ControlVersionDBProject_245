-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,Update Call Table Interface to Is Server 2023/02/02 time : 11.24 ,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_divided_lots_ver_001]
	-- Add the parameters for the stored procedure here
	@type_check INT --1: get create_text ,2: get update send rohm
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF (@type_check = 1)
	BEGIN
		SELECT CAST([lots].[lot_no] AS VARCHAR(10)) AS [lot_no]
		FROM [APCSProDWH].[atom].[divided_lots]
		INNER JOIN [APCSProDB].[trans].[lots]
			ON [divided_lots].[lot_id] = [lots].[id]
		WHERE [divided_lots].[is_create_text] = 0;
	END
	IF (@type_check = 2)
	BEGIN
		SELECT CAST([lots].[lot_no] AS VARCHAR(10)) AS [lot_no]
		FROM [APCSProDWH].[atom].[divided_lots]
		INNER JOIN [APCSProDB].[trans].[lots]
			ON [divided_lots].[lot_id] = [lots].[id]
		WHERE [divided_lots].[is_create_text] = 1
			AND [divided_lots].[is_send_text] = 0;
	END
END
