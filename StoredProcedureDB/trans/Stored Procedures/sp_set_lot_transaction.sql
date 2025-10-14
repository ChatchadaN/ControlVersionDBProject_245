-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_lot_transaction]
	@strcolumn varchar(max), @strvalue nvarchar(max) , @transaction_id INT OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	BEGIN TRY

		DECLARE @SQLCmd NVARCHAR(MAX);
		SET @SQLCmd = ' INSERT INTO [APCSProDWR].[trans].[lot_transactions] (' + @strcolumn + ', created_at)
   						VALUES (' + @strvalue + ', GETDATE()); 
   						SET @transaction_id = SCOPE_IDENTITY();';

		EXEC sp_executesql @SQLCmd, N'@transaction_id BIGINT OUTPUT', @transaction_id OUTPUT;

		
		/* SELECT 'TRUE' AS Is_Pass, 
					   '' AS Error_Message_ENG, 
					   '' AS Error_Message_THA ,
					   '' AS Handling,
					   @transaction_id AS transaction_id;
					   */
	END TRY
	BEGIN CATCH
		SELECT  'FALSE' AS Is_Pass ,
				--'Recording fail. !!' AS Error_Message_ENG ,
				ERROR_MESSAGE() AS Error_Message_ENG ,
				N'การบันทึกผิดพลาด !!' AS Error_Message_THA,
				'' AS Handling

	END CATCH

END
