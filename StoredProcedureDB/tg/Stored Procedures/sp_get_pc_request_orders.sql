-- =============================================
-- =============================================
CREATE PROCEDURE [tg].[sp_get_pc_request_orders]
	-- Add the parameters for the stored procedure here
	 @order_id_val int = null
	,@is_condition int = 0  --#0:show the order wip all, #1:show order by order, #2:show order success all

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF @is_condition = 0  --show the order wip all
	BEGIN
		SELECT 
			  [pc_order].[order_id]
			, [pc_order].[id] AS auto_order_id
			, [pc_order].[package_name]
			, [pc_order].[device_name]
			, [pc_order].[date] AS [request_date]
			, [pc_order].[ship_date]
			, [pc_order].[ship_date] as shipment_in_cps
			, case when [pc_order].[condition_type] = 0 then 'ALL SHIP OUT'
			       when [pc_order].[condition_type] = 1 then 'KEEP QTY'
				   else 'IS NOT CONDITION' end as condition_type
			, [pc_order].[pdcd] AS [ship_out_to]
			, [pc_order].[attachment_need] AS [customer_need]
			, [pc_order].[rank] AS [request_rank]
			, [pc_order].[qc_instruction] 
			, [pc_order].[remark]
			, [pc_order].[is_urgent] AS [request_urgent_type]
			, [pc_order].[is_state] --1 is create lot success , 0 is not create lot
			, case when [pc_order].[is_state] = 0 then '-'
				   when [pc_order].[is_state] = 1 then 'SUCCESS'
				   else 'IS NOT CONDITION' end AS is_state_order
			, [pc_order].[qty] AS [reply_qty]
			, [pc_order].[created_at]
			, [pc_order].[created_by]
			, [pc_order].[updated_at]
			, [pc_order].[updated_by]
			, [users].[name] AS name_request
			, [pc_order].[section_id] AS section_id
			, [sec].[name] AS section_name
			, [lot].[id] AS lot_id
			, TRIM([lot].[lot_no]) AS lot_create
			, [pc_order].[month_year]
			, IIF([lot].[wip_state] is null,0,[lot].[wip_state]) AS wip_state
			, [pc_order].[is_shipment]
		FROM [APCSProDB].[trans].[pc_request_orders] as pc_order
		inner join APCSProDB.man.users on pc_order.created_by = users.id
		left join APCSProDB.man.sections as sec on pc_order.section_id = sec.id
		left join APCSProDB.trans.lots as lot on pc_order.lot_id = lot.id
		WHERE ((lot.wip_state != 200) OR lot.wip_state IS NULL)
				and [pc_order].[is_state] = 0
		ORDER BY [pc_order].[is_urgent] DESC,[pc_order].[date] ASC
	END
	ELSE IF @is_condition = 2
	BEGIN
		SELECT 
			  [pc_order].[order_id]
			, [pc_order].[id] AS auto_order_id
			, [pc_order].[package_name]
			, [pc_order].[device_name]
			, [pc_order].[date] AS [request_date]
			, [pc_order].[ship_date]
			, [pc_order].[ship_date] as shipment_in_cps
			, case when [pc_order].[condition_type] = 0 then 'ALL SHIP OUT'
			       when [pc_order].[condition_type] = 1 then 'KEEP QTY'
				   else 'IS NOT CONDITION' end as condition_type
			, [pc_order].[pdcd] AS [ship_out_to]
			, [pc_order].[attachment_need] AS [customer_need]
			, [pc_order].[rank] AS [request_rank]
			, [pc_order].[qc_instruction] 
			, [pc_order].[remark]
			, [pc_order].[is_urgent] AS [request_urgent_type]
			, [pc_order].[is_state] --1 is create lot success , 0 is not create lot
			, case when [pc_order].[is_state] = 0 then '-'
				   when [pc_order].[is_state] = 1 then 'SUCCESS'
				   else 'IS NOT CONDITION' end AS is_state_order
			, [pc_order].[qty] AS [reply_qty]
			, [pc_order].[created_at]
			, [pc_order].[created_by]
			, [pc_order].[updated_at]
			, [pc_order].[updated_by]
			, [users].[name] AS name_request
			, [pc_order].[section_id] AS section_id
			, [sec].[name] AS section_name
			, [lot].[id] AS lot_id
			, TRIM([lot].[lot_no]) AS lot_create
			, [pc_order].[month_year]
			, IIF([lot].[wip_state] is null,0,[lot].[wip_state]) AS wip_state
			, [pc_order].[is_shipment]
		FROM [APCSProDB].[trans].[pc_request_orders] as pc_order
		inner join APCSProDB.man.users on pc_order.created_by = users.id
		left join APCSProDB.man.sections as sec on pc_order.section_id = sec.id
		left join APCSProDB.trans.lots as lot on pc_order.lot_id = lot.id
		WHERE ((lot.wip_state != 200) OR lot.wip_state IS NULL)
				and [pc_order].[is_state] = 1
		ORDER BY [pc_order].[is_urgent] DESC,[pc_order].[date] ASC
	END
	ELSE IF @is_condition = 1 --show order by order
	BEGIN
		SELECT 
			  [pc_order].[order_id]
			, [pc_order].[id] AS auto_order_id
			, [pc_order].[package_name]
			, [pc_order].[device_name]
			, [pc_order].[date] AS [request_date]
			, [pc_order].[ship_date]
			, [pc_order].[ship_date] as shipment_in_cps
			, case when [pc_order].[condition_type] = 0 then 'ALL SHIP OUT'
			       when [pc_order].[condition_type] = 1 then 'KEEP QTY'
				   else 'IS NOT CONDITION' end as condition_type
			, [pc_order].[pdcd] AS [ship_out_to]
			, [pc_order].[attachment_need] AS [customer_need]
			, [pc_order].[rank] AS [request_rank]
			, [pc_order].[qc_instruction] 
			, [pc_order].[remark]
			, [pc_order].[is_urgent] AS [request_urgent_type]
			, [pc_order].[is_state] --1 is create lot success , 0 is not create lot
			, case when [pc_order].[is_state] = 0 then '-'
				   when [pc_order].[is_state] = 1 then 'SUCCESS'
				   else 'IS NOT CONDITION' end AS is_state_order
			, [pc_order].[qty] AS [reply_qty]
			, [pc_order].[created_at]
			, [pc_order].[created_by]
			, [pc_order].[updated_at]
			, [pc_order].[updated_by]
			, [users].[name] As name_request
			, [pc_order].[section_id] AS section_id
			, [sec].[name] AS section_name
			, [lot].[id] AS lot_id
			, TRIM([lot].[lot_no]) AS lot_create
			, [pc_order].[month_year]
			, IIF([lot].[wip_state] is null,0,[lot].[wip_state]) AS wip_state
			, [pc_order].[is_shipment]
		FROM [APCSProDB].[trans].[pc_request_orders] as pc_order
		inner join APCSProDB.man.users on pc_order.created_by = users.id
		left join APCSProDB.man.sections as sec on pc_order.section_id = sec.id
		left join APCSProDB.trans.lots as lot on pc_order.lot_id = lot.id
		WHERE [pc_order].[id] = @order_id_val
			AND (lot.wip_state != 200 OR lot.wip_state IS NULL)
		ORDER BY [pc_order].[date] ASC, [pc_order].[is_urgent] DESC
	END

END
