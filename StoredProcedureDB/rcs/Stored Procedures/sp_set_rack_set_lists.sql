-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [rcs].[sp_set_rack_set_lists]
	-- Add the parameters for the stored procedure here
	@rack_set_id INT
	,@value VARCHAR(50)
	,@value_type INT
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
		IF (@filter = 0)
		BEGIN
			PRINT 'Delete'

			IF EXISTS(
				SELECT 1 FROM APCSProDB.rcs.rack_set_lists
				WHERE rack_set_id = @rack_set_id 
					AND [value] = @value
					AND [value_type] = @value_type
			)
			BEGIN
				IF (@value_type = 3)
				BEGIN
					PRINT 'Delete all device of package(3)'

					--Check ว่ามี device ของ package ที่ต้องการลบมั้ย
					IF EXISTS (
					SELECT 1 FROM APCSProDB.rcs.rack_set_lists setlist
					INNER JOIN APCSProDB.method.device_names ON setlist.value = device_names.id
					WHERE setlist.rack_set_id = @rack_set_id
						AND value_type = 1
						AND package_id = @value
					)
					BEGIN
						PRINT N'ถ้ามี device ของ package ที่ต้องการลบ ลบ device ก่อน'

						DELETE setlist
						FROM APCSProDB.rcs.rack_set_lists setlist
						INNER JOIN APCSProDB.method.device_names ON setlist.value = device_names.id
						WHERE setlist.rack_set_id = @rack_set_id
							AND value_type = 1
							AND package_id = @value
					END

					PRINT N'Delete package'
					DELETE APCSProDB.rcs.rack_set_lists
					WHERE rack_set_id = @rack_set_id
						AND [value] = @value
						AND [value_type] = @value_type

				END
				ELSE
				BEGIN
					PRINT 'Delete Normal'

					DELETE APCSProDB.rcs.rack_set_lists
					WHERE rack_set_id = @rack_set_id
						AND [value] = @value
						AND [value_type] = @value_type
				END

				COMMIT;
				SELECT 'TRUE' AS Is_Pass 
					, 'Remove Successfully !!' AS Error_Message_ENG
					, N'	การลบข้อมูลสำเร็จ !!' AS Error_Message_THA	
					, N'' AS Headlind
				RETURN;	
			END
			ELSE
			BEGIN
				ROLLBACK;
				SELECT 'FALSE' AS Is_Pass 
					, 'Remove fail. Not found data !!' AS Error_Message_ENG
					, N'การลบข้อมูลผิดพลาด ไม่พบข้อมูล!!' AS Error_Message_THA
					, N'Please check the data !!' AS Headlind
				RETURN;
			END
		END

		ELSE IF (@filter = 1)
		BEGIN
			PRINT 'Insert'

			IF EXISTS (
				SELECT 1 FROM APCSProDB.rcs.rack_set_lists
				WHERE rack_set_id = @rack_set_id AND [value] = @value AND [value_type] = @value_type
			)
			BEGIN
				ROLLBACK;
				print 'Insert fail'
				SELECT 'FALSE' AS Is_Pass 
					, 'This set already has this value  !!' AS Error_Message_ENG
					, N'Set นี้ มีค่านี้อยู่แล้ว !!' AS Error_Message_THA
					, N'Please check the data !!' AS Headlind
				RETURN;
			END
			ELSE
			BEGIN
				IF (@value_type = 1 AND @value = 'All Device')
				BEGIN
					PRINT 'Condition All Device'

					-- Check package in set
					IF NOT EXISTS (
						SELECT 1
						FROM APCSProDB.rcs.rack_set_lists
						INNER JOIN APCSProDB.method.packages ON rack_set_lists.value = packages.id
						WHERE rack_set_id = @rack_set_id
						AND value_type = 3
					)
					BEGIN
						ROLLBACK;
						SELECT 'FALSE' AS Is_Pass 
							, 'Not found package in rack_set. Please check your data!!' AS Error_Message_ENG
							, N' ไม่พบข้อมูล package ใน rack_set. กรุณาตรวจสอบข้อมูล!!' AS Error_Message_THA	
							, N'' AS Headlind
						RETURN;
					END
					ELSE
					BEGIN
						IF EXISTS (				
							SELECT 1
							FROM APCSProDB.method.device_names
							INNER JOIN APCSProDB.method.packages ON device_names.package_id = packages.id
							WHERE package_id IN ( SELECT packages.id
								FROM APCSProDB.rcs.rack_set_lists
								INNER JOIN APCSProDB.method.packages ON rack_set_lists.value = packages.id
								WHERE rack_set_id = @rack_set_id
								AND value_type = 3 )
							AND device_names.id NOT IN (SELECT device_names.id
								FROM APCSProDB.rcs.rack_set_lists
								INNER JOIN APCSProDB.method.device_names ON rack_set_lists.value = device_names.id
								WHERE  rack_set_id = @rack_set_id
								AND value_type = 1)
						)
						BEGIN
							PRINT 'Insert All Device'

							INSERT INTO APCSProDB.rcs.rack_set_lists
							([rack_set_id],[value],[value_type],[created_at],[created_by])
							SELECT
								@rack_set_id AS rack_set_id
								, device_names.id AS [value]
								, 1 AS [value_type]
								, GETDATE() AS [created_at]
								, @emp_no AS [created_by]
							FROM APCSProDB.method.device_names
							INNER JOIN APCSProDB.method.packages ON device_names.package_id = packages.id
							WHERE package_id IN ( SELECT packages.id
								FROM APCSProDB.rcs.rack_set_lists
								INNER JOIN APCSProDB.method.packages ON rack_set_lists.value = packages.id
								WHERE rack_set_id = @rack_set_id
								AND value_type = 3 )
							AND device_names.id NOT IN (SELECT device_names.id
								FROM APCSProDB.rcs.rack_set_lists
								INNER JOIN APCSProDB.method.device_names ON rack_set_lists.value = device_names.id
								WHERE  rack_set_id = @rack_set_id
								AND value_type = 1)
							ORDER BY packages.name ASC
						END
						ELSE
						BEGIN
							ROLLBACK;
							SELECT 'FALSE' AS Is_Pass 
								, 'Already Add All Device !!' AS Error_Message_ENG
								, N' เพิ่มข้อมูลทุก Device แล้ว !!' AS Error_Message_THA	
								, N'' AS Headlind
							RETURN;
						END
					END
				END
				ELSE
				BEGIN
					PRINT 'Insert Normal'

					INSERT INTO APCSProDB.rcs.rack_set_lists
					([rack_set_id],[value],[value_type],[created_at],[created_by])
					VALUES
					(@rack_set_id,@value,@value_type,GETDATE(),@emp_no)
				END
		
				print 'Insert Success'
				COMMIT;
				SELECT 'TRUE' AS Is_Pass 
					, 'Add Successfully !!' AS Error_Message_ENG
					, N'	การเพิ่มข้อมูลสำเร็จ !!' AS Error_Message_THA	
					, N'' AS Headlind
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
		RETURN;
	END CATCH
END