-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_wip_lot_inventory]
	@lot_no VARCHAR(10) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	SELECT    ROW_NUMBER() OVER(ORDER BY lots.created_at) AS No	
					, lots.id		AS lot_id
					, ISNULL(lots.lot_no,'') AS lot_no
					, ISNULL([packages].name,'') AS pack_name
					, ISNULL(device_names.assy_name,'') AS device_name
					, ISNULL(loca.address,'') AS rack_address
					, ISNULL(loca.name,'') AS rack_location
					,'WIP'  AS status_lot
					, iif([lots].[is_special_flow] = 1,[process_special].[name],[processes].[name]) as [process]
					, iif([lots].[is_special_flow] = 1,[item_process_state_sp].[label_eng],[item_process_state].[label_eng]) as [process_state]
					, [item_quality_state].[label_eng] as [quality_state] 
					, [lots].[qty_in] as [total]
					, [lots].[qty_pass] as [good]
					, [lots].[qty_fail] as [NG]
					, ISNULL(class.class_no,'') AS [classification_no]
					--, ISNULL(sheet_rack_inventory.class_no,'') AS [classification_no]
			FROM [APCSProDB].[trans].lots WITH (NOLOCK)
			INNER JOIN APCSProDB.method.device_flows
			ON lots.device_slip_id = device_flows.device_slip_id
			AND  device_flows.step_no =  lots.step_no
			LEFT JOIN [APCSProDB].[trans].[special_flows] 
			ON [special_flows].lot_id = lots.id 
			AND [special_flows].id	  = lots.special_flow_id
			AND lots.is_special_flow  = 1
			left join [APCSProDB].[trans].[lot_special_flows] with (nolock) 
			on [lot_special_flows].[special_flow_id] = [special_flows].[id] 
			and  [special_flows].[step_no] = [lot_special_flows].[step_no]
			left join [APCSProDB].[method].[jobs] as [job_special] with (nolock) 
			on [job_special].[id] = [lot_special_flows].[job_id]
			LEFT JOIN [APCSProDB].[trans].[lot_inventory] WITH (NOLOCK) 
			ON lots.lot_no = UPPER([lot_inventory].[lot_no])
			INNER JOIN [APCSProDB].[method].[device_names] WITH (NOLOCK) 
			ON lots.act_device_name_id = [device_names].[id]
			INNER JOIN [APCSProDB].[method].[packages] WITH (NOLOCK) 
			ON lots.[act_package_id] = [packages].[id] and packages.package_group_id <> 35 and packages.package_group_id <> 1
			INNER JOIN [APCSProDB].[method].[jobs] WITH (NOLOCK) 
			ON lots.act_job_id = [jobs].[id]
			INNER JOIN [APCSProDB].[trans].[days] as [day_indate] with (nolock) 
			on [day_indate].[id] = [lots].[in_plan_date_id]
			inner join [APCSProDB].[method].[processes] with (nolock) on [processes].[id] = [jobs].[process_id]
			LEFT JOIN APCSProDB.trans.locations AS loca 
			ON lots.location_id = loca.id
			LEFT JOIN APCSProDB.inv.class_locations as rack 
			ON rack.location_name =  loca.name 
			LEFT JOIN APCSProDB.inv.Inventory_classfications as class 
			ON class.id = rack.class_id
			--LEFT JOIN  APCSProDWH.atom.sheet_rack_inventory
			--ON sheet_rack_inventory.location =   loca.name
			left join [APCSProDB].[method].[processes] as [process_special] with (nolock) 
			on [process_special].[id] = [job_special].[process_id]
			left join [APCSProDB].[trans].[item_labels] as [item_process_state] with (nolock) 
			on [item_process_state].[name] = 'lots.process_state' 
			and [item_process_state].[val] = [lots].[process_state]
			left join [APCSProDB].[trans].[item_labels] as [item_process_state_sp] with (nolock) 
			on [item_process_state_sp].[name] = 'lots.process_state' 
			and [item_process_state_sp].[val] = [special_flows].[process_state]
			left join [APCSProDB].[trans].[item_labels] as [item_quality_state] with (nolock) 
			on [item_quality_state].[name] = 'lots.quality_state' 
			and [item_quality_state].[val] = [lots].[quality_state]
			WHERE   [lots].[wip_state] in (10,20,0) 
			and [day_indate].[date_value] <= convert(date, getdate())
			AND [lot_inventory].[lot_no]  IS NULL
			AND [device_names].[is_assy_only] in (0,1)

END
