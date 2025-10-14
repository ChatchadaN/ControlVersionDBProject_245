-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_lot_stock_V2_by_bass]
	-- Add the parameters for the stored procedure here
	@lotno VARCHAR(10),
	@mcno VARCHAR(20) = ''  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @Process_Value CHAR(20) = '', @lot_id AS INT

	--update 2021/12/09 time : 11.47
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
		, 'EXEC [dbo].[tg_sp_get_lot_stock_V2] @lotno = ''' + @lotno + ''''
		, @lotno
   
	SELECT @lot_id = id FROM APCSProDB.trans.lots WHERE lot_no = @lotno;

	--Add Parameter Check Record in Allocat : 2022/11/17 time : 11.45
	DECLARE @Lotno_Allocat_Count INT = 0
	SELECT @Lotno_Allocat_Count = COUNT(*) FROM APCSProDB.method.allocat WHERE LotNo = @lotno;

	IF @mcno = ''  --FOR WEB LSMS
	BEGIN
		--UPDATE QUERY 2023/04/11 Time : 10.01
		IF @Lotno_Allocat_Count != 0
		BEGIN
			SELECT allocat.LotNo AS lot_no
				, lots.qty_pass
				, ISNULL(TRIM(surpluses.serial_no), '-') AS Hasuu_LotNo
				, ISNULL(surpluses.MNo, '') AS MNo_H_Stock
				, ISNULL(surpluses.pcs, '-') AS Hasuu_Qty
				, DATEDIFF(YEAR, surpluses.created_at, GETDATE()) AS Over_Year
				, allocat.Type_Name AS Package
				, allocat.ROHM_Model_Name AS Device
				, allocat.TIRank
				, allocat.rank
				, allocat.TPRank
				, allocat.SUBRank
				, allocat.PDCD
				, allocat.Mask
				, allocat.KNo
				, allocat.MNo AS MNo_Standard
				, allocat.ORNo
				, ISNULL(allocat.Packing_Standerd_QTY, '-') AS Standerd_QTY
				, allocat.Tomson1
				, allocat.Tomson2
				, allocat.Tomson3
				, allocat.WFLotNo
				, allocat.LotNo_Class
				, allocat.User_Code
				, allocat.Product_Control_Cl_1
				, allocat.Product_Class
				, allocat.Production_Class
				, allocat.Rank_No
				, allocat.HINSYU_Class
				, allocat.Label_Class
				, allocat.OUT_OUT_FLAG
				, device_names.name AS DeviceTpRank
				, ISNULL(lots.qty_pass + surpluses.pcs, '-') AS Total
				, ISNULL((lots.qty_pass + surpluses.pcs) / (allocat.Packing_Standerd_QTY), '-') AS Reel
				, ISNULL((lots.qty_pass + surpluses.pcs) % (allocat.Packing_Standerd_QTY), '-') AS TotalHasuu
				, assy_orders.order_no AS OrderNo
				, ISNULL(surpluses.location_name, 'nolocation') AS location_name
				, ISNULL(surpluses.location_address, 'noaddress') AS location_address
			FROM APCSProDB.method.allocat
			INNER JOIN APCSProDB.trans.lots ON lots.lot_no = allocat.LotNo
			LEFT JOIN APCSProDB.robin.assy_orders ON assy_orders.id = lots.order_id
			INNER JOIN APCSProDB.method.device_names ON lots.act_device_name_id = device_names.id
			CROSS APPLY (
				SELECT TOP 1 surpluses.*
					, locations.name AS location_name
					, locations.address AS location_address
					, tl.wip_state
					, dn.name AS ROHM_Model_Name
					, ISNULL(dn.rank, '') AS Rank_dn
					, surpluses.qc_instruction AS Tomson_Mark_3
					, surpluses.mark_no AS MNo
				FROM APCSProDB.trans.surpluses
				LEFT JOIN APCSProDB.trans.lots AS tl ON tl.lot_no = surpluses.serial_no
				LEFT JOIN APCSProDB.trans.locations AS locations ON surpluses.location_id = locations.id
				LEFT JOIN APCSProDB.method.device_names AS dn ON tl.act_device_name_id = dn.id
				WHERE (
						--SUBSTRING(serial_no, 5, 1) IN ( 'A', 'B', 'F', 'G' )  --( 'A', 'B', 'F', 'G' )  change 2023/09/07 time : 13.24
						(
							(CASE
								WHEN SUBSTRING(lots.lot_no, 5, 1) = 'A' AND SUBSTRING(serial_no, 5, 1) IN ('A','B','D') THEN 1
								WHEN SUBSTRING(lots.lot_no, 5, 1) = 'B' AND SUBSTRING(serial_no, 5, 1) IN ('A','D','F') THEN 1
								WHEN SUBSTRING(lots.lot_no, 5, 1) = 'F' AND SUBSTRING(serial_no, 5, 1) IN ('A','B','D','F') THEN 1
								ELSE 0
							END) = 1
						) --add 2023/09/08 time : 14.10
						OR (
							SUBSTRING(serial_no, 5, 1) = 'G'
							AND dn.name IN ( 'BV2HC045EFU-C       '
								, 'BV2HD045EFU-CE2     '
								, 'BV2HD070EFU-CE2    '
								, 'BV2HC045EFU-CE2     ' )
						) --add 2023/03/24 time : 11.56
					)
					AND surpluses.location_id != 0
					AND tl.wip_state IN ( 20, 70, 100 )
					AND tl.quality_state = 0
					AND surpluses.in_stock = 2
					AND dn.name = allocat.ROHM_Model_Name
					AND dn.rank = allocat.Rank
					AND surpluses.qc_instruction = allocat.Tomson3
					AND allocat.LotNo != surpluses.serial_no --lot ใน Allocat ต้อง ไม่มีอยู่ใน Surpluses
					AND surpluses.created_at >= (GETDATE() - 1095)
				ORDER BY surpluses.serial_no ASC
			) AS surpluses
			WHERE lots.id = @lot_id
				AND SUBSTRING(allocat.LotNo, 0, 3) >= 21
		END
		ELSE
		BEGIN
			SELECT allocat.LotNo AS lot_no
				, lots.qty_pass
				, ISNULL(TRIM(surpluses.serial_no), '-') AS Hasuu_LotNo
				, ISNULL(surpluses.MNo, '') AS MNo_H_Stock
				, ISNULL(surpluses.pcs, '-') AS Hasuu_Qty
				, DATEDIFF(YEAR, surpluses.created_at, GETDATE()) AS Over_Year
				, allocat.Type_Name AS Package
				, allocat.ROHM_Model_Name AS Device
				, allocat.TIRank
				, allocat.rank
				, allocat.TPRank
				, allocat.SUBRank
				, allocat.PDCD
				, allocat.Mask
				, allocat.KNo
				, allocat.MNo AS MNo_Standard
				, allocat.ORNo
				, ISNULL(allocat.Packing_Standerd_QTY, '-') AS Standerd_QTY
				, allocat.Tomson1
				, allocat.Tomson2
				, allocat.Tomson3
				, allocat.WFLotNo
				, allocat.LotNo_Class
				, allocat.User_Code
				, allocat.Product_Control_Cl_1
				, allocat.Product_Class
				, allocat.Production_Class
				, allocat.Rank_No
				, allocat.HINSYU_Class
				, allocat.Label_Class
				, allocat.OUT_OUT_FLAG
				, device_names.name AS DeviceTpRank
				, ISNULL(lots.qty_pass + surpluses.pcs, '-') AS Total
				, ISNULL((lots.qty_pass + surpluses.pcs) / (allocat.Packing_Standerd_QTY), '-') AS Reel
				, ISNULL((lots.qty_pass + surpluses.pcs) % (allocat.Packing_Standerd_QTY), '-') AS TotalHasuu
				, assy_orders.order_no AS OrderNo
				, ISNULL(surpluses.location_name, 'nolocation') AS location_name
				, ISNULL(surpluses.location_address, 'noaddress') AS location_address
			FROM APCSProDB.method.allocat_temp AS allocat
			INNER JOIN APCSProDB.trans.lots ON lots.lot_no = allocat.LotNo
			LEFT JOIN APCSProDB.robin.assy_orders ON assy_orders.id = lots.order_id
			INNER JOIN APCSProDB.method.device_names ON lots.act_device_name_id = device_names.id
			CROSS APPLY (
				SELECT TOP 1 surpluses.*
					, locations.name AS location_name
					, locations.address AS location_address
					, tl.wip_state
					, dn.name AS ROHM_Model_Name
					, ISNULL(dn.rank, '') AS Rank_dn
					, surpluses.qc_instruction AS Tomson_Mark_3
					, surpluses.mark_no AS MNo
				FROM APCSProDB.trans.surpluses
				LEFT JOIN APCSProDB.trans.lots AS tl ON tl.lot_no = surpluses.serial_no
				LEFT JOIN APCSProDB.trans.locations AS locations ON surpluses.location_id = locations.id
				LEFT JOIN APCSProDB.method.device_names AS dn ON tl.act_device_name_id = dn.id
				WHERE (
						--SUBSTRING(serial_no, 5, 1) IN ( 'A', 'B','F', 'G' )   --( 'A', 'B', 'F', 'G' )  change 2023/09/07 time : 13.24
						(
							(CASE
								WHEN SUBSTRING(lots.lot_no, 5, 1) = 'A' AND SUBSTRING(serial_no, 5, 1) IN ('A','B','D') THEN 1
								WHEN SUBSTRING(lots.lot_no, 5, 1) = 'B' AND SUBSTRING(serial_no, 5, 1) IN ('A','D','F') THEN 1
								WHEN SUBSTRING(lots.lot_no, 5, 1) = 'F' AND SUBSTRING(serial_no, 5, 1) IN ('A','B','D','F') THEN 1
								ELSE 0
							END) = 1
						) --add 2023/09/08 time : 14.10
						OR (
							SUBSTRING(serial_no, 5, 1) = 'G'
							AND dn.name in ( 'BV2HC045EFU-C       '
								, 'BV2HD045EFU-CE2     '
								, 'BV2HD070EFU-CE2    '
								, 'BV2HC045EFU-CE2     ' )
						) --add 2023/03/24 time : 11.56
					)
					AND surpluses.location_id != 0
					AND tl.wip_state IN ( 20, 70, 100 )
					AND tl.quality_state = 0
					AND surpluses.in_stock = 2
					AND dn.name = allocat.ROHM_Model_Name
					AND dn.rank = allocat.Rank
					AND surpluses.qc_instruction = allocat.Tomson3
					AND allocat.LotNo != surpluses.serial_no --lot ใน Allocat ต้อง ไม่มีอยู่ใน Surpluses
					AND surpluses.created_at >= (GETDATE() - 1095)
				ORDER BY surpluses.serial_no ASC
			) AS surpluses
			WHERE lots.id = @lot_id
				AND SUBSTRING(allocat.LotNo, 0, 3) >= 21
		END
	END
	-- OPEN 2023/05/18 11:03
	ELSE IF @mcno != ''  --FOR TP CELLCON
	BEGIN
		---------------------------------------------------------------------------------
		-- # << CELLCON
		---------------------------------------------------------------------------------
		IF @Lotno_Allocat_Count != 0
		BEGIN
			SELECT allocat.LotNo AS lot_no,
				lots.qty_pass,
				ISNULL(TRIM(surpluses.serial_no), '-') AS Hasuu_LotNo,
				ISNULL(surpluses.MNo, '') AS MNo_H_Stock,
				ISNULL(surpluses.pcs, '-') AS Hasuu_Qty,
				ISNULL(surpluses.location_name, 'No Location') AS location_name,
				ISNULL(CAST(surpluses.location_address AS VARCHAR(10)), 'No Address') AS location_address
			FROM APCSProDB.method.allocat
			INNER JOIN APCSProDB.trans.lots ON lots.lot_no = allocat.LotNo
			LEFT JOIN APCSProDB.robin.assy_orders ON assy_orders.id = lots.order_id
			INNER JOIN APCSProDB.method.device_names ON lots.act_device_name_id = device_names.id
			OUTER APPLY (
				SELECT TOP 1 surpluses.*
					, locations.name AS location_name
					, locations.address AS location_address
					, tl.wip_state
					, dn.name AS ROHM_Model_Name
					, isnull(dn.rank, '') AS Rank_dn
					, surpluses.qc_instruction AS Tomson_Mark_3
					, surpluses.mark_no AS MNo
				FROM APCSProDB.trans.surpluses
				LEFT JOIN APCSProDB.trans.lots AS tl ON tl.lot_no = surpluses.serial_no
				LEFT JOIN APCSProDB.trans.locations AS locations ON surpluses.location_id = locations.id
				LEFT JOIN APCSProDB.method.device_names AS dn ON tl.act_device_name_id = dn.id
				WHERE (
						--SUBSTRING(serial_no, 5, 1) IN ( 'A', 'B','F', 'G' )   --( 'A', 'B', 'F', 'G' )  change 2023/09/07 time : 13.24
						(
							(CASE
								WHEN SUBSTRING(lots.lot_no, 5, 1) = 'A' AND SUBSTRING(serial_no, 5, 1) IN ('A','B','D') THEN 1
								WHEN SUBSTRING(lots.lot_no, 5, 1) = 'B' AND SUBSTRING(serial_no, 5, 1) IN ('A','D','F') THEN 1
								WHEN SUBSTRING(lots.lot_no, 5, 1) = 'F' AND SUBSTRING(serial_no, 5, 1) IN ('A','B','D','F') THEN 1
								ELSE 0
							END) = 1
						) --add 2023/09/08 time : 14.10
				        OR (
							SUBSTRING(serial_no, 5, 1) = 'G'
							AND dn.name IN ( 'BV2HC045EFU-C       '
								, 'BV2HD045EFU-CE2     '
								, 'BV2HD070EFU-CE2    '
								,'BV2HC045EFU-CE2     ' )
				        ) --add 2023/03/24 time : 11.56
					)
				    --AND surpluses.location_id != 0
				    AND tl.wip_state IN ( 20, 70, 100 )
				    AND tl.quality_state = 0
				    AND surpluses.in_stock = 2
				    AND dn.name = allocat.ROHM_Model_Name
				    AND dn.rank = allocat.Rank
				    AND surpluses.qc_instruction = allocat.Tomson3
				    AND allocat.LotNo != surpluses.serial_no --lot ใน Allocat ต้อง ไม่มีอยู่ใน Surpluses
					AND surpluses.created_at >= (GETDATE() - 1095)
				ORDER BY IIF(surpluses.location_id IS NULL,1,0) ASC, surpluses.serial_no ASC
			) AS surpluses
			WHERE lots.id = @lot_id
				AND SUBSTRING(allocat.LotNo, 0, 3) >= 21
				AND surpluses.serial_no IS NOT NULL
		END
		ELSE
		BEGIN
			SELECT allocat.LotNo AS lot_no
				, lots.qty_pass
				, ISNULL(TRIM(surpluses.serial_no), '-') AS Hasuu_LotNo
				, ISNULL(surpluses.MNo, '') AS MNo_H_Stock
				, ISNULL(surpluses.pcs, '-') AS Hasuu_Qty
				, ISNULL(surpluses.location_name, 'No Location') AS location_name
				, ISNULL(CAST(surpluses.location_address AS VARCHAR(10)), 'No Address') AS location_address
			FROM APCSProDB.method.allocat_temp AS allocat
			INNER JOIN APCSProDB.trans.lots ON lots.lot_no = allocat.LotNo
			LEFT JOIN APCSProDB.robin.assy_orders ON assy_orders.id = lots.order_id
			INNER JOIN APCSProDB.method.device_names ON lots.act_device_name_id = device_names.id
			OUTER APPLY (
				SELECT TOP 1 surpluses.*
					, locations.name AS location_name
					, locations.address AS location_address
					, tl.wip_state
					, dn.name AS ROHM_Model_Name
					, isnull(dn.rank, '') AS Rank_dn
					, surpluses.qc_instruction AS Tomson_Mark_3
					, surpluses.mark_no AS MNo
				FROM APCSProDB.trans.surpluses
				LEFT JOIN APCSProDB.trans.lots AS tl ON tl.lot_no = surpluses.serial_no
				LEFT JOIN APCSProDB.trans.locations AS locations ON surpluses.location_id = locations.id
				LEFT JOIN APCSProDB.method.device_names AS dn ON tl.act_device_name_id = dn.id
				WHERE (
						--SUBSTRING(serial_no, 5, 1) IN ( 'A', 'B','F', 'G' )   --( 'A', 'B', 'F', 'G' )  change 2023/09/07 time : 13.24
						(
							(CASE
								WHEN SUBSTRING(lots.lot_no, 5, 1) = 'A' AND SUBSTRING(serial_no, 5, 1) IN ('A','B','D') THEN 1
								WHEN SUBSTRING(lots.lot_no, 5, 1) = 'B' AND SUBSTRING(serial_no, 5, 1) IN ('A','D','F') THEN 1
								WHEN SUBSTRING(lots.lot_no, 5, 1) = 'F' AND SUBSTRING(serial_no, 5, 1) IN ('A','B','D','F') THEN 1
								ELSE 0
							END) = 1
						) --add 2023/09/08 time : 14.10
				        OR (
							SUBSTRING(serial_no, 5, 1) = 'G'
							AND dn.name IN ( 'BV2HC045EFU-C       '
								, 'BV2HD045EFU-CE2     '
								, 'BV2HD070EFU-CE2    '
								, 'BV2HC045EFU-CE2     ' )
				         ) --add 2023/03/24 time : 11.56
					)
				    --AND surpluses.location_id != 0
				    AND tl.wip_state IN ( 20, 70, 100 )
				    AND tl.quality_state = 0
				    AND surpluses.in_stock = 2
				    AND dn.name = allocat.ROHM_Model_Name
				    AND dn.rank = allocat.Rank
				    AND surpluses.qc_instruction = allocat.Tomson3
				    AND allocat.LotNo != surpluses.serial_no --lot ใน Allocat ต้อง ไม่มีอยู่ใน Surpluses
					AND surpluses.created_at >= (GETDATE() - 1095)
				ORDER BY IIF(surpluses.location_id IS NULL,1,0) ASC, surpluses.serial_no ASC
			) AS surpluses
			WHERE lots.id = @lot_id
				AND SUBSTRING(allocat.LotNo, 0, 3) >= 21
				AND surpluses.serial_no IS NOT NULL
		END
		---------------------------------------------------------------------------------
		-- # >> CELLCON
		---------------------------------------------------------------------------------
	END
END
