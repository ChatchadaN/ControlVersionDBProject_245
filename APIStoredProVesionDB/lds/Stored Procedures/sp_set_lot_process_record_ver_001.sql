-- =============================================
-- Author:		<Author: Yutida P.>
-- Create date: <Create Date: 6-Aug-2025 >
-- Description:	<Description: For Working Records(LSI Search Pro)>
-- =============================================
CREATE PROCEDURE [lds].[sp_set_lot_process_record_ver_001]
	@strcolumn_common varchar(max), 
	@strvalue_common nvarchar(max), 
	@strcolumn_extends varchar(max), 
	@strvalue_extends nvarchar(max), 
	@process_id int , 
	@template_name varchar(50)--, @transaction_id INT OUTPUT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	BEGIN TRANSACTION;
	BEGIN TRY

	    DECLARE @process_name nvarchar(20), @template_id int, @transaction_id int;

		SELECT @process_name = [name]
		FROM [APCSProDB].[method].[processes]
		WHERE id = @process_id

		SELECT @template_id = id FROM APCSProDWR.lds.lot_record_templates
		WHERE [name] = @template_name

		IF (ISNULL(@template_id,0) <> 0 )
		BEGIN
			DECLARE @SQLCmdCommon NVARCHAR(MAX), @SQLCmdExtends NVARCHAR(MAX);

			SET @SQLCmdCommon = ' INSERT INTO [APCSProDWR].[trans].[lot_transactions] (' + @strcolumn_common + ', created_at, [process], [lot_record_templates_id])
   							VALUES (' + @strvalue_common + ', GETDATE(), '''+ @process_name +''',@template_id); 
   							SET @transaction_id = SCOPE_IDENTITY();';

			EXEC sp_executesql @SQLCmdCommon, N'@template_id INT, @transaction_id BIGINT OUTPUT',@template_id, @transaction_id OUTPUT;

			IF ( (ISNULL(@strcolumn_extends, '') <> '') AND (ISNULL(@strvalue_extends, '') <> '') )
			BEGIN
				SET @SQLCmdExtends = 'INSERT INTO [APCSProDWR].[trans].[lot_extends] (lot_transactions_id,' + @strcolumn_extends + ', created_at)
									  VALUES (@transaction_id, ' + @strvalue_extends + ', GETDATE())';
				  
				
				EXEC sp_executesql 
					@SQLCmdExtends, 
					N'@transaction_id INT', 
					@transaction_id;

			END

			COMMIT;
			SELECT 'TRUE' AS Is_Pass, 
						   '' AS Error_Message_ENG, 
						   '' AS Error_Message_THA ,
						   '' AS Handling;

		END
		ELSE
		BEGIN
			ROLLBACK;
			SELECT  'FALSE' AS Is_Pass ,
					'Process Record Not yet registered!' AS Error_Message_ENG ,
					N'ยังไม่ได้ลงทะเบียน Process Record!' AS Error_Message_THA,
					N'Please contact ICT team (โปรดติดต่อทีม ICT).' AS Handling;

		END
	END TRY
	BEGIN CATCH
		ROLLBACK;
		SELECT  'FALSE' AS Is_Pass ,
				--'Recording fail. !!' AS Error_Message_ENG ,
				ERROR_MESSAGE() AS Error_Message_ENG ,
				N'การบันทึกผิดพลาด !!' AS Error_Message_THA,
				'' AS Handling;

	END CATCH

END
