-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [rcs].[sp_set_rack_address_resize]
	-- Add the parameters for the stored procedure here
	@rack_id INT
	, @x INT
	, @y INT
	, @z INT
	, @user_id VARCHAR(10)

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SET @user_id = CAST(@user_id AS INT)

	DECLARE @ix		INT = 1
			, @iy	INT = 1
			, @iz	INT = 1;

	DECLARE @old_x INT
		
	SELECT @old_x = COUNT(DISTINCT x)
	FROM APCSProDB.rcs.rack_addresses
	WHERE rack_control_id = @rack_id

    -- Insert statements for procedure here
	BEGIN TRANSACTION
	BEGIN TRY
		
		IF ( @old_x + @x ) >= 12
		BEGIN
			SELECT 'FALSE' AS Is_Pass
			, 'ERROR: @x should not be greater than 12 !!' AS Error_Message_ENG
			, N'ERROR: @x ควรน้อยกว่า 12!!' AS Error_Message_THA
			, N'กรุณาติดต่อ System' AS [Handling];
			RETURN;
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
							@rack_id
							,NULL
							,0
							,NCHAR(64 + @old_x + @ix) + FORMAT(@iy,'00') + FORMAT(@iz,'00')
							,NCHAR(64 + @old_x + @ix)
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

			SELECT 'TRUE' AS Is_Pass 
			, 'Register Successfully !!' AS Error_Message_ENG
			, N'การลงทะเบียนสำเร็จ !!' AS Error_Message_THA		
			, N'' AS [Handling];
			COMMIT;
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
