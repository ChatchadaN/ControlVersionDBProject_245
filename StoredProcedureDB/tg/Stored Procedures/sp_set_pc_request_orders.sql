-- =============================================
-- =============================================
CREATE PROCEDURE [tg].[sp_set_pc_request_orders]
	-- Add the parameters for the stored procedure here
	 @order_id INT = NULL, 
	 @package_name CHAR(20) = '', 
	 @device_name CHAR(20) = '', 
	 @date DATE = '1999-01-01', 
	 @ship_date DATE = '1999-01-01', 
	 @condition_type INT = 0, 
	 @pdcd VARCHAR(6) = '', 
	 @attachment_need NVARCHAR(100) = '', 
	 @rank CHAR(5) = '', 
	 @qc_instruction CHAR(20) = '', 
	 @remark VARCHAR(100) = '', 
	 @is_urgent INT = 0, 
	 @qty INT = 0, 
	 @section_id INT = null, 
	 @user_id INT = NULL,
	 @is_shipment INT = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @month_year VARCHAR(6) = FORMAT(GETDATE(),'yyyyMM');

	IF NOT EXISTS(SELECT 1 FROM [APCSProDB].[trans].[pc_request_orders] WHERE [order_id] = @order_id AND [month_year] = @month_year)
	BEGIN
		INSERT INTO [APCSProDB].[trans].[pc_request_orders]
			( [order_id]
			, [month_year]
			, [package_name]
			, [device_name]
			, [date]
			, [ship_date]
			, [condition_type]
			, [pdcd]
			, [attachment_need]
			, [rank]
			, [qc_instruction]
			, [remark]
			, [is_urgent]
			, [is_state]
			, [lot_id]
			, [qty]
			, [qty_last]
			, [request_at]
			, [created_lot_at]
			, [created_at]
			, [created_by]
			, [updated_at]
			, [updated_by] 
			, [section_id]
			, [is_shipment])
		SELECT @order_id AS [order_id]
			, @month_year AS [month_year]
			, @package_name AS [package_name]
			, @device_name AS [device_name]
			, @date AS [date]
			, @ship_date AS [ship_date]
			, @condition_type AS [condition_type]
			, @pdcd AS [pdcd]
			, @attachment_need AS [attachment_need]
			, @rank AS [rank]
			, @qc_instruction AS [qc_instruction]
			, @remark AS [remark]
			, @is_urgent AS [is_urgent]
			, 0 AS [is_state]
			, NULL AS [lot_id]
			, @qty AS [qty]
			, NULL AS [qty_last]
			, GETDATE() AS [request_at]
			, NULL AS [created_lot_at]
			, GETDATE() AS [created_at]
			, @user_id AS [created_by]
			, NULL AS [updated_at]
			, NULL AS [updated_by]
			, @section_id 
			, @is_shipment;

		--Get Data auto_id_order and Order_no
		DECLARE @get_order_id int = null
		DECLARE @get_order_no int = null
		SELECT @get_order_id = id,@get_order_no = order_id from APCSProDB.trans.pc_request_orders where order_id = @order_id and month_year = @month_year

		IF (@@ROWCOUNT > 0)
		BEGIN
			SELECT 'TRUE' AS Is_Pass 
				, 'Insert data success' AS Error_Message_ENG
				, N'บันทึกข้อมูลสำเร็จ' AS Error_Message_THA 
				, N'' AS Handling
				, @get_order_id As IdofOrder
				, @get_order_no As OrderNo
			RETURN;
		END
		ELSE
		BEGIN
			SELECT 'FALSE' AS Is_Pass 
				, 'Insert data error !!' AS Error_Message_ENG
				, N'บันทึกข้อมูลผิดพลาด !!' AS Error_Message_THA 
				, N'กรุณาติดต่อ System' AS Handling
				, @get_order_id As IdofOrder
				, @get_order_no As OrderNo
			RETURN;
		END
	END
	ELSE
	BEGIN
		SELECT 'FALSE' AS Is_Pass 
			, 'order duplicate !!' AS Error_Message_ENG
			, N'order ซ้ำ !!' AS Error_Message_THA 
			, N'กรุณาติดต่อ System' AS Handling
			, @get_order_id As IdofOrder
			, @get_order_no As OrderNo
		RETURN;
	END
END
