-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,Update Call Table Interface to Is Server 2023/02/02 time : 11.24 ,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_divided_lot_by_task]
	-- Add the parameters for the stored procedure here
	@type_action INT --1: insert ,2: update
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF (@type_action = 1)
	BEGIN
		DECLARE @lot_divide TABLE
		(
			LOT_NO NCHAR(10),
			DATE_TIMESTAMP DATETIME,
			FLAG NCHAR(1)
		)

		----# check insert
		IF EXISTS(
			SELECT TOP 1 [lots].[lot_no]
			FROM [APCSProDB].[trans].[lots]
			INNER JOIN [APCSProDWH].[atom].[divided_lots] ON [divided_lots].[lot_id] = [lots].[id]
			LEFT JOIN [ISDB].[DBLSISHT].[dbo].[LOT_DIVIDE] ON [lots].[lot_no] COLLATE SQL_Latin1_General_CP1_CI_AS = [LOT_DIVIDE].[LOT_NO] COLLATE SQL_Latin1_General_CP1_CI_AS
			WHERE [LOT_DIVIDE].[LOT_NO] IS NULL
		)
		BEGIN
			----# (1) insert to @lot_divide
			INSERT INTO @lot_divide
				( LOT_NO
				, DATE_TIMESTAMP
				, FLAG )
			SELECT CAST([lots].[lot_no] AS NCHAR(10)) AS [LOT_NO]
				, GETDATE() AS [DATE_TIMESTAMP]
				, '0' AS FLAG
			FROM [APCSProDB].[trans].[lots]
			INNER JOIN [APCSProDWH].[atom].[divided_lots] ON [divided_lots].[lot_id] = [lots].[id]
			LEFT JOIN [ISDB].[DBLSISHT].[dbo].[LOT_DIVIDE] ON [lots].[lot_no] COLLATE SQL_Latin1_General_CP1_CI_AS = [LOT_DIVIDE].[LOT_NO] COLLATE SQL_Latin1_General_CP1_CI_AS
			WHERE [LOT_DIVIDE].[LOT_NO] IS NULL;

			----# (2) insert to [DBLSISHT].[dbo].[LOT_DIVIDE]
			IF EXISTS(SELECT COUNT(LOT_NO) FROM @lot_divide)
			BEGIN
				INSERT INTO [ISDB].[DBLSISHT].[dbo].[LOT_DIVIDE]
					( LOT_NO
					, DATE_TIMESTAMP
					, FLAG )
				SELECT LOT_NO
					, DATE_TIMESTAMP
					, FLAG 
				FROM @lot_divide;
			END
		END

		----# check update state lot
		IF EXISTS(
			SELECT TOP 1 [lots].[lot_no]
			FROM [APCSProDWH].[atom].[divided_lots]
			INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = [divided_lots].[lot_id]
			INNER JOIN [ISDB].[DBLSISHT].[dbo].[LOT_DIVIDE] ON [lots].[lot_no] COLLATE SQL_Latin1_General_CP1_CI_AS = [LOT_DIVIDE].[LOT_NO] COLLATE SQL_Latin1_General_CP1_CI_AS
			WHERE ([divided_lots].[is_create_text] = 0
				OR [divided_lots].[is_send_text] != [LOT_DIVIDE].[FLAG])
		)
		BEGIN
			UPDATE [divided_lots]
			SET [divided_lots].[is_create_text] = 1
				, [divided_lots].[is_send_text] = IIF([LOT_DIVIDE].[FLAG] = 1,1,0)
			FROM [APCSProDWH].[atom].[divided_lots]
			INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = [divided_lots].[lot_id]
			INNER JOIN [ISDB].[DBLSISHT].[dbo].[LOT_DIVIDE] ON [lots].[lot_no] COLLATE SQL_Latin1_General_CP1_CI_AS = [LOT_DIVIDE].[LOT_NO] COLLATE SQL_Latin1_General_CP1_CI_AS
			WHERE ([divided_lots].[is_create_text] = 0
				OR [divided_lots].[is_send_text] != [LOT_DIVIDE].[FLAG]);
		END
	END
	ELSE IF (@type_action = 2)
	BEGIN 
		----# check update state lot
		IF EXISTS(
			SELECT TOP 1 [lots].[lot_no]
			FROM [APCSProDWH].[atom].[divided_lots]
			INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = [divided_lots].[lot_id]
			INNER JOIN [ISDB].[DBLSISHT].[dbo].[LOT_DIVIDE] ON [lots].[lot_no] COLLATE SQL_Latin1_General_CP1_CI_AS = [LOT_DIVIDE].[LOT_NO] COLLATE SQL_Latin1_General_CP1_CI_AS
			WHERE ([divided_lots].[is_create_text] = 0
				OR [divided_lots].[is_send_text] != [LOT_DIVIDE].[FLAG])
		)
		BEGIN
			UPDATE [divided_lots]
			SET [divided_lots].[is_create_text] = 1
				, [divided_lots].[is_send_text] = IIF([LOT_DIVIDE].[FLAG] = 1,1,0)
			FROM [APCSProDWH].[atom].[divided_lots]
			INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = [divided_lots].[lot_id]
			INNER JOIN [ISDB].[DBLSISHT].[dbo].[LOT_DIVIDE] ON [lots].[lot_no] COLLATE SQL_Latin1_General_CP1_CI_AS = [LOT_DIVIDE].[LOT_NO] COLLATE SQL_Latin1_General_CP1_CI_AS
			WHERE ([divided_lots].[is_create_text] = 0
				OR [divided_lots].[is_send_text] != [LOT_DIVIDE].[FLAG]);
		END
	END
END
