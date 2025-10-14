-- =============================================
-- Author:		<Author: Yutida P.>
-- Create date: <Create Date: 25-July-2025 >
-- Description:	<Description: For Working Records(LSI Search Pro)>
-- =============================================
CREATE PROCEDURE [lds].[sp_set_lot_extends_ver_002]
	@strcolumn varchar(max), @strvalue nvarchar(max), @transaction_id int, @template_name varchar(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	BEGIN TRANSACTION
	BEGIN TRY
		
		DECLARE @template_id int;

		SELECT @template_id = id FROM APCSProDWR.lds.lot_record_templates
		WHERE [name] = @template_name

		IF (ISNULL(@template_id, 0) <> 0 )
		BEGIN
			DECLARE @SQLCmd NVARCHAR(MAX);
			SET @SQLCmd = 'INSERT INTO [APCSProDWR].[trans].[lot_extends] (lot_transactions_id, lot_record_templates_id,' + @strcolumn + ', created_at) ' +
					  'VALUES (' + CAST(@transaction_id AS NVARCHAR) + ',' + CAST(@template_id AS NVARCHAR) + ',' + @strvalue + ', GETDATE())';
				  
			EXEC(@SQLCmd);
			COMMIT;

			SELECT 'TRUE' AS Is_Pass, 
						   '' AS Error_Message_ENG, 
						   '' AS Error_Message_THA ,
						   '' AS Handling;
		END
		ELSE
		BEGIN
			COMMIT;
			SELECT 'FALSE' AS Is_Pass, 
					'No template_id' AS Error_Message_ENG, 
					'ไม่มี template_id' AS Error_Message_THA ,
					'' AS Handling;
		END
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
