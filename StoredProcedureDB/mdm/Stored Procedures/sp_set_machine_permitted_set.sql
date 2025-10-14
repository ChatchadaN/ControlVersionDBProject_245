-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_set_machine_permitted_set]
	-- Add the parameters for the stored procedure here
	@name AS VARCHAR(250),
	@symbol_mc_id AS INT = NULL,
	@created_by AS INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	DECLARE @lastest_id_num AS INT = 0
	SET @lastest_id_num = (SELECT id + 1 FROM APCSProDB.mc.numbers WHERE [name] = 'permitted_machines.id')
	
	BEGIN TRANSACTION
	BEGIN TRY

		INSERT INTO [APCSProDB].[mc].[permitted_machines]
			([id]
			,[name] 
			,[symbol_machine_id] 
			,created_at 
			,created_by)
        VALUES
			(@lastest_id_num
			, @name
			, @symbol_mc_id
			, GETDATE()
			, @created_by)


		DECLARE @r AS INT
				set @r = @@ROWCOUNT
				UPDATE APCSProDB.mc.numbers
				SET  id = id + @r
				WHERE name = 'permitted_machines.id'

		SELECT 'TRUE' AS Is_Pass ,'Register Success !!' AS Error_Message_ENG,N'บันทึกสำเร็จ' AS Error_Message_THA		
		COMMIT; 
	END TRY

	BEGIN CATCH
		ROLLBACK;
		SELECT 'FALSE' AS Is_Pass ,'Register fail !!' AS Error_Message_ENG,N'การลงทะเบียนผิดพลาด !!' AS Error_Message_THA
	END CATCH
END
