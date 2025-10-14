-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [rcs].[sp_set_rack_set_lists_002]
	-- Add the parameters for the stored procedure here
	@rack_set_id INT
	,@set_list [dbo].[rcs_set_list] readonly
	,@emp_no INT
	,@filter INT
	--(0 : Delete 1 : Insert)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN TRANSACTION
	BEGIN TRY

		DECLARE @set_list_tb TABLE 
		(
			[value] VARCHAR(50)
			,[value_type] INT
		)

		INSERT INTO @set_list_tb 
		SELECT [item],[type] FROM @set_list

		IF (@filter = 0)
		BEGIN
			--0 : Delete
			PRINT 'Delete'

			IF EXISTS(
				SELECT 1
				FROM APCSProDB.rcs.rack_set_lists setlist
				INNER JOIN @set_list_tb temp_sl ON setlist.value = temp_sl.value
				AND setlist.value_type = temp_sl.value_type
				WHERE rack_set_id = @rack_set_id
			)
			BEGIN
				IF EXISTS (
					SELECT 1 FROM @set_list_tb WHERE value_type = 3
				)
				BEGIN
					PRINT 'Delete all device of pk'

					--Check ว่ามี device ของ package ที่ต้องการลบมั้ย
					IF EXISTS (
						SELECT 1 FROM APCSProDB.rcs.rack_set_lists setlist
						INNER JOIN APCSProDB.method.device_names ON setlist.value = device_names.id
						WHERE setlist.rack_set_id = @rack_set_id
						AND value_type = 1
						AND package_id IN (SELECT [value] FROM @set_list_tb WHERE value_type = 3)
					)
					BEGIN
						PRINT N'ถ้ามี device ของ package ที่ต้องการลบ'

						DELETE setlist
						FROM APCSProDB.rcs.rack_set_lists setlist
						INNER JOIN APCSProDB.method.device_names ON setlist.value = device_names.id
						WHERE setlist.rack_set_id = @rack_set_id
						AND value_type = 1
						AND package_id IN (SELECT [value] FROM @set_list_tb WHERE value_type = 3)

					END

					DELETE setlist
					FROM APCSProDB.rcs.rack_set_lists setlist
					INNER JOIN @set_list_tb temp_sl ON  setlist.[value] = temp_sl.[value]
						AND setlist.value_type = temp_sl.value_type
					WHERE rack_set_id = @rack_set_id

				END
				ELSE
				BEGIN
					PRINT 'DELETE normal'

					DELETE setlist
					FROM APCSProDB.rcs.rack_set_lists setlist
					INNER JOIN @set_list_tb temp_sl ON  setlist.[value] = temp_sl.[value]
						AND setlist.value_type = temp_sl.value_type
					WHERE rack_set_id = @rack_set_id
				END

				COMMIT;
				SELECT 'TRUE' AS Is_Pass 
					,'Remove Successfully !!' AS Error_Message_ENG
					,N'	การลบข้อมูลสำเร็จ !!' AS Error_Message_THA	
					,N'' AS Headlind
				RETURN;	
			END
			ELSE
			BEGIN
				ROLLBACK;
				SELECT 'FALSE' AS Is_Pass 
					,'Remove fail. Not found data !!' AS Error_Message_ENG
					,N'การลบข้อมูลผิดพลาด ไม่พบข้อมูล!!' AS Error_Message_THA
					,N'Please check the data !!' AS Headlind
				RETURN;
			END

		END

		ELSE IF (@filter = 1)
		BEGIN
			--1 : Insert
			PRINT 'Insert'

			IF EXISTS(
				SELECT 1
				FROM APCSProDB.rcs.rack_set_lists setlist
				INNER JOIN @set_list_tb temp_sl ON setlist.[value] = temp_sl.[value]
					AND setlist.value_type = temp_sl.value_type
				WHERE rack_set_id = @rack_set_id
			)
			BEGIN
				print 'Insert fail'

				ROLLBACK;
				SELECT 'FALSE' AS Is_Pass 
					,'This set already has this value  !!' AS Error_Message_ENG
					,N'Set นี้ มีค่านี้อยู่แล้ว !!' AS Error_Message_THA
					,N'Please check the data !!' AS Headlind
				RETURN;
			END
			ELSE
			BEGIN
				--ถ้าใน @set_list_tb ไม่มี value_type = 1 ให้เข้าเงื่อนไข IF
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
					SELECT @rack_set_id , [value] ,[value_type] ,GETDATE() ,@emp_no FROM @set_list_tb
				END
				ELSE
				BEGIN
					-- มี value_type = 1 → insert แบบปกติ
					PRINT 'INSERT Normal'

					INSERT INTO APCSProDB.rcs.rack_set_lists
					(rack_set_id,[value],value_type, [created_at] ,[created_by])
					SELECT @rack_set_id , [value] ,[value_type] ,GETDATE() ,@emp_no FROM @set_list_tb
				END
				
				COMMIT;
				SELECT 'TRUE' AS Is_Pass 
						,'Add Successfully !!' AS Error_Message_ENG
						,N'	การเพิ่มข้อมูลสำเร็จ !!' AS Error_Message_THA	
						,N'' AS Headlind
				RETURN;
			END
		END

	END TRY

	BEGIN CATCH
		ROLLBACK;
		SELECT 'FALSE' AS Is_Pass 
		,ERROR_MESSAGE() AS Error_Message_ENG
		,N'Please check the data !!' AS Error_Message_THA
		,N'' AS Headlind
	END CATCH
END
