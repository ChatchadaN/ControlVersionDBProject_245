CREATE FUNCTION [atom].[fnc_get_flow](
	@lot_id int,
	@step_no int
)
    RETURNS @table_flow table (
		step_no varchar(30),
		back_step_no int,
		back_step_no_master int,
		flow_type int,
		status_add_flow int,
		step_no_now int
	)
AS
BEGIN
    insert into @table_flow 
	(
		step_no
		, back_step_no
		, back_step_no_master
		, flow_type
		, status_add_flow
		, step_no_now
	)
	select [flow].[step_no]
		, isnull(lead([flow].[step_no]) over (order by [flow].[step_no]),0) as [back_step_no]
		, [flow].[back_step_no] as [back_step_no_master]
		, [flow].[flow_type]
		, iif([flow_current].[step_no] <= @step_no,1,0) as [status_add_flow]
		, [flow_current].[step_no] as [step_no_now]
	from (
		select step_no, 1 as flow_type, next_step_no as back_step_no
		from APCSProDB.method.device_flows 
		where device_slip_id = (select device_slip_id from APCSProDB.trans.lots where lots.id = @lot_id ) and is_skipped != 1
		union all
		select lot_special_flows.step_no, 2 as flow_type, special_flows.back_step_no
		from APCSProDB.trans.special_flows
		left join APCSProDB.trans.lot_special_flows on special_flows.id = lot_special_flows.special_flow_id
		where special_flows.lot_id = @lot_id
	) as [flow]
	left join (
		select lots.id as lot_id, IIF(lot_special_flows.step_no is null,lots.step_no,lot_special_flows.step_no) as [step_no]
		from APCSProDB.trans.lots
		left join APCSProDB.trans.special_flows on lots.is_special_flow = 1
			and lots.special_flow_id = special_flows.id
		left join APCSProDB.trans.lot_special_flows on special_flows.id = lot_special_flows.special_flow_id
			and special_flows.step_no = lot_special_flows.step_no
	) [flow_current] on [flow_current].[lot_id] = @lot_id;

    return;
END;