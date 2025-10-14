
CREATE PROCEDURE [lsms].[sp_get_hasuu_stock] 
	-- Add the parameters for the stored procedure here
	  @Type CHAR(20) = ''
	, @TRNo CHAR(11) = ''
	, @Spec CHAR(3) = ''
	, @HFERank CHAR(6) = ''
	, @Marking1 VARCHAR(14) = ''
	, @lotno varchar(10) = ''
	, @FuntionType INT ---# 1: StockGroup, 2: StockGroupBYdetailLot, 3 : Search lot master , 4 : Get Data in Rack page, 5 : Check data in surpluses ?
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	--Test
	IF (@FuntionType = 1)
	BEGIN
		--- Group
		SELECT [lot_informations].[type_name]
			, [lot_informations].[tr_no]
			, [lot_informations].[spec]
			, [lot_informations].[pack_unit_qty]
			, [lot_informations].[hfe_rank]
			, [lot_informations].[marking_1]
			, SUM([surpluses].[pcs]) AS [qty]
			, COUNT([lot_informations].[lot_no]) AS [lot]
		FROM [APCSProDB].[trans].[lot_informations]
		INNER JOIN [APCSProDB].[trans].[surpluses] ON [lot_informations].[id] = [surpluses].[lot_id]
		GROUP BY [lot_informations].[type_name]
			, [lot_informations].[tr_no]
			, [lot_informations].[spec]
			, [lot_informations].[pack_unit_qty]
			, [lot_informations].[hfe_rank]
			, [lot_informations].[marking_1];
	END
	ELSE IF (@FuntionType = 2)
	BEGIN
		----Lot
		--SELECT [lot_informations].[lot_no]
		--	, [lot_informations].[type_name]
		--	, [lot_informations].[tr_no]
		--	, [lot_informations].[spec]
		--	, [surpluses].[pcs] AS [qty]
		--	, [lot_informations].[pack_unit_qty]
		--	, [lot_informations].[hfe_rank]
		--	, [lot_informations].[marking_1]
		--FROM [APCSProDB].[trans].[lot_informations]
		--INNER JOIN [APCSProDB].[trans].[surpluses] ON [lot_informations].[id] = [surpluses].[lot_id]
		--WHERE [lot_informations].[type_name] = @Type
		--	AND [lot_informations].[tr_no] = @TRNo
		--	AND [lot_informations].[spec] = @Spec
		--	AND [lot_informations].[hfe_rank] = @HFERank
		--	AND [lot_informations].[marking_1] = @Marking1
		--	AND [lot_no] != @lotno;
		SELECT [Detail].*
			, [item].[color_code]
		FROM (
			SELECT [lot_informations].[lot_no]
				, [lot_informations].[type_name]
				, [lot_informations].[tr_no]
				, [lot_informations].[spec]
				, [surpluses].[pcs] AS [qty]
				, [lot_informations].[pack_unit_qty]
				, [lot_informations].[hfe_rank]
				, [lot_informations].[marking_1]
				, [surpluses].[location_id]
				, [locations].[name] AS [location]	
				, [rack_controls].[name] AS [rack_name]
				, [rack_addresses].[address] AS [rack_address]
				, [surpluses].[created_at] AS [date_exp]
				--,
				--CASE
				--	WHEN DATEDIFF(MONTH, [surpluses].[created_at], GETDATE()) >= 48 THEN 'Surpluses Long' --> อายุเกิน 4 ปี จะเป็น Hasuu long standing 
				--	WHEN DATEDIFF(MONTH, [surpluses].[created_at], GETDATE()) = 1 THEN '1'  --> ก่อนหมดอายุ 1 เดือน จะโชว์
				--	WHEN DATEDIFF(MONTH, [surpluses].[created_at], GETDATE()) < 1 THEN '2'  --> งานปกติ
				--	WHEN DATEDIFF(MONTH, [surpluses].[created_at], GETDATE()) > 1 THEN 'EXP.'  --> อิหยังหว่า หมดอายุหรือเขียนผิด ?? รอแก้ไข
				--END AS [status]
				, ( CASE
					WHEN DATEDIFF(MONTH, [surpluses].[created_at], GETDATE()) >= 48 THEN '#FF0000' -- Surpluses Long (3)
					WHEN DATEDIFF(MONTH, [surpluses].[created_at], GETDATE()) = 47 THEN '#FEEE91' -- Warning Exprite date (1)
					ELSE '#FFFFFF' -- Normal (2)
				END ) AS [status]
			FROM [APCSProDB].[trans].[lot_informations]
			INNER JOIN [APCSProDB].[trans].[surpluses] ON [lot_informations].[id] = [surpluses].[lot_id]
			INNER JOIN [APCSProDB].[rcs].[rack_addresses] ON [lot_informations].[lot_no] = [rack_addresses].[item]
				AND [surpluses].[location_id] = [rack_addresses].[id]
			INNER JOIN [APCSProDB].[rcs].[rack_controls] ON [rack_addresses].[rack_control_id] = [rack_controls].[id]
			INNER JOIN [APCSProDB].[trans].[locations] ON [rack_controls].[location_id] = [locations].[id]
			WHERE [locations].[address] = 'WideLine'
				AND [lot_informations].[type_name] = @Type
				AND [lot_informations].[tr_no] = @TRNo
				AND [lot_informations].[spec] = @Spec
				AND [lot_informations].[hfe_rank] = @HFERank
				AND [lot_informations].[marking_1] = @Marking1
				AND [lot_no] != @lotno
				--ยังไม่ได้ใส่เงื่อนไขถ้างานอายุเกินห้ามโชว์
		) AS [Detail]
		LEFT JOIN [APCSProDB].[trans].[item_labels] AS [item] ON [Detail].[status] = [item].[val] 
			AND [item].[name] = 'surpluses.expiration'
	END
	ELSE IF (@FuntionType = 3)
	BEGIN
		--SELECT [lot_informations].[lot_no]
		--	, [lot_informations].[type_name]
		--	, [lot_informations].[tr_no]
		--	, [lot_informations].[spec]
		--	, [lot_informations].[qty_pass] AS [qty]
		--	, [lot_informations].[pack_unit_qty]
		--	, [lot_informations].[hfe_rank]
		--	, [lot_informations].[marking_1]
		--	, ([lot_informations].[qty_pass]/[lot_informations].[pack_unit_qty]) * [lot_informations].[pack_unit_qty] AS [qty_shipment]
		--	, ([lot_informations].[qty_pass] - (([lot_informations].[qty_pass]/[lot_informations].[pack_unit_qty]) * [lot_informations].[pack_unit_qty])) AS [qty_surpluses]
		--FROM [APCSProDB].[trans].[lot_informations]
		--WHERE [lot_informations].[lot_no] = @lotno

		--** Update Query 2025/04/04 **--
		SELECT [lot_informations].[lot_no]
			, [lot_informations].[type_name]
			, [lot_informations].[tr_no]
			, [lot_informations].[spec]
			, [lot_informations].[qty_pass] AS [qty]
			, [lot_informations].[pack_unit_qty]
			, [lot_informations].[hfe_rank]
			, [lot_informations].[marking_1]
			, [lot_informations].[output_qty] AS [qty_shipment]
			, (([lot_informations].[qty_pass] - [lot_informations].[output_qty])/[lot_informations].[pack_unit_qty]) * [lot_informations].[pack_unit_qty] AS [qty_surpluses]
			, (([lot_informations].[qty_pass] - [lot_informations].[output_qty]) - ((([lot_informations].[qty_pass] - [lot_informations].[output_qty])/[lot_informations].[pack_unit_qty]) * [lot_informations].[pack_unit_qty])) AS [qty_faction]  
		FROM [APCSProDB].[trans].[lot_informations]
		WHERE [lot_informations].[lot_no] = @lotno
	END
	ELSE IF (@FuntionType = 4)
	BEGIN
		----Lot
		SELECT [lot_informations].[lot_no]
			, [lot_informations].[type_name]
			, [lot_informations].[tr_no]
			, [lot_informations].[spec]
			, [surpluses].[pcs] AS [qty]
			, [lot_informations].[pack_unit_qty]
			, [lot_informations].[hfe_rank]
			, [lot_informations].[marking_1]
		FROM [APCSProDB].[trans].[lot_informations]
		INNER JOIN [APCSProDB].[trans].[surpluses] ON [lot_informations].[id] = [surpluses].[lot_id]
		WHERE [surpluses].[serial_no] = @lotno
	END
	ELSE IF (@FuntionType = 5) --check data in surpluses table
	BEGIN
		IF EXISTS(SELECT serial_no FROM APCSProDB.trans.surpluses WHERE serial_no = @lotno)
		BEGIN
			SELECT 'TRUE' AS [Is_Pass] 
				, 'Search completed successfully' AS [Error_Message_ENG]
				, '' AS [Error_Message_THA] 
				, '' AS [Handling];		
		END
		ELSE
		BEGIN
			SELECT 'FALSE' AS [Is_Pass] 
				, 'Not found Surpluses lot' AS [Error_Message_ENG]
				, N'ไม่พบข้อมูล Surpluses lot นี้' AS [Error_Message_THA] 
				, N'' AS [Handling];		
		END
	END
END
