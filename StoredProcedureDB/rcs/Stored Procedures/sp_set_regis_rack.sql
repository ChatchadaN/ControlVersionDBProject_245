-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [rcs].[sp_set_regis_rack]
	-- Add the parameters for the stored procedure here
	@location_id INT --zone_id
	, @categories_id INT 
	, @rack_name VARCHAR(50) 
	, @x INT
	, @y INT
	, @z INT
	, @user_id VARCHAR(10)
	, @is_fifo INT
	, @is_type_control INT = 0

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SET @user_id = CAST(@user_id AS INT)

	DECLARE @rack_control_id INT

	DECLARE @ix		INT = 1
			, @iy	INT = 1
			, @iz	INT = 1;

	IF EXISTS ( SELECT 1 FROM APCSProDB.rcs.rack_controls
	INNER JOIN APCSProDB.trans.locations ON rack_controls.location_id = locations.id
	WHERE rack_controls.[name] = @rack_name and category = @categories_id AND location_id = @location_id)
	BEGIN
		SELECT 'FALSE' AS Is_Pass
		,'ERROR: This RackName already exists !!' AS Error_Message_ENG
		,N'ERROR: RackName นี้มีอยู่แล้ว !!' AS Error_Message_THA
		RETURN;
	END

    -- Insert statements for procedure here
	BEGIN TRANSACTION
	BEGIN TRY
		-- Regis Rack_controls --
		INSERT INTO APCSProDB.rcs.rack_controls
		(
			[name]
			,[category]
			,[priority]
			,[leadtime]
			,[is_enable]
			,[created_at]
			,[created_by]
			,[updated_at]
			,[updated_by]
			,[location_id]
			,[is_fifo]
			,[is_type_control]
		)
		VALUES
		(
			@rack_name
			,@categories_id
			,0
			,NULL
			,1
			,GETDATE()
			,@user_id
			,NULL
			,NULL
			,@location_id
			,@is_fifo
			,@is_type_control
		)

		-- ดึง id @rack_control_id ล่าสุด
		SELECT @rack_control_id = SCOPE_IDENTITY() 

		---- Regis trans.location_racks --
		--INSERT INTO APCSProDB.trans.location_racks
		--(
		--	[location_id]
		--	,[rack_control_id]
		--	,[created_at]
		--	,[created_by]
		--	,[updated_at]
		--	,[updated_by]
		--)
		--VALUES
		--(
		--	@location_id
		--	,@rack_control_id
		--	,GETDATE()
		--	,@user_id
		--	,NULL
		--	,NULL
		--)
		
		-- Regis rack_address --
		IF @x > 12
		BEGIN
			ROLLBACK;
			SELECT 'FALSE' AS Is_Pass
			,'ERROR: @x should not be greater than 12 !!' AS Error_Message_ENG
			,N'ERROR: @x ควรน้อยกว่า 12!!' AS Error_Message_THA
			RETURN
		END
		ELSE
		BEGIN
			WHILE @ix <= @x
			BEGIN    
				WHILE @iy <= @y
				BEGIN
					WHILE @iz <= @z
					BEGIN
						INSERT INTO APCSProDB.rcs.rack_addresses
						(
							[rack_control_id]
							,[item]
							,[status]
							,[address]
							,[x]
							,[y]
							,[z]
							,[is_enable]
							,[created_at]
							,[created_by]
							,[updated_at]
							,[updated_by]
						)
						VALUES
						(
							@rack_control_id
							,NULL
							,0
							,NCHAR(64 + @ix) + FORMAT(@iy,'00') + FORMAT(@iz,'00')
							,NCHAR(64 + @ix)
							,CAST(@iy AS VARCHAR(10))
							,CAST(@iz AS VARCHAR(10))
							,1
							,GETDATE()
							,@user_id
							,NULL
							,NULL
						)

						SET @iz = @iz + 1
					END
					SET @iz = 1
					SET @iy = @iy + 1
				END
				SET @iy = 1
				SET @ix = @ix + 1
			END
		END

		COMMIT; 
		SELECT 'TRUE' AS Is_Pass 
		,'Register Successfully !!' AS Error_Message_ENG
		,N'การลงทะเบียนสำเร็จ !!' AS Error_Message_THA		
		
	END TRY

	BEGIN CATCH
		ROLLBACK;
		SELECT 'FALSE' AS Is_Pass 
		,'Register fail. !!' AS Error_Message_ENG
		,N'การลงทะเบียนผิดพลาด !!' AS Error_Message_THA
	END CATCH
END
