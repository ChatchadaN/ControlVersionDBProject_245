-- =============================================
-- Author:		<Author: Yutida P.>
-- Create date: <Create Date: 25-July-2025 >
-- Description:	<Description: For Working Records(LSI Search Pro)>
-- =============================================
CREATE PROCEDURE [lds].[sp_set_lot_transaction_ver_001]
	@strcolumn varchar(max), @strvalue nvarchar(max), @process_id int, @transaction_id INT OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	BEGIN TRY
		-- Get Process Name
	    DECLARE @process_name nvarchar(20);
		SELECT @process_name = [name]
		FROM [APCSProDB].[method].[processes]
		WHERE id = @process_id

		-- Insert data
		DECLARE @SQLCmd NVARCHAR(MAX);
		SET @SQLCmd = ' INSERT INTO [APCSProDWR].[trans].[lot_transactions] (' + @strcolumn + ', created_at, [process])
   						VALUES (' + @strvalue + ', GETDATE(), '''+ @process_name +'''); 
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
