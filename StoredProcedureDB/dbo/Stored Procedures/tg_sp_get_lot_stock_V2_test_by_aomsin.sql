-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_lot_stock_V2_test_by_aomsin]
	-- Add the parameters for the stored procedure here
	 @lotno varchar(10)
	,@mcno varchar(20) = ''  
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @Process_Value char(20) = '' , @lot_id AS INT

	--update 2021/12/09 time : 11.47
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	([record_at]
      , [record_class]
      , [login_name]
      , [hostname]
      , [appname]
      , [command_text]
	  , [lot_no])
	SELECT GETDATE()
		,'4'
		,ORIGINAL_LOGIN()
		,HOST_NAME()
		,APP_NAME()
		,'EXEC [dbo].[tg_sp_get_lot_stock_V2] @lotno = ''' + @lotno + ''''
		,@lotno
   
		select @lot_id = id from APCSProDB.trans.lots
		where lot_no = @lotno

		--Add Parameter Check Record in Allocat : 2022/11/17 time : 11.45
		DECLARE @Lotno_Allocat_Count Int = 0
		SELECT @Lotno_Allocat_Count = COUNT(*) FROM APCSProDB.method.allocat where LotNo = @lotno

		IF @mcno = ''  --FOR WEB LSMS
		BEGIN
			--UPDATE QUERY 2023/04/11 Time : 10.01
			IF @Lotno_Allocat_Count != 0
			BEGIN
				select 
				allocat.LotNo as lot_no,
				lots.qty_pass,
				isnull(trim(surpluses.serial_no), '-') as Hasuu_LotNo,
				isnull(surpluses.MNo, '') as MNo_H_Stock,
				isnull(surpluses.pcs, '-') as Hasuu_Qty,
				datediff(year, surpluses.created_at, getdate()) as Over_Year,
				allocat.Type_Name as Package,
				allocat.ROHM_Model_Name as Device,
				allocat.TIRank,
				allocat.rank,
				allocat.TPRank,
				allocat.SUBRank,
				allocat.PDCD,
				allocat.Mask,
				allocat.KNo,
				allocat.MNo as MNo_Standard,
				allocat.ORNo,
				isnull(allocat.Packing_Standerd_QTY, '-') as Standerd_QTY,
				allocat.Tomson1,
				allocat.Tomson2,
				allocat.Tomson3,
				allocat.WFLotNo,
				allocat.LotNo_Class,
				allocat.User_Code,
				allocat.Product_Control_Cl_1,
				allocat.Product_Class,
				allocat.Production_Class,
				allocat.Rank_No,
				allocat.HINSYU_Class,
				allocat.Label_Class,
				allocat.OUT_OUT_FLAG,
				device_names.name as DeviceTpRank,
				isnull(lots.qty_pass + surpluses.pcs, '-') as Total,
				isnull((lots.qty_pass + surpluses.pcs) / (allocat.Packing_Standerd_QTY), '-') as Reel,
				isnull((lots.qty_pass + surpluses.pcs) % (allocat.Packing_Standerd_QTY), '-') as TotalHasuu,
				assy_orders.order_no as OrderNo,
				isnull(surpluses.location_name, 'nolocation') as location_name,
				isnull(surpluses.location_address, 'noaddress') as location_address
				from APCSProDB.method.allocat
				    inner join APCSProDB.trans.lots
				        on lots.lot_no = allocat.LotNo
				    left join APCSProDB.robin.assy_orders
				        on assy_orders.id = lots.order_id
				    inner join APCSProDB.method.device_names
				        on lots.act_device_name_id = device_names.id
				    cross apply
				(
				    select top 1
				        surpluses.*,
				        locations.name as location_name,
				        locations.address as location_address,
				        tl.wip_state,
				        dn.name as ROHM_Model_Name,
				        isnull(dn.rank, '') as Rank_dn,
				        surpluses.qc_instruction as Tomson_Mark_3,
				        surpluses.mark_no as MNo
				    from APCSProDB.trans.surpluses
				        left join APCSProDB.trans.lots as tl
				            on tl.lot_no = surpluses.serial_no
				        left join APCSProDB.trans.locations as locations
				            on surpluses.location_id = locations.id
				        left join APCSProDB.method.device_names as dn
				            on tl.act_device_name_id = dn.id
				    where (
				              SUBSTRING(serial_no, 5, 1) in ( 'A', 'B', 'F', 'G' )
				              or (
				                     SUBSTRING(serial_no, 5, 1) = 'G'
				                     and dn.name in ( 'BV2HC045EFU-C       ', 'BV2HD045EFU-CE2     ', 'BV2HD070EFU-CE2    ',
				                                      'BV2HC045EFU-CE2     '
				                                    )
				                 ) --add 2023/03/24 time : 11.56
				          )
				          and surpluses.location_id != 0
				          and tl.wip_state in ( 20, 70, 100 )
				          and tl.quality_state = 0
				          and surpluses.in_stock = 2
				          and dn.name = allocat.ROHM_Model_Name
				          and dn.rank = allocat.Rank
				          and surpluses.qc_instruction = allocat.Tomson3
				          and allocat.LotNo != surpluses.serial_no --lot ใน Allocat ต้อง ไม่มีอยู่ใน Surpluses
						  and surpluses.created_at >= (getdate() - 1095)
				    order by surpluses.serial_no asc
				) as surpluses
				where lots.id = @lot_id
				and substring(allocat.LotNo, 0, 3) >= 21
			END
			ELSE
			BEGIN
				select 
				allocat.LotNo as lot_no,
				lots.qty_pass,
				isnull(trim(surpluses.serial_no), '-') as Hasuu_LotNo,
				isnull(surpluses.MNo, '') as MNo_H_Stock,
				isnull(surpluses.pcs, '-') as Hasuu_Qty,
				datediff(year, surpluses.created_at, getdate()) as Over_Year,
				allocat.Type_Name as Package,
				allocat.ROHM_Model_Name as Device,
				allocat.TIRank,
				allocat.rank,
				allocat.TPRank,
				allocat.SUBRank,
				allocat.PDCD,
				allocat.Mask,
				allocat.KNo,
				allocat.MNo as MNo_Standard,
				allocat.ORNo,
				isnull(allocat.Packing_Standerd_QTY, '-') as Standerd_QTY,
				allocat.Tomson1,
				allocat.Tomson2,
				allocat.Tomson3,
				allocat.WFLotNo,
				allocat.LotNo_Class,
				allocat.User_Code,
				allocat.Product_Control_Cl_1,
				allocat.Product_Class,
				allocat.Production_Class,
				allocat.Rank_No,
				allocat.HINSYU_Class,
				allocat.Label_Class,
				allocat.OUT_OUT_FLAG,
				device_names.name as DeviceTpRank,
				isnull(lots.qty_pass + surpluses.pcs, '-') as Total,
				isnull((lots.qty_pass + surpluses.pcs) / (allocat.Packing_Standerd_QTY), '-') as Reel,
				isnull((lots.qty_pass + surpluses.pcs) % (allocat.Packing_Standerd_QTY), '-') as TotalHasuu,
				assy_orders.order_no as OrderNo,
				isnull(surpluses.location_name, 'nolocation') as location_name,
				isnull(surpluses.location_address, 'noaddress') as location_address
				from APCSProDB.method.allocat_temp as allocat
				    inner join APCSProDB.trans.lots
				        on lots.lot_no = allocat.LotNo
				    left join APCSProDB.robin.assy_orders
				        on assy_orders.id = lots.order_id
				    inner join APCSProDB.method.device_names
				        on lots.act_device_name_id = device_names.id
				    cross apply
				(
				    select top 1
				        surpluses.*,
				        locations.name as location_name,
				        locations.address as location_address,
				        tl.wip_state,
				        dn.name as ROHM_Model_Name,
				        isnull(dn.rank, '') as Rank_dn,
				        surpluses.qc_instruction as Tomson_Mark_3,
				        surpluses.mark_no as MNo
				    from APCSProDB.trans.surpluses
				        left join APCSProDB.trans.lots as tl
				            on tl.lot_no = surpluses.serial_no
				        left join APCSProDB.trans.locations as locations
				            on surpluses.location_id = locations.id
				        left join APCSProDB.method.device_names as dn
				            on tl.act_device_name_id = dn.id
				    where (
				              SUBSTRING(serial_no, 5, 1) in ( 'A', 'B', 'F' ,'G' )
				              or (
				                     SUBSTRING(serial_no, 5, 1) = 'G'
				                     and dn.name in ( 'BV2HC045EFU-C       ', 'BV2HD045EFU-CE2     ', 'BV2HD070EFU-CE2    ',
				                                      'BV2HC045EFU-CE2     '
				                                    )
				                 ) --add 2023/03/24 time : 11.56
				          )
				          and surpluses.location_id != 0
				          and tl.wip_state in ( 20, 70, 100 )
				          and tl.quality_state = 0
				          and surpluses.in_stock = 2
				          and dn.name = allocat.ROHM_Model_Name
				          and dn.rank = allocat.Rank
				          and surpluses.qc_instruction = allocat.Tomson3
				          and allocat.LotNo != surpluses.serial_no --lot ใน Allocat ต้อง ไม่มีอยู่ใน Surpluses
						  and surpluses.created_at >= (getdate() - 1095)
				    order by surpluses.serial_no asc
				) as surpluses
				where lots.id = @lot_id
				and substring(allocat.LotNo, 0, 3) >= 21
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
				select 
				allocat.LotNo as lot_no,
				lots.qty_pass,
				isnull(trim(surpluses.serial_no), '-') as Hasuu_LotNo,
				isnull(surpluses.MNo, '') as MNo_H_Stock,
				isnull(surpluses.pcs, '-') as Hasuu_Qty,
				isnull(surpluses.location_name, 'No Location') as location_name,
				isnull(CAST(surpluses.location_address as varchar(10)), 'No Address') as location_address
				from APCSProDB.method.allocat
				    inner join APCSProDB.trans.lots
				        on lots.lot_no = allocat.LotNo
				    left join APCSProDB.robin.assy_orders
				        on assy_orders.id = lots.order_id
				    inner join APCSProDB.method.device_names
				        on lots.act_device_name_id = device_names.id
				    outer apply
				(
				    select top 1
				        surpluses.*,
				        locations.name as location_name,
				        locations.address as location_address,
				        tl.wip_state,
				        dn.name as ROHM_Model_Name,
				        isnull(dn.rank, '') as Rank_dn,
				        surpluses.qc_instruction as Tomson_Mark_3,
				        surpluses.mark_no as MNo
				    from APCSProDB.trans.surpluses
				        left join APCSProDB.trans.lots as tl
				            on tl.lot_no = surpluses.serial_no
				        left join APCSProDB.trans.locations as locations
				            on surpluses.location_id = locations.id
				        left join APCSProDB.method.device_names as dn
				            on tl.act_device_name_id = dn.id
				    where (
				              SUBSTRING(serial_no, 5, 1) in ( 'A', 'B','F','G' )
				              or (
				                     SUBSTRING(serial_no, 5, 1) = 'G'
				                     and dn.name in ( 'BV2HC045EFU-C       ', 'BV2HD045EFU-CE2     ', 'BV2HD070EFU-CE2    ',
				                                      'BV2HC045EFU-CE2     '
				                                    )
				                 ) --add 2023/03/24 time : 11.56
				          )
				          --and surpluses.location_id != 0
				          and tl.wip_state in ( 20, 70, 100 )
				          and tl.quality_state = 0
				          and surpluses.in_stock = 2
				          and dn.name = allocat.ROHM_Model_Name
				          and dn.rank = allocat.Rank
				          and surpluses.qc_instruction = allocat.Tomson3
				          and allocat.LotNo != surpluses.serial_no --lot ใน Allocat ต้อง ไม่มีอยู่ใน Surpluses
						  and surpluses.created_at >= (getdate() - 1095)
				    order by iif(surpluses.location_id is null,1,0) asc, surpluses.serial_no asc
				) as surpluses
				where lots.id = @lot_id
				and substring(allocat.LotNo, 0, 3) >= 21
				and surpluses.serial_no is not null
			END
			ELSE
			BEGIN
				select 
				allocat.LotNo as lot_no,
				lots.qty_pass,
				isnull(trim(surpluses.serial_no), '-') as Hasuu_LotNo,
				isnull(surpluses.MNo, '') as MNo_H_Stock,
				isnull(surpluses.pcs, '-') as Hasuu_Qty,
				isnull(surpluses.location_name, 'No Location') as location_name,
				isnull(CAST(surpluses.location_address as varchar(10)), 'No Address') as location_address
				from APCSProDB.method.allocat_temp as allocat
				    inner join APCSProDB.trans.lots
				        on lots.lot_no = allocat.LotNo
				    left join APCSProDB.robin.assy_orders
				        on assy_orders.id = lots.order_id
				    inner join APCSProDB.method.device_names
				        on lots.act_device_name_id = device_names.id
				    outer apply
				(
				    select top 1
				        surpluses.*,
				        locations.name as location_name,
				        locations.address as location_address,
				        tl.wip_state,
				        dn.name as ROHM_Model_Name,
				        isnull(dn.rank, '') as Rank_dn,
				        surpluses.qc_instruction as Tomson_Mark_3,
				        surpluses.mark_no as MNo
				    from APCSProDB.trans.surpluses
				        left join APCSProDB.trans.lots as tl
				            on tl.lot_no = surpluses.serial_no
				        left join APCSProDB.trans.locations as locations
				            on surpluses.location_id = locations.id
				        left join APCSProDB.method.device_names as dn
				            on tl.act_device_name_id = dn.id
				    where (
				              SUBSTRING(serial_no, 5, 1) in ( 'A', 'B','F','G' )
				              or (
				                     SUBSTRING(serial_no, 5, 1) = 'G'
				                     and dn.name in ( 'BV2HC045EFU-C       ', 'BV2HD045EFU-CE2     ', 'BV2HD070EFU-CE2    ',
				                                      'BV2HC045EFU-CE2     '
				                                    )
				                 ) --add 2023/03/24 time : 11.56
				          )
				          --and surpluses.location_id != 0
				          and tl.wip_state in ( 20, 70, 100 )
				          and tl.quality_state = 0
				          and surpluses.in_stock = 2
				          and dn.name = allocat.ROHM_Model_Name
				          and dn.rank = allocat.Rank
				          and surpluses.qc_instruction = allocat.Tomson3
				          and allocat.LotNo != surpluses.serial_no --lot ใน Allocat ต้อง ไม่มีอยู่ใน Surpluses
						  and surpluses.created_at >= (getdate() - 1095)
				    order by iif(surpluses.location_id is null,1,0) asc, surpluses.serial_no asc
				) as surpluses
				where lots.id = @lot_id
				and substring(allocat.LotNo, 0, 3) >= 21
				and surpluses.serial_no is not null
			END
			---------------------------------------------------------------------------------
			-- # >> CELLCON
			---------------------------------------------------------------------------------
		END
END
