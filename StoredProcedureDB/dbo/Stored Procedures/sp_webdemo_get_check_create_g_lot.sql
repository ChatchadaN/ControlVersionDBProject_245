-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_webdemo_get_check_create_g_lot]
	-- Add the parameters for the stored procedure here
	@original_lotno atom.trans_lots READONLY,
	@state INT --0: check 1: get qty
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF (@state = 0)
	BEGIN
		---- # check lot in trans.lots
		IF EXISTS (
			SELECT [OldLotTable].[lot_no] 
			FROM @original_lotno AS [OldLotTable]
			LEFT JOIN [APCSProDB].[trans].[lots] ON [OldLotTable].[lot_no] = [lots].[lot_no]
			WHERE [lots].[lot_no] IS NULL
		)
		BEGIN
			DECLARE @lot_error1 VARCHAR(MAX)
			SET @lot_error1 = STUFF(( 
					SELECT CONCAT(',', [OldLotTable].[lot_no])
					FROM @original_lotno AS [OldLotTable]
					LEFT JOIN [APCSProDB].[trans].[lots] ON [OldLotTable].[lot_no] = [lots].[lot_no]
					WHERE [lots].[lot_no] IS NULL FOR XML PATH ('')
				), 1, 1, '');

			SELECT 'FALSE' AS [Is_Pass] 
				, 'Lot ' + @lot_error1 + ' not data in trans.lots !!' AS [Error_Message_ENG]
				, N'Lot ' + @lot_error1 + N' ไม่มีข้อมูลใน trans.lots !!' AS [Error_Message_THA] 
				, N'' AS [Handling];
			RETURN;
		END

		---- # check used lot
		IF EXISTS (
			SELECT [OldLotTable].[lot_no] 
			FROM @original_lotno AS [OldLotTable]
			INNER JOIN [APCSProDB].[trans].[lots] ON [OldLotTable].[lot_no] = [lots].[lot_no]
			INNER JOIN [APCSProDB].[trans].[lot_combine] ON [lots].[id] = [lot_combine].[member_lot_id]
		)
		BEGIN
			DECLARE @lot_error VARCHAR(MAX)
			SET @lot_error = STUFF(( 
					SELECT CONCAT(',', [OldLotTable].[lot_no])
					FROM @original_lotno AS [OldLotTable]
					INNER JOIN [APCSProDB].[trans].[lots] ON [OldLotTable].[lot_no] = [lots].[lot_no]
					INNER JOIN [APCSProDB].[trans].[lot_combine] ON [lots].[id] = [lot_combine].[member_lot_id]
					GROUP BY [OldLotTable].[lot_no] FOR XML PATH ('')
				), 1, 1, '');

			SELECT 'FALSE' AS [Is_Pass] 
				, 'Lot ' + @lot_error + ' has been used !!' AS [Error_Message_ENG]
				, N'Lot ' + @lot_error + N' ถูกใช้งานแล้ว !!' AS [Error_Message_THA] 
				, N'' AS [Handling];
			RETURN;
		END

		---- # check type lot
		IF EXISTS (
			SELECT [lot_no]
			FROM @original_lotno
			WHERE SUBSTRING([lot_no], 5, 1) != 'G'
		)
		BEGIN
			SELECT 'FALSE' AS [Is_Pass] 
				, 'Mixing can only be done with G lot !!' AS [Error_Message_ENG]
				, N'Mixing ได้เฉพาะ G lot !!' AS [Error_Message_THA] 
				, N'' AS [Handling];
			RETURN;
		END

		---- # check package
		IF EXISTS (
			SELECT [packages].[name]
			FROM @original_lotno AS [OldLotTable]
			INNER JOIN [APCSProDB].[trans].[lots] ON [OldLotTable].[lot_no] = [lots].[lot_no]
			INNER JOIN [APCSProDB].[method].[packages] ON [lots].[act_package_id] = [packages].[id]
			WHERE [packages].[name] != 'SSOP-C38W'
		)
		BEGIN
			SELECT 'FALSE' AS [Is_Pass] 
				, 'Mixing can only be done with SSOP-C38W !!' AS [Error_Message_ENG]
				, N'Mixing ได้เฉพาะ SSOP-C38W !!' AS [Error_Message_THA] 
				, N'' AS [Handling];
			RETURN;
		END

		---- # check device
		IF ((
			SELECT COUNT([id])
			FROM (
				SELECT [device_names].[id]
				FROM @original_lotno AS [OldLotTable]
				INNER JOIN [APCSProDB].[trans].[lots] ON [OldLotTable].[lot_no] = [lots].[lot_no]
				INNER JOIN [APCSProDB].[method].[device_names] ON [lots].[act_device_name_id] = [device_names].[id]
				GROUP BY [device_names].[id]
			) AS [count]
		) > 1)
		BEGIN
			SELECT 'FALSE' AS [Is_Pass] 
				, 'divice different !!' AS [Error_Message_ENG]
				, N'divice แตกต่างกัน !!' AS [Error_Message_THA] 
				, N'' AS [Handling];
			RETURN;
		END

		---- # check device
		IF ((SELECT COUNT([lot_no]) FROM @original_lotno) > 10)
		BEGIN
			SELECT 'FALSE' AS [Is_Pass] 
				, 'More than 10 lots !!' AS [Error_Message_ENG]
				, N'เกิน 10 lot !!' AS [Error_Message_THA] 
				, N'' AS [Handling];
			RETURN;
		END

		---- # success
		SELECT 'TRUE' AS [Is_Pass] 
			, 'The information is correct.' AS [Error_Message_ENG]
			, N'ข้อมูลถูกต้อง' AS [Error_Message_THA] 
			, N'' AS [Handling];
		RETURN;
	END
	ELSE IF (@state = 1)
	BEGIN
		SELECT CAST([lots].[lot_no] AS VARCHAR(10)) AS [lot_no], ISNULL([lots].[qty_pass], 0) AS [qty]
		FROM @original_lotno AS [OldLotTable]
		INNER JOIN [APCSProDB].[trans].[lots] ON [OldLotTable].[lot_no] = [lots].[lot_no];
	END
END
