-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_set_ois_recipe_new_device]
	-- Add the parameters for the stored procedure here
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
    @is_higtvoltage INT,
	@newOISRecipeId INT OUTPUT,
    @device_version_id INT OUTPUT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	DECLARE @version_num INT,
			@device_version_ids INT,
			@device_type NVARCHAR(255)

	--SET @device_type = CASE
	--	WHEN @production_category IN ('30','31') THEN '1' --E Sample Products
	--	WHEN @production_category IN ('20','21','22','23') THEN '6' --D Lot
	--	WHEN @production_category = '70' THEN '7' --Recall Lot
	--	WHEN @production_category = '40' THEN '8' --F Out Source Lot
	--	ELSE '0'  --A B G Mass Products
	--END

	SET @device_type = CASE
		WHEN @production_category IN (30,31) THEN '1' --E Sample Products
		ELSE '0' --A B G Mass Products
	END

	IF @handler IS NULL OR @handler = ''
	BEGIN
    SET @handler = NULL; -- กำหนดค่า NULL ให้กับ mc_model_id ในกรณีไม่มีข้อมูลส่งมา
	END

	BEGIN
	/****** Script for SelectTopNRows command from SSMS  ******/

	SELECT @version_num = ISNULL(MAX(version_num), 0) + 1
	FROM APCSProDB.method.ois_recipe_versions
	WHERE device_id = @device_names AND job_id = @job and device_type = @device_type

	INSERT INTO APCSProDB.method.ois_recipe_versions -- เพิ่มข้อมูลใน ois_recipe_versions
		(device_id
		, job_id
		, version_num
		, device_type
		, created_at
		, created_by)
	VALUES(
		@device_names
		, @job
		, @version_num
		, @device_type
		, GETDATE()
		, @created_by)

	SELECT @device_version_ids = SCOPE_IDENTITY() -- ดึง id ois_recipe_versions ล่าสุด

	INSERT INTO APCSProDB.method.ois_recipes	-- เพิ่มข้อมูลใน ois_recipes
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
		, version_num)
	VALUES (
		@program_name
		, @device_version_ids
		, @job
		, @production_category
		, @test_time
		, @is_released
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

	    -- Set output parameters
		SET @newOISRecipeId = SCOPE_IDENTITY();
		SET @device_version_id = @device_version_ids; 

	END
END
