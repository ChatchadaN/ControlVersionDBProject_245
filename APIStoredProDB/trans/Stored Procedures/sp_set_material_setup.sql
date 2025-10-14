-- =============================================
-- Author:		NUCHA
-- Create date: 2022/07/01
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_material_setup]
	@lot_no AS VARCHAR(10)= '',
	@barcode AS VARCHAR(100),
	@opno AS VARCHAR(6),
	@mcno AS VARCHAR(20)
	--@input_qty as INT = 0
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
			, 'EXEC [trans].[sp_set_material_setup_007] @lot_no = ''' + ISNULL(CAST(@lot_no AS varchar),'') + ''', @barcode = ''' + ISNULL(CAST(@barcode AS varchar),'') + ''', @opno = ''' 
				+ ISNULL(CAST(@opno AS varchar),'') +  ''', @mcno = ''' + ISNULL(CAST(@mcno AS varchar),'') + '''' 
				--+ ''', @input_qty = ''' + ISNULL(CAST(@input_qty AS varchar),'') + ''''
			,IIF(@lot_no IS NULL OR @lot_no = '' ,@barcode,@lot_no)

	---- ########## VERSION 001 ##########
	--		EXEC [APIStoredProVersionDB].trans.sp_set_material_setup_001
	--			@lot_no = @lot_no,
	--			@barcode = @barcode,
	--			@opno = @opno,
	--			@mcno = @mcno
	--			--@input_qty = @input_qty
	---- ########## VERSION 001 ##########

	---- ########## VERSION 002 ##########
	--		EXEC [APIStoredProVersionDB].trans.sp_set_material_setup_002
	--			@lot_no = @lot_no,
	--			@barcode = @barcode,
	--			@opno = @opno,
	--			@mcno = @mcno
	--			--@input_qty = @input_qty
	---- ########## VERSION 002 ##########
 
	---- ########## VERSION 003 ##########
	--		EXEC [APIStoredProVersionDB].trans.sp_set_material_setup_003
	--			@lot_no = @lot_no,
	--			@barcode = @barcode,
	--			@opno = @opno,
	--			@mcno = @mcno
	--			--@input_qty = @input_qty
	---- ########## VERSION 003 ##########

	 ----########## VERSION 005 ##########   solder 2024/05/15 14.00
		--	EXEC [APIStoredProVersionDB].trans.sp_set_material_setup_005
		--		@lot_no = @lot_no,
		--		@barcode = @barcode,
		--		@opno = @opno,
		--		@mcno = @mcno
		--		--@input_qty = @input_qty
	 ----########## VERSION 005 ##########

	---- ########## VERSION 006 ##########   Wafer Torino 2025/06/16 11.03
	--		EXEC [APIStoredProVersionDB].trans.sp_set_material_setup_006
	--			@lot_no = @lot_no,
	--			@barcode = @barcode,
	--			@opno = @opno,
	--			@mcno = @mcno 
	---- ########## VERSION 006 ##########

		-- ########## VERSION 007 ##########   Wafer Torino 2025/08/20 15.42
			EXEC [APIStoredProVersionDB].trans.sp_set_material_setup_007
				@lot_no = @lot_no,
				@barcode = @barcode,
				@opno = @opno,
				@mcno = @mcno 
	-- ########## VERSION 007 ##########

END
