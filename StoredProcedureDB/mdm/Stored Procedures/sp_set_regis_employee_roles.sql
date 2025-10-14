

-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_set_regis_employee_roles]
	-- Add the parameters for the stored procedure here
	  @emp_code		VARCHAR(10)
	, @role_id		INT
	, @created_by	INT

    
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN TRANSACTION
    BEGIN TRY

	DECLARE @emp_id int
  SELECT @emp_id = id from [DWH].[man].[employees]
  where   emp_code = @emp_code
  --select @emp_id

		IF EXISTS (SELECT  'xx' FROM  [DWH].[man].[employee_roles] WHERE [emp_id] = @emp_id AND  [role_id] = @role_id)
		BEGIN  

					SELECT	  'FALSE'		AS Is_Pass
					, 'Data Duplicate'		AS Error_Message_ENG
					, N'ข้อมูลนี้ลงทะเบียนแล้ว'		AS Error_Message_THA	
					, ''					AS Handling
					COMMIT;
					RETURN

		END 
		ELSE
		BEGIN 

			INSERT INTO [DWH].[man].[employee_roles]
			(			[emp_id]
						,[role_id]
						,[expired_on]
						,[created_at]
						,[created_by]
						
			)
			VALUES 
			(
						  @emp_id
						, @role_id
						,'9999-12-31'
						, GETDATE()
						, @created_by
			)

				 --SELECT	  'TRUE'		AS Is_Pass
					--	, 1				AS code
					--	, @role_name	AS parameter

			SELECT	  'TRUE'				AS Is_Pass
					, 'Successed !!'		AS Error_Message_ENG
					, N'บันทึกข้อมูลเรียบร้อย.'	AS Error_Message_THA	
					, ''					AS Handling

			COMMIT; 

			RETURN
	END 
	END TRY



	BEGIN CATCH
			ROLLBACK;
			SELECT	  'FALSE'				AS Is_Pass
					, 'Update Failed !!'		AS Error_Message_ENG
					, N'บันทึกข้อมูลผิดพลาด !!'	AS Error_Message_THA
					, ''					AS Handling
		END CATCH

	END
