-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [rcs].[sp_set_edit_rack_and_resize]
	-- Add the parameters for the stored procedure here
	  @rack_id			INT	
	, @updated_by		INT = NULL

	-- Edit Rack --
	, @new_rack_name		VARCHAR(50)	= NULL
	, @new_location_id		INT			= NULL
	, @new_categories_id	INT			= NULL
	, @new_is_enable		INT			= NULL
	, @new_is_fifo			INT			= NULL
	, @new_is_type_control	INT			= NULL

	-- Edit size --
	, @new_x INT = NULL
	, @new_y INT = NULL
	, @new_z INT = NULL

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	   ([record_at]
	  , [record_class]
	  , [login_name]
	  , [hostname]
	  , [appname]
	  , [command_text]
	  , [lot_no])
	SELECT GETDATE()
		,'4' --1 Insert,2 Update,3 Delete,4 StoredProcedure
		,ORIGINAL_LOGIN()
		,HOST_NAME()
		,APP_NAME()
		, 'EXEC [rcs].[sp_set_edit_rack_and_resize] @@rack_id  = ''' + ISNULL(CAST(@rack_id AS nvarchar(MAX)),'') 
			+ ''',@updated_by = ''' + ISNULL(CAST(@updated_by AS nvarchar(MAX)),'') +  
			+ ''',@new_rack_name = ''' + ISNULL(CAST(@new_rack_name AS nvarchar(MAX)),'') + 
			+ ''',@new_location_id = ''' + ISNULL(CAST(@new_location_id AS nvarchar(MAX)),'') +
			+ ''',@new_categories_id = ''' + ISNULL(CAST(@new_categories_id AS nvarchar(MAX)),'') +
			+ ''',@new_is_enable = ''' + ISNULL(CAST(@new_is_enable AS nvarchar(MAX)),'') +
			+ ''',@new_is_fifo = ''' + ISNULL(CAST(@new_is_fifo AS nvarchar(MAX)),'') +
			+ ''',@new_is_type_control = ''' + ISNULL(CAST(@new_is_type_control AS nvarchar(MAX)),'') +

			+ ''',@new_x = ''' + ISNULL(CAST(@new_x AS nvarchar(MAX)),'') +
			+ ''',@new_y = ''' + ISNULL(CAST(@new_y AS nvarchar(MAX)),'') +
			+ ''',@new_z = ''' + ISNULL(CAST(@new_z AS nvarchar(MAX)),'') +
			''''
		, ISNULL(CAST(@rack_id AS nvarchar(MAX)),'')

    -- Insert statements for procedure here
	BEGIN TRANSACTION
	BEGIN TRY		
		IF EXISTS( SELECT 1 FROM APCSProDB.rcs.rack_controls WHERE id = @rack_id)
		BEGIN
			-- * Noted : การเปลี่ยน rack ทั้งหมด rack นั้นจะต้องไม่มี item อยู่บน rack * --
			IF EXISTS ( 
				SELECT item FROM APCSProDB.rcs.rack_addresses 
				WHERE rack_control_id = @rack_id 
				AND item IS NOT NULL 
			)
			BEGIN	
				PRINT N'พบ item บน rack clear data'

				ROLLBACK;
				SELECT 'FALSE' AS Is_Pass 		
					, 'Items found on the rack! Please clear all items on rack first.' AS Error_Message_ENG		
					, N'พบ item บน rack. กรุณาเคลียร์ item ทั้งหมดบน rack ก่อน !!' AS Error_Message_THA	
					, N'' AS Headlind
				RETURN;
			END

			-- ดึงข้อมูล rack เดิม
			DECLARE 
				@old_name VARCHAR(50),
				@old_location_id INT,
				@old_categories_id INT,
				@old_is_enable INT,
				@old_is_fifo INT,
				@old_is_type_control INT

			SELECT 
				@old_name = name,
				@old_location_id = location_id,
				@old_categories_id = category,
				@old_is_enable = is_enable,
				@old_is_fifo = is_fifo,
				@old_is_type_control = is_type_control
			FROM APCSProDB.rcs.rack_controls
			WHERE id = @rack_id;

			DECLARE @old_x_String VARCHAR(10)
			, @old_x INT
			, @old_y INT
			, @old_z INT;

			SELECT 
				@old_x_String = MAX(x),
				@old_x = ASCII(MAX(x)) - ASCII('A') + 1,
				@old_y = MAX(CAST(Y AS INT)),
				@old_z = MAX(CAST(Z AS INT))
			FROM APCSProDB.rcs.rack_addresses
			WHERE rack_control_id = @rack_id
			AND is_enable = 1;

			-- check rack change data
			IF (
				(@new_rack_name IS NULL OR @new_rack_name = @old_name) AND
				(@new_location_id IS NULL OR @new_location_id = @old_location_id) AND
				(@new_categories_id IS NULL OR @new_categories_id = @old_categories_id) AND
				(@new_is_enable IS NULL OR @new_is_enable = @old_is_enable) AND
				(@new_is_fifo IS NULL OR @new_is_fifo = @old_is_fifo) AND
				(@new_is_type_control IS NULL OR @new_is_type_control = @old_is_type_control) AND
				(@new_x IS NULL OR @new_x = @old_x) AND
				(@new_y IS NULL OR @new_y = @old_y) AND
				(@new_z IS NULL OR @new_z = @old_z)
			)
			BEGIN
				PRINT N'ไม่มีการเปลี่ยนแปลง'
				ROLLBACK;
				SELECT 'FALSE' AS Is_Pass 
					, 'Rack Not Change.' AS Error_Message_ENG
					, N'Rack ไม่มีการเปลี่ยนแปลง กรุณาตรวจสอบข้อมูล !!' AS Error_Message_THA
					, N'' AS Headlind
				RETURN;
			END

			-------------------------------------------------------------------------------------------------------------------
			-- ! UPDATE RACK ! --

			-- UPDATE เฉพาะ field ที่มีค่าใหม่และแตกต่างจากของเดิม
			IF @new_rack_name IS NOT NULL AND @new_rack_name <> @old_name
			BEGIN
				PRINT 'UPDATE RACK NAME'

				DECLARE @check_location_id INT = ISNULL(@new_location_id, @old_location_id);			
				IF EXISTS (
					SELECT 1 
					FROM APCSProDB.rcs.rack_controls 
					WHERE name = @new_rack_name 
					AND location_id = @check_location_id 
				)
				BEGIN
					SELECT 'FALSE' AS Is_Pass 
						,'Rack Name Duplicate !!' AS Error_Message_ENG
						,N'ชื่อ Rack ซ้ำ กรุณาตรวจสอบข้อมูล !!' AS Error_Message_THA
						,N'Please check the data !!' AS Headlind
					RETURN;
				END
				ELSE
				BEGIN
					UPDATE APCSProDB.rcs.rack_controls
					SET name = @new_rack_name,
						updated_by = @updated_by,
						updated_at = GETDATE()
					WHERE id = @rack_id;
				END
			END

			IF @new_location_id IS NOT NULL AND @new_location_id <> @old_location_id
			BEGIN
				PRINT 'UPDATE location_id'

				UPDATE APCSProDB.rcs.rack_controls
				SET location_id = @new_location_id,
					updated_by = @updated_by,
					updated_at = GETDATE()
				WHERE id = @rack_id;

			END

			IF @new_categories_id IS NOT NULL AND @new_categories_id <> @old_categories_id
			BEGIN
				PRINT 'UPDATE categories_id'

				UPDATE APCSProDB.rcs.rack_controls
				SET category = @new_categories_id,
					updated_by = @updated_by,
					updated_at = GETDATE()
				WHERE id = @rack_id;

			END

			IF @new_is_enable IS NOT NULL AND @new_is_enable <> @old_is_enable
			BEGIN
				PRINT 'UPDATE is_enable'

				UPDATE APCSProDB.rcs.rack_controls
				SET is_enable = @new_is_enable,
					updated_by = @updated_by,
					updated_at = GETDATE()
				WHERE id = @rack_id;

				--UPDATE APCSProDB.rcs.rack_addresses
				--SET is_enable = @new_is_enable,
				--	updated_by = @updated_by,
				--	updated_at = GETDATE()
				--WHERE rack_control_id = @rack_id;

			END

			IF @new_is_fifo IS NOT NULL AND @new_is_fifo <> @old_is_fifo
			BEGIN
				PRINT 'UPDATE is_fifo'

				UPDATE APCSProDB.rcs.rack_controls
				SET is_fifo = @new_is_fifo,
					updated_by = @updated_by,
					updated_at = GETDATE()
				WHERE id = @rack_id;

			END

			IF @new_is_type_control IS NOT NULL AND @new_is_type_control <> @old_is_type_control
			BEGIN
				PRINT 'UPDATE is_fifo'

				UPDATE APCSProDB.rcs.rack_controls
				SET is_type_control = @new_is_type_control,
					updated_by = @updated_by,
					updated_at = GETDATE()
				WHERE id = @rack_id;

			END

			-------------------------------------------------------------------------------------------------------------------
			-- ! UPDATE SIZE RACK ! --

			-- ตรวจสอบว่ามีการเปลี่ยนขนาด rack หรือไม่
			IF (
				@new_x IS NOT NULL AND @new_x <> @old_x OR
				@new_y IS NOT NULL AND @new_y <> @old_y OR
				@new_z IS NOT NULL AND @new_z <> @old_z
			)
			BEGIN
				PRINT N'เงื่อนไขการ resize';
				-- TODO: เพิ่ม logic resize rack ที่นี่

				-- Enable disabled positions within new dimensions
				UPDATE APCSProDB.rcs.rack_addresses
				SET is_enable = 1
				WHERE rack_control_id = @rack_id
				  AND ASCII(x) - ASCII('A') + 1 <= @new_x
				  AND y <= @new_y
				  AND z <= @new_z
				  AND is_enable = 0;

				DECLARE @ix INT, @iy INT, @iz INT;
				DECLARE @x CHAR(1), @x_char CHAR(1), @y INT;
				DECLARE @is_enable INT;

				-- Resize X
				IF @new_x > @old_x
				BEGIN
					SET @ix = @old_x + 1;
					WHILE @ix <= @new_x
					BEGIN
						SET @x_char = CHAR(64 + @ix);
						SET @iy  = 1;
						WHILE @iy <= @old_y
						BEGIN
							SET @iz  = 1;
							WHILE @iz <= @old_z
							BEGIN
								INSERT INTO APCSProDB.rcs.rack_addresses
								(rack_control_id, item, status, address, x, y, z, is_enable, created_at, created_by)
								VALUES
								(@rack_id, NULL, 0, @x_char + FORMAT(@iy,'00') + FORMAT(@iz,'00'), @x_char, @iy, @iz, 1, GETDATE(), @updated_by);
								SET @iz += 1;
							END
							SET @iy += 1;
						END
						SET @ix += 1;
					END
				END
				ELSE IF @new_x < @old_x
				BEGIN
					UPDATE APCSProDB.rcs.rack_addresses
					SET is_enable = 0
					WHERE rack_control_id = @rack_id AND ASCII(x) - ASCII('A') + 1 > @new_x;
				END

				-- Resize Y
				IF @new_y > @old_y
				BEGIN
					SET @iy  = @old_y + 1;
					WHILE @iy <= @new_y
					BEGIN
						DECLARE x_cursor CURSOR FOR SELECT DISTINCT x FROM APCSProDB.rcs.rack_addresses WHERE rack_control_id = @rack_id;
						OPEN x_cursor;

						FETCH NEXT FROM x_cursor INTO @x;
						WHILE @@FETCH_STATUS = 0
						BEGIN
							SET @iz  = 1;
							WHILE @iz <= @old_z
							BEGIN
								DECLARE @is_x_disabled INT;
								SELECT @is_x_disabled = CASE 
									WHEN COUNT(*) = SUM(CASE WHEN is_enable = 0 THEN 1 ELSE 0 END) THEN 1
									ELSE 0 END
								FROM APCSProDB.rcs.rack_addresses
								WHERE rack_control_id = @rack_id AND x = @x;

								SET @is_enable  = CASE WHEN @is_x_disabled = 1 THEN 0 ELSE 1 END;

								INSERT INTO APCSProDB.rcs.rack_addresses
								(rack_control_id, item, status, address, x, y, z, is_enable, created_at, created_by)
								VALUES
								(@rack_id, NULL, 0, @x + FORMAT(@iy,'00') + FORMAT(@iz,'00'), @x, @iy, @iz, @is_enable, GETDATE(), @updated_by);
								SET @iz += 1;
							END
							FETCH NEXT FROM x_cursor INTO @x;
						END
						CLOSE x_cursor;
						DEALLOCATE x_cursor;
						SET @iy += 1;
					END
				END
				ELSE IF @new_y < @old_y
				BEGIN
					UPDATE APCSProDB.rcs.rack_addresses
					SET is_enable = 0
					WHERE rack_control_id = @rack_id AND y > @new_y;
				END

				-- Resize Z
				IF @new_z > @old_z
				BEGIN
					SET @iz = @old_z + 1;
					WHILE @iz <= @new_z
					BEGIN
						DECLARE xy_cursor CURSOR FOR SELECT DISTINCT x, y FROM APCSProDB.rcs.rack_addresses WHERE rack_control_id = @rack_id;
						OPEN xy_cursor;

						FETCH NEXT FROM xy_cursor INTO @x, @y;
						WHILE @@FETCH_STATUS = 0
						BEGIN
							DECLARE @is_xy_disabled INT;
							SELECT @is_xy_disabled = CASE 
								WHEN COUNT(*) = SUM(CASE WHEN is_enable = 0 THEN 1 ELSE 0 END) THEN 1
								ELSE 0 END
							FROM APCSProDB.rcs.rack_addresses
							WHERE rack_control_id = @rack_id AND x = @x AND y = @y;

							SET @is_enable = CASE WHEN @is_xy_disabled = 1 THEN 0 ELSE 1 END;

							INSERT INTO APCSProDB.rcs.rack_addresses
							(rack_control_id, item, status, address, x, y, z, is_enable, created_at, created_by)
							VALUES
							(@rack_id, NULL, 0, @x + FORMAT(@y,'00') + FORMAT(@iz,'00'), @x, @y, @iz, @is_enable, GETDATE(), @updated_by);
							FETCH NEXT FROM xy_cursor INTO @x, @y;
						END
						CLOSE xy_cursor;
						DEALLOCATE xy_cursor;
						SET @iz += 1;
					END
				END
				ELSE IF @new_z < @old_z
				BEGIN
					UPDATE APCSProDB.rcs.rack_addresses
					SET is_enable = 0
					WHERE rack_control_id = @rack_id AND z > @new_z;
				END
			END

			COMMIT;
			SELECT 'TRUE' AS Is_Pass 
				,'Update Data Successfully !!' AS Error_Message_ENG
				,N'	การอัพเดทข้อมูลสำเร็จ !!' AS Error_Message_THA	
				,N'' AS Headlind
		END
		ELSE
		BEGIN
			ROLLBACK;
			SELECT 'FALSE' AS Is_Pass 
				,'Not found data !!' AS Error_Message_ENG
				,N'ไม่พบข้อมูล!!' AS Error_Message_THA
				,N'Please check the data !!' AS Headlind
			RETURN;
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
