-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [rcs].[sp_set_is_enable_rack_address]
	-- Add the parameters for the stored procedure here
	  @rack_id		INT
	 ,@updated_by	INT

	 ,@x			CHAR(1)	
	 ,@y            INT		
	 ,@z            INT	-- จำนวนช่องที่ต้องการใช้

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
		, 'EXEC [rcs].[sp_set_is_enable_rack_address] @rack_id  = ''' + ISNULL(CAST(@rack_id AS nvarchar(MAX)),'') 
			+ ''',@updated_by = ''' + ISNULL(CAST(@updated_by AS nvarchar(MAX)),'') +  
			+ ''',@x = ''' + ISNULL(CAST(@x AS nvarchar(MAX)),'') +
			+ ''',@y = ''' + ISNULL(CAST(@y AS nvarchar(MAX)),'') +
			+ ''',@z = ''' + ISNULL(CAST(@z AS nvarchar(MAX)),'') +
			''''
		, ISNULL(CAST(@rack_id AS nvarchar(MAX)),'')

    -- Insert statements for procedure here
	BEGIN TRANSACTION
	BEGIN TRY
		-- ตรวจสอบว่ามี item อยู่ใน rack หรือไม่
		IF EXISTS (
			SELECT item 
			FROM APCSProDB.rcs.rack_addresses
			WHERE rack_control_id = @rack_id 
				AND x = @x
				AND y = @y
				AND item IS NOT NULL
		)
		BEGIN
			Print 'Clear item'

			ROLLBACK;
			SELECT 'FALSE' AS [Is_Pass] 
				, 'Items found on the rack! Please clear all items on rack first.' AS Error_Message_ENG
				, N'กรุณาเคลียร์ item บน rack ก่อน !!' AS Error_Message_THA
				, N'กรุณาติดต่อ System' AS [Handling] 
			RETURN;
		END
		
		-- นับจำนวนช่องที่เปิดอยู่ และจำนวนช่องทั้งหมด
		DECLARE @Current_z INT, @total_z INT;

		SELECT @Current_z = COUNT(id)
		FROM APCSProDB.rcs.rack_addresses
		WHERE rack_control_id = @rack_id
			AND x = @x
			AND y = @y
			AND is_enable = 1;

		SELECT @total_z = COUNT(id)
		FROM APCSProDB.rcs.rack_addresses
		WHERE rack_control_id = @rack_id
			AND x = @x
			AND y = @y;

		-- กรณีไม่ต้องอัปเดต
		IF @z = @Current_z
		BEGIN
			PRINT N'จำนวนช่องที่ต้องการเท่ากับช่องที่เปิดอยู่ ไม่มีการเปลี่ยนแปลง';

			ROLLBACK;
			SELECT 
				'FALSE' AS Is_Pass
				, 'No update needed.' AS Error_Message_ENG
				, N'ไม่จำเป็นต้องอัปเดตช่อง' AS Error_Message_THA
				, N'' AS Headlind
			RETURN;
		END

		-- กรณีต้องเปิดช่องเพิ่ม
		IF @z > @Current_z
		BEGIN
			IF @z > @total_z
			BEGIN
				PRINT N'จำนวนช่องที่ต้องการมากกว่าจำนวนช่องทั้งหมด';

				ROLLBACK;
				SELECT 
					'FALSE' AS Is_Pass
					, 'Requested slots exceed total available slots.' AS Error_Message_ENG
					, N'จำนวนช่องที่ต้องการมากกว่าจำนวนช่องทั้งหมด' AS Error_Message_THA
					, N'' AS Headlind
				RETURN;
			END

			-- เปิดช่องเพิ่ม	
			UPDATE A
			SET is_enable = 1
			FROM (
				SELECT TOP (@z - @Current_z) *
				FROM APCSProDB.rcs.rack_addresses
				WHERE rack_control_id = @rack_id
					AND x = @x
					AND y = @y
					AND is_enable = 0
				ORDER BY z ASC
			) AS A;

			PRINT N'เปิดช่องเพิ่มเติมเรียบร้อยแล้ว';

			COMMIT;
			SELECT 
				'TRUE' AS Is_Pass  
				, 'Slots enabled successfully.' AS Message_ENG
				, N'เปิดช่องเพิ่มเติมเรียบร้อยแล้ว' AS Message_THA
				, N'' AS Headlind
			RETURN;
		END

		-- กรณีต้องปิดช่อง
		IF @z < @Current_z
		BEGIN
			-- ปิดช่อง
			UPDATE A
			SET is_enable = 0
			FROM (
				SELECT TOP (@Current_z - @z) *
				FROM APCSProDB.rcs.rack_addresses
				WHERE rack_control_id = @rack_id
					AND x = @x
					AND y = @y
					AND is_enable = 1
				ORDER BY z DESC
			) AS A;

			PRINT N'ปิดช่องเรียบร้อยแล้ว';

			COMMIT;
			SELECT 
				'TRUE' AS Is_Pass
				, 'Slots disabled successfully.' AS Message_ENG
				, N'ปิดช่องเรียบร้อยแล้ว' AS Message_THA
				, N'' AS Headlind
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
