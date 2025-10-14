-- =============================================
-- Author:		NUCHA
-- Create date: 2022/07/01
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_material_endlot]
	@lot_no AS VARCHAR(10),
	@barcode AS VARCHAR(100),
	@opno AS VARCHAR(6),
	@mcno AS VARCHAR(20),
	@qty AS DECIMAL(18,6) = 0
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
			, 'EXEC [trans].[sp_set_material_endlot_002] @lot_no = ''' + ISNULL(CAST(@lot_no AS varchar),'') + ''', @barcode = ''' + ISNULL(CAST(@barcode AS varchar(100)),'') + ''', @opno = ''' 
				+ ISNULL(CAST(@opno AS varchar),'') +  ''', @mcno = ''' + ISNULL(CAST(@mcno AS varchar),'') + '''' + ''', @qty = ''' + ISNULL(CAST(@qty AS varchar),'') + ''''
			, @barcode

	---- ########## VERSION 001 ##########
	--		EXEC [APIStoredProVersionDB].trans.sp_set_material_endlot_001
	--			@lot_no = @lot_no,
	--			@barcode = @barcode,
	--			@opno = @opno,
	--			@mcno = @mcno,
	--			@qty = @qty
	---- ########## VERSION 001 ##########

	-- ########## VERSION 002 ##########
			EXEC [APIStoredProVersionDB].trans.sp_set_material_endlot_002
				@lot_no = @lot_no,
				@barcode = @barcode,
				@opno = @opno,
				@mcno = @mcno,
				@qty = @qty
	-- ########## VERSION 002 ##########

END
