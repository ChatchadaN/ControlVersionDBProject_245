-- =============================================
-- Author:		NUCHA
-- Create date: 2022/07/01
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_material_outoffmachine]
	@barcode as VARCHAR(100),
	@opno AS VARCHAR(6),
	@mcno AS VARCHAR(20),
	@is_outoffstock AS INT = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

		INSERT INTO APIStoredProDB.[dbo].[exec_sp_history]
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
			, 'EXEC [trans].[sp_set_material_outoffmachine_002] @barcode = ''' + ISNULL(CAST(@barcode AS varchar),'') + ''', @opno = ''' + ISNULL(CAST(@opno AS varchar),'') 
			+ ''', @mcno = ''' + ISNULL(CAST(@mcno AS varchar),'') + ''', @is_outoffstock = ''' + ISNULL(CAST(@is_outoffstock AS varchar),'') + '''' 
			,@barcode

	---- ########## VERSION 001 ##########
	--		EXEC [APIStoredProVersionDB].trans.sp_set_material_outoffmachine_001
	--				@barcode = @barcode,
	--				@opno = @opno,
	--				@mcno = @mcno,
	--				@is_outoffstock = @is_outoffstock
	---- ########## VERSION 001 ##########

	----	-- ########## VERSION 002 ##########
	--		EXEC [APIStoredProVersionDB].trans.sp_set_material_outoffmachine_002
	--				@barcode = @barcode,
	--				@opno = @opno,
	--				@mcno = @mcno,
	--				@is_outoffstock = @is_outoffstock
	------ ########## VERSION 002 ##########

	
		-- ########## VERSION 003 ##########  2025-07-10  11.06

			EXEC [APIStoredProVersionDB].trans.sp_set_material_outoffmachine_003
					@barcode = @barcode,
					@opno = @opno,
					@mcno = @mcno,
					@is_outoffstock = @is_outoffstock
	 --########## VERSION 003 ##########
END

