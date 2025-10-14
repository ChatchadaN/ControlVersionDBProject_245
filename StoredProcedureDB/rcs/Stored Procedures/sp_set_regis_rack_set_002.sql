-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [rcs].[sp_set_regis_rack_set_002]
	-- Add the parameters for the stored procedure here
	@name VARCHAR(50) 
	, @set_list [dbo].[rcs_set_list] readonly
	, @created_by INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN TRANSACTION
	BEGIN TRY

		IF EXISTS(SELECT 1 FROM APCSProDB.rcs.rack_sets WHERE name = @name)
		BEGIN
			ROLLBACK;
			SELECT 'FALSE' AS Is_Pass 
				,'Register fail. Set Name Already Exists!!' AS Error_Message_ENG
				,N'การลงทะเบียนผิดพลาด Set Name นี้มีอยู่แล้ว !!' AS Error_Message_THA
				,N'Please check the data !!' AS Headlind
			RETURN;
		END
		ELSE
		BEGIN		
			DECLARE @set_list_tb TABLE 
			(
				[value] VARCHAR(50)
				,[value_type] INT
			)
	
			INSERT INTO @set_list_tb 
			SELECT [item],[type] FROM @set_list

			--Step 1 create rack set
			DECLARE @set_id INT

			INSERT INTO APCSProDB.rcs.rack_sets
			([name] , [created_at] ,[created_by])
			VALUES(@name ,GETDATE() ,@created_by)

			SET @set_id = SCOPE_IDENTITY()

			--Step 2 create rack set list
			--Check มี value_type = 1 มั้ย
			IF NOT EXISTS (
				SELECT 1 FROM @set_list_tb WHERE value_type = 1
			)
			BEGIN
				PRINT 'INSERT Group Device'

				-- เช็คว่ามี value_type = 3 ก่อนค่อยค้นหา device_name
				IF EXISTS (
					SELECT 1 FROM @set_list_tb WHERE value_type = 3
				)
				BEGIN
					INSERT INTO @set_list_tb 
					SELECT id, 1 FROM APCSProDB.method.device_names
					WHERE package_id IN (
						SELECT value FROM @set_list_tb WHERE value_type = 3
					)
				END

				-- Insert ข้อมูลทั้งหมดเข้า rack_set_lists
				INSERT INTO APCSProDB.rcs.rack_set_lists
				(rack_set_id,[value],value_type, [created_at] ,[created_by])
				SELECT @set_id , [value] ,[value_type] ,GETDATE() ,@created_by FROM @set_list_tb

			END
			ELSE
			BEGIN
				PRINT 'INSERT Normal'
		
				INSERT INTO APCSProDB.rcs.rack_set_lists
				(rack_set_id,[value],value_type, [created_at] ,[created_by])
				SELECT @set_id , [value] ,[value_type] ,GETDATE() ,@created_by FROM @set_list_tb
			END

			COMMIT;
			SELECT 'TRUE' AS Is_Pass 
				,'Register Successfully !!' AS Error_Message_ENG
				,N'การลงทะเบียนสำเร็จ !!' AS Error_Message_THA	
				,N'' AS Headlind			 
		END
	END TRY

	BEGIN CATCH
		ROLLBACK;
		SELECT 'FALSE' AS Is_Pass 
		,'Register fail. !!' AS Error_Message_ENG
		,N'การลงทะเบียนผิดพลาด !!' AS Error_Message_THA
		,N'Please check the data !!' AS Headlind
	END CATCH
END
