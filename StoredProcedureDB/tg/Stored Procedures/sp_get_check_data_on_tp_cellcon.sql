-- =============================================
-- Author:		<Author,,Aomsin DSI 009131>
-- Create date: <Create Date,2024/06/07>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [tg].[sp_get_check_data_on_tp_cellcon]
	-- Add the parameters for the stored procedure here
	  @lot_no VARCHAR(10) = ''
	, @function INT = 0 
	, @emp_id INT = null
	, @img_id INT = null

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		( [record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no] )
	SELECT GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [tg].[sp_get_check_data_on_tp_cellcon] @lot_no = ''' + ISNULL(CAST(@lot_no AS VARCHAR),'NULL') + ''''
			+ ' , @function = ' + ISNULL(CAST(@function AS VARCHAR),'NULL')
		, ISNULL(CAST(@lot_no AS VARCHAR),'NULL');
	--=====================================================================================================================================================================================
	----# 1: GET MEMBER LOT AND QTY_HASUU
	IF (@function = 1)
	BEGIN
		SELECT TRIM(lot_member.lot_no) AS lotno
			,sur.pcs AS qty_hasuu 
		FROM APCSProDB.trans.lot_combine AS lot_cb 
		INNER JOIN APCSProDB.trans.lots AS lot ON lot_cb.lot_id = lot.id 
		INNER JOIN APCSProDB.trans.lots AS lot_member ON lot_cb.member_lot_id = lot_member.id 
		INNER JOIN APCSProDB.trans.surpluses AS sur ON lot_cb.member_lot_id = sur.lot_id
		WHERE lot.lot_no = @lot_no
	END
	--=====================================================================================================================================================================================
	----# 2:searchUserData (TP)
	ELSE IF (@function = 2)
	BEGIN
		SELECT emp_num FROM [APCSProDB].[man].[users] WHERE [id] = @emp_id
	END
	--=====================================================================================================================================================================================
	----# 3:getDataQtyTranLot (TP)
	ELSE IF (@function = 3)
	BEGIN
		SELECT [qty_combined]
			, [qty_p_nashi]
			, [qty_front_ng]
			, [qty_marker]
			, [production_category] 
			, [quality_state]
			, [wip_state]
			, [packages].[pcs_per_tube_or_tray] 
		FROM APCSProDB.trans.lots 
		INNER JOIN APCSProDB.method.packages ON lots.act_package_id = packages.id
		WHERE lot_no = @lot_no 
	END
	--=====================================================================================================================================================================================
	----# 4:CheckLogo (TP)
	ELSE IF (@function = 4)
	BEGIN
		 SELECT picture_url,picture_data FROM APCSProDBFile.ocr.marking_logo_picture where id = @img_id
	END
	--=====================================================================================================================================================================================
	----# 5:GET Data for Rework (TP)  Create : 2025/01/29 Time : 11.24 by Aomsin
	ELSE IF (@function = 5)
	BEGIN
		 SELECT [lots].[id]
			,[lots].[qty_out]
			,[sur].[pcs]
			,[sur].[in_stock]
			,[dev].[pcs_per_pack] 
		 FROM [APCSProDB].[trans].[lots] as [lots]
		 INNER JOIN [APCSProDB].[trans].[surpluses] as [sur] on [lots].[id] = [sur].[lot_id] 
		 INNER JOIN [APCSProDB].[method].[device_names] as [dev] on [dev].[id] = [lots].[act_device_name_id] 
		 WHERE [lots].[lot_no] = @lot_no
	END
	----# 6:Check Data Firstlot TG (TP)  Create : 2025/01/29 Time : 14.53 by Aomsin
	ELSE IF (@function = 6)
	BEGIN
		DECLARE @lotID INT = 0
		SELECT @lotID = [id] FROM [APCSProDB].[trans].[lots] WHERE lot_no = @lot_no
		SELECT COUNT(lot_id) AS [countData] from [APCSProDB].[trans].[lot_combine] where [lot_id] = @lotID
	END
END
