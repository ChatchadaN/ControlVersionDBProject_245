-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_data_cancel_mix_lot_001]
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

		select 
		ROW_NUMBER() OVER(ORDER BY sur.pcs) AS row_id  
		,lot_ms.lot_no as lot_master
		,lot.lot_no as lot_member
		,CAST(pk.short_name as char(10)) as package_name
		,CAST(dv.name as char(20)) as device_name
		,case when CAST(dv.tp_rank as char(2)) is null then CAST('' as char(2)) else CAST(dv.tp_rank as char(2)) end as TPRank
		,dv.pcs_per_pack as packing_standard
		--show header
		,@qty_all as qty_pass
		,@qty_shipment as qty_shipment
		,@qty_hasuu as qty_hasuu
		,@status_lot as status_lot
		,lot_ms.wip_state --add value date 2022/03/17 time : 15.53
		,item_labels.label_eng + ' (' + cast(lot_ms.wip_state as varchar) + ')' AS wip_state_detail --add value date 2022/03/17 time : 16.10
		,@status_cancel as [status_cancel]
		from APCSProDB.trans.lot_combine as cb
		inner join APCSProDB.trans.lots as lot on cb.member_lot_id = lot.id
		inner join APCSProDB.trans.lots as lot_ms on cb.lot_id = lot_ms.id
		inner join APCSProDB.method.device_names as dv on lot.act_device_name_id = dv.id
		inner join APCSProDB.method.packages as pk on dv.package_id = pk.id
		left join APCSProDB.trans.surpluses as sur on cb.member_lot_id = sur.lot_id
		left join APCSProDB.trans.item_labels on item_labels.name = 'lots.wip_state' --join 2022/03/17 time : 16.10
			and lot_ms.wip_state = item_labels.val --join 2022/03/17 time : 16.10
		where cb.lot_id = @lot_id	
	END
			
END
