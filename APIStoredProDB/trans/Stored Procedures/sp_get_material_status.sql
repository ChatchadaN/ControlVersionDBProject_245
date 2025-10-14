-- =============================================
-- Author:		NUCHA
-- Create date: 2022/07/01
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_material_status]
	@barcode as VARCHAR(100),
	@material_name as VARCHAR(250) = '',
	@mc_no as VARCHAR(250),
	@lot_no as VARCHAR(10) = NULL,
	@opno AS VARCHAR(6)
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
			, 'EXEC [trans].[sp_get_material_status_005] @lot_no = ''' + ISNULL(CAST(@lot_no AS varchar),'') + ''', @barcode = ''' + ISNULL(CAST(@barcode AS varchar(100)),'') + ''', @material_name = ''' 
			+ ISNULL(CAST(@material_name AS varchar),'') +  ''', @mcno = ''' + ISNULL(CAST(@mc_no AS varchar),'') + '''' + ''', @opno = ''' 
			+ ISNULL(CAST(@opno AS varchar),'') + ''''
			,IIF(@lot_no IS NULL OR @lot_no = '' ,@barcode,@lot_no)

	---- ########## VERSION 001 ##########
	--		EXEC [APIStoredProVersionDB].trans.sp_get_material_status_001
	--			@barcode = @barcode,
	--			@material_name = @material_name,
	--			@mc_no = @mc_no,
	--			@lot_no = @lot_no,
	--			@opno = @opno
	---- ########## VERSION 001 ##########

	---- ########## VERSION 002 ##########
	--	EXEC [APIStoredProVersionDB].trans.sp_get_material_status_002
	--		@barcode = @barcode,
	--		@material_name = @material_name,
	--		@mc_no = @mc_no,
	--		@lot_no = @lot_no,
	--		@opno = @opno
	---- ########## VERSION 002 ##########

	---- ########## VERSION 003 ##########
	--EXEC [APIStoredProVersionDB].trans.sp_get_material_status_003
	--	@barcode = @barcode,
	--	@material_name = @material_name,
	--	@mc_no = @mc_no,
	--	@lot_no = @lot_no,
	--	@opno = @opno
	---- ########## VERSION 003 ##########

	--	-- ########## VERSION 004 ##########   solder 2024/05/15  14.00
	--EXEC [APIStoredProVersionDB].trans.sp_get_material_status_004
	--	@barcode = @barcode,
	--	@material_name = @material_name,
	--	@mc_no = @mc_no,
	--	@lot_no = @lot_no,
	--	@opno = @opno
	---- ########## VERSION 004 ##########


	-- ########## VERSION 005 ##########   resin new label 2025/08/18	09.00
	EXEC [APIStoredProVersionDB].trans.sp_get_material_status_005
		@barcode = @barcode,
		@material_name = @material_name,
		@mc_no = @mc_no,
		@lot_no = @lot_no,
		@opno = @opno
	-- ########## VERSION 005 ##########


END
