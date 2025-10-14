-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_lot_extended]
	@strcolumn varchar(max), @strvalue nvarchar(max), @transaction_id int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN TRANSACTION
	BEGIN TRY
		DECLARE @SQLCmd NVARCHAR(MAX);
		SET @SQLCmd = 'INSERT INTO [APCSProDWR].[trans].[lot_extended] (lot_transactions_id,' + @strcolumn + ', created_at) ' +
				  'VALUES (' + CAST(@transaction_id AS NVARCHAR) + ',' + @strvalue + ', GETDATE())'; 
		EXEC(@SQLCmd);
		COMMIT;

		SELECT 'TRUE' AS Is_Pass, 
					   '' AS Error_Message_ENG, 
					   '' AS Error_Message_THA ,
					   '' AS Handling;

	END TRY
	BEGIN CATCH
		ROLLBACK;

		SELECT  'FALSE' AS Is_Pass ,
				--'Recording fail. !!' AS Error_Message_ENG ,
				ERROR_MESSAGE() AS Error_Message_ENG ,
				N'การบันทึกผิดพลาด !!' AS Error_Message_THA,
				'' AS Handling

	END CATCH

END
