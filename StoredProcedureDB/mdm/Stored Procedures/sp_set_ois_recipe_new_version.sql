-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_set_ois_recipe_new_version]
	-- Add the parameters for the stored procedure here
	@ois_recipe_id INT,
	@program_name NVARCHAR(255),
    @device_names NVARCHAR(255),
    @job NVARCHAR(255),
    @production_category NVARCHAR(255),
    @test_time NVARCHAR(255),
    @is_released INT,
    @created_by NVARCHAR(255),
    @comment NVARCHAR(255),
    @revision_reason NVARCHAR(255),
    @tp_type NVARCHAR(255),
    @tube_type NVARCHAR(255),
    @pattern NVARCHAR(255),
    @handler NVARCHAR(255),
    @is_higtvoltage INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SET @is_released = 0;

    -- Insert statements for procedure here
	DECLARE @version_num INT,
			@device_version_id INT,
			@device_recipe_newid INT,
			@device_type NVARCHAR(255)

	SET @device_type = CASE
		WHEN @production_category IN (30,31)  THEN '1' --E Sample Products
		ELSE '0' --A B G Mass Products
	END

	BEGIN
	/****** Script for SelectTopNRows command from SSMS  ******/

	-- ตรวจสอบ version device_id และ job_id 
	SELECT @version_num = ISNULL(MAX(version_num), 0) + 1
	FROM APCSProDB.method.ois_recipe_versions
	WHERE device_id = @device_names AND job_id = @job and device_type = @device_type

	-- อัปเดต version at ois_recipe_versions
    UPDATE APCSProDB.method.ois_recipe_versions
	SET version_num = @version_num,
		updated_at = GETDATE(),
		updated_by = @created_by
	WHERE device_id = @device_names AND job_id = @job AND device_type = @device_type

	---- อัปเดต is_released เป็น 0 สำหรับทุก version
	--UPDATE APCSProDB.method.ois_recipes
	--SET is_released = 0,
	--    updated_at = GETDATE(),
	--	updated_by = @created_by
	--WHERE device_version_id IN (
	--	SELECT id
	--	FROM APCSProDB.method.ois_recipe_versions
	--	WHERE device_id = @device_names AND job_id = @job
	--)
	--AND is_released = 1;

	SELECT @device_version_id = id
	FROM APCSProDB.method.ois_recipe_versions
	WHERE device_id = @device_names AND job_id = @job AND device_type = @device_type

	INSERT INTO APCSProDB.method.ois_recipes -- เพิ่มข้อมูลใน ois_recipes
		(program_name
		, device_version_id
		, job_id
		, production_category
		, test_time
		, is_released
		, created_at
		, created_by
		, comment
		, revision_reason
		, tp_type
		, tube_type
		, pattern
		, mc_model_id
		, is_highvoltage
		,version_num)
	VALUES (
		@program_name
		, @device_version_id
		, @job
		, @production_category
		, @test_time, @is_released
		, GETDATE()
		, @created_by
		, @comment
		, @revision_reason
		, @tp_type
		, @tube_type
		, @pattern
		, @handler
		, @is_higtvoltage
		, @version_num)

	SELECT @device_recipe_newid = SCOPE_IDENTITY() -- ดึง id ois_recipe ล่าสุด

	INSERT INTO APCSProDB.method.ois_recipe_details
	(ois_recipe_id,jig_production_id,unit,unit_type)
	SELECT 
		@device_recipe_newid AS ois_recipe_id,
		jig_production_id,
		unit,
		unit_type
	FROM APCSProDB.method.ois_recipe_details
	WHERE ois_recipe_id = @ois_recipe_id

	--UPDATE APCSProDB.method.ois_recipe_details -- อัปเดตคอลัมน์ ois_recipe_id ในตาราง ois_recipe_details
	--SET ois_recipe_id = @device_recipe_newid
	--WHERE ois_recipe_id = @ois_recipe_id

	--UPDATE APCSProDB.method.ois_set_lists -- อัปเดตคอลัมน์ ois_recipe_id ในตาราง ois_set_lists
	--SET ois_recipe_id = @device_recipe_newid
	--WHERE ois_recipe_id = @ois_recipe_id

	SELECT SCOPE_IDENTITY();

	END
END
