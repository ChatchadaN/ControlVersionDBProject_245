-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_data_cancel_mix_lot_test_002]
	-- Add the parameters for the stored procedure here
	@lotno varchar(10) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @lot_id int = 0
		, @device_slip_id int = NULL ---add by kpanomsai 2022/03/18 time : 15.10
		, @step_no int = NULL  ---add by kpanomsai 2022/03/18 time : 15.10
		, @status_cancel int = NULL ---add by kpanomsai 2022/03/18 time : 15.10 (1:Cancel,2:not Cancel)
	DECLARE @process_state int = 0
	DECLARE @qty_all int = 0
	DECLARE @qty_shipment int = 0
	DECLARE @qty_hasuu int = 0
	DECLARE @status_lot nvarchar(50)  --status = 1 show data lot master, status = 2 show list lot member

	select @lot_id = lots.id 
	,@process_state = case when lots.is_special_flow = 1 then spf.process_state else lots.process_state end
	,@qty_all = lots.qty_out + lots.qty_hasuu
	,@qty_shipment = lots.qty_out
	,@qty_hasuu = lots.qty_hasuu
	,@device_slip_id = device_slip_id ---add by kpanomsai 2022/03/18 time : 15.10
	from APCSProDB.trans.lots 
	left join APCSProDB.trans.special_flows as spf on lots.special_flow_id = spf.id
	where lot_no = @lotno

	-----get data from is and check lsi
	DECLARE @check_is int = 0
	DECLARE @check_lsi int = 0
	DECLARE @sql NVARCHAR(MAX)
	DECLARE @table_mix_hist table ( 
		[HASUU_LotNo] [varchar](10) NOT NULL,
		[LotNo] [varchar](10) NOT NULL,
		[Type_Name] [varchar](10) NULL,
		[ROHM_Model_Name] [varchar](20) NULL,
		[TPRank] [char](3) NULL,
		[Packing_Standerd_QTY] [int] NULL,
		[QTY] [int] NULL
	)
	SET @sql = 'SELECT * FROM OPENROWSET(''SQLNCLI'', ''Server= 10.28.1.144;Database=DBLSISHT;Uid=ship;Pwd=ship'',' + 
				'''SELECT HASUU_LotNo,LotNo,Type_Name,ROHM_Model_Name,TPRank,Packing_Standerd_QTY,QTY FROM [DBLSISHT].[dbo].[MIX_HIST] '+ 
				'WHERE HASUU_LotNo = ''''' + @lotno + ''''''')';

	INSERT INTO @table_mix_hist EXEC sp_executesql @sql;

	set @check_is = (select count(HASUU_LotNo) from @table_mix_hist)
	set @check_lsi = (select count(lot_id) from APCSProDB.trans.lot_combine where lot_id = @lot_id)
	-----get data from is and check lsi

	-----------------check flow ogi & check cancel-----------------
	---add by kpanomsai 2022/03/18 time : 15.10
	-----------------check flow ogi-----------------
	select @step_no = device_flows.step_no
	from APCSProDB.method.device_flows
	inner join APCSProDB.method.jobs on device_flows.job_id = jobs.id
	where device_slip_id = @device_slip_id
		and jobs.name = 'OUT GOING INSP'
	order by device_flows.step_no
	-----------------check cancel-----------------
	if @step_no is null
	begin
		-----#no flow OGI
		set @status_cancel = 1
	end
	else begin
		-----#have OGI
		-----------------check Shipped
		if exists (
			select item_labels.label_eng
			from APCSProDB.trans.lot_process_records
			inner join APCSProDB.trans.item_labels on item_labels.name = 'lot_process_records.record_class'
				and lot_process_records.record_class = item_labels.val
			where lot_id = @lot_id
				and record_class = 7
		)
		begin
			-----#Shipped  --> if status_cancel = 2 no cancel lot mix 
			set @status_cancel = 2
		end
		else begin
			-----#Not shipped  --> else status_cancel = 1 is cancel ok
			set @status_cancel = 1
		end
		-----------------check Shipped
	end
	-----------------check flow ogi & check cancel-----------------

	IF @lotno != ''
	BEGIN
		IF @process_state = 2
		BEGIN
			select @status_lot = N'2' --LOT PROCESSING
		END
		ELSE IF @process_state = 1
		BEGIN
			select @status_lot = N'1' --LOT SETUP
		END
		ELSE
		BEGIN
			select @status_lot = N'3'  --LOT NORMAL cancel ได้
		END
		-----------------------------------------------------------------------
		IF (@check_is > 0 and @check_lsi > 0)
		BEGIN
			IF @check_is > 1
			BEGIN
				delete from @table_mix_hist
				where HASUU_LotNo = LotNo;
			END

			--select N'mixing or tg มี data ทั้ง lsi and is'
			select ROW_NUMBER() OVER(ORDER BY sur.pcs) AS row_id  
				,lot_master.lot_no as lot_master
				, case 
					when lot_member.lot_no is not null then lot_member.lot_no
					else mix_hist.LotNo 
				end as lot_member
				, CAST(pk.short_name as char(10)) as package_name
				, CAST(dv.name as char(20)) as device_name
				, case when CAST(dv.tp_rank as char(2)) is null then CAST('' as char(2)) else CAST(dv.tp_rank as char(2)) end as TPRank
				, dv.pcs_per_pack as packing_standard
				, @qty_all as qty_pass
				, @qty_shipment as qty_shipment
				, @qty_hasuu as qty_hasuu
				, @status_lot as status_lot
				, lot_master.wip_state --add value date 2022/03/17 time : 15.53
				, item_labels.label_eng + ' (' + cast(lot_master.wip_state as varchar) + ')' AS wip_state_detail --add value date 2022/03/17 time : 16.10
				, @status_cancel as [status_cancel]
				, case when lot_master.production_category is null then 0 else lot_master.production_category end as production_category --add value date 2022/05/24 time : 15.55
				, case when lot_master.carrier_no is null then '' else lot_master.carrier_no end as carrier_no
				, case when lot_master.e_slip_id is null then '' else lot_master.e_slip_id end as e_slip_id
			from APCSProDB.trans.lots as lot_master
			left join APCSProDB.trans.lot_combine as cb on lot_master.id = cb.lot_id
			left join APCSProDB.trans.lots as lot_member on cb.member_lot_id = lot_member.id
			inner join APCSProDB.method.device_names as dv on lot_master.act_device_name_id = dv.id
			inner join APCSProDB.method.packages as pk on dv.package_id = pk.id
			left join APCSProDB.trans.surpluses as sur on cb.member_lot_id = sur.lot_id
			left join APCSProDB.trans.item_labels on item_labels.name = 'lots.wip_state' --join 2022/03/17 time : 16.10
				and lot_master.wip_state = item_labels.val
			left join @table_mix_hist as mix_hist on lot_master.lot_no = mix_hist.LotNo
			where lot_master.id = @lot_id
		END
		ELSE IF (@check_is > 0 and @check_lsi = 0)  --Add Condition Check data Lsi is null but data is is not null (นำ data ฝั่ง IS มาใช้งาน) 2022/06/24 time : 11.20
		BEGIN
			--select 'check is > 0 and check lsi = 0'
			IF @check_is > 1
			BEGIN
				delete from @table_mix_hist
				where HASUU_LotNo = LotNo;
			END

			select ROW_NUMBER() OVER(ORDER BY mix_hist.QTY) AS row_id  
				,lot_master.lot_no as lot_master
				, mix_hist.LotNo as lot_member
				, CAST(mix_hist.Type_Name as char(10)) as package_name
				, CAST(mix_hist.ROHM_Model_Name as char(20)) as device_name
				, case when CAST(mix_hist.TPRank as char(2)) is null then CAST('' as char(2)) else CAST(mix_hist.TPRank as char(2)) end as TPRank
				, mix_hist.Packing_Standerd_QTY as packing_standard
				, @qty_all as qty_pass
				, @qty_shipment as qty_shipment
				, @qty_hasuu as qty_hasuu
				, @status_lot as status_lot
				, lot_master.wip_state --add value date 2022/03/17 time : 15.53
				, item_labels.label_eng + ' (' + cast(lot_master.wip_state as varchar) + ')' AS wip_state_detail --add value date 2022/03/17 time : 16.10
				, @status_cancel as [status_cancel]
				, case when lot_master.production_category is null then 0 else lot_master.production_category end as production_category --add value date 2022/05/24 time : 15.55
				, case when lot_master.carrier_no is null then '' else lot_master.carrier_no end as carrier_no
				, case when lot_master.e_slip_id is null then '' else lot_master.e_slip_id end as e_slip_id
			from APCSProDB.trans.lots as lot_master
			left join APCSProDB.trans.item_labels on item_labels.name = 'lots.wip_state' --join 2022/03/17 time : 16.10
				and lot_master.wip_state = item_labels.val
			left join @table_mix_hist as mix_hist on lot_master.lot_no = mix_hist.HASUU_LotNo
			--left join APCSProDB.trans.surpluses as sur on mix_hist.LotNo = sur.serial_no
			where lot_master.id = @lot_id
		END
		BEGIN
			--select 'no mix but is work re-surpluses or hasuu stock in' add condition support work re-surpluses and hasuu stock in : 2022/06/27 time : 10.31
			select ROW_NUMBER() OVER(ORDER BY sur.pcs) AS row_id  
				,lot_master.lot_no as lot_master
				, case 
					when lot_member.lot_no is not null then lot_member.lot_no
					else mix_hist.LotNo 
				end as lot_member
				, CAST(pk.short_name as char(10)) as package_name
				, CAST(dv.name as char(20)) as device_name
				, case when CAST(dv.tp_rank as char(2)) is null then CAST('' as char(2)) else CAST(dv.tp_rank as char(2)) end as TPRank
				, dv.pcs_per_pack as packing_standard
				, @qty_all as qty_pass
				, @qty_shipment as qty_shipment
				, @qty_hasuu as qty_hasuu
				, @status_lot as status_lot
				, lot_master.wip_state --add value date 2022/03/17 time : 15.53
				, item_labels.label_eng + ' (' + cast(lot_master.wip_state as varchar) + ')' AS wip_state_detail --add value date 2022/03/17 time : 16.10
				, @status_cancel as [status_cancel]
				, case when lot_master.production_category is null then 0 else lot_master.production_category end as production_category --add value date 2022/05/24 time : 15.55
				, case when lot_master.carrier_no is null then '' else lot_master.carrier_no end as carrier_no
				, case when lot_master.e_slip_id is null then '' else lot_master.e_slip_id end as e_slip_id
			from APCSProDB.trans.lots as lot_master
			left join APCSProDB.trans.lot_combine as cb on lot_master.id = cb.lot_id
			left join APCSProDB.trans.lots as lot_member on cb.member_lot_id = lot_member.id
			inner join APCSProDB.method.device_names as dv on lot_master.act_device_name_id = dv.id
			inner join APCSProDB.method.packages as pk on dv.package_id = pk.id
			left join APCSProDB.trans.surpluses as sur on cb.member_lot_id = sur.lot_id
			left join APCSProDB.trans.item_labels on item_labels.name = 'lots.wip_state' --join 2022/03/17 time : 16.10
				and lot_master.wip_state = item_labels.val
			left join @table_mix_hist as mix_hist on lot_master.lot_no = mix_hist.LotNo
			where lot_master.id = @lot_id
		END

	END
			
END
