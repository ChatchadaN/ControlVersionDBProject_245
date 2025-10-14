-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_delay_lot_condition_detail]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here

	DECLARE @date_value varchar(10)
	DECLARE @day_delay_condition int

	SET @date_value = convert(varchar(10), GETDATE(), 120)
	SET @day_delay_condition = (SELECT [daycondition] FROM [APCSProDWH].[cac].[day_delay_condition])

	DECLARE @table_delay_lot_condition_detail table ( 
		[lot_no] [varchar](10) NOT NULL,
		[status] [varchar](200) NULL,
		[problem_point] [varchar](200) NULL,
		[incharge] [varchar](50) NULL,
		[occure_date] [date] NULL,
		[plan_date] [date] NULL
	)

	insert into @table_delay_lot_condition_detail
	(
		[lot_no]
		,[status]
		,[problem_point]
		,[incharge]
		,[occure_date]
		,[plan_date]
	)
	select [lots].[lot_no]
		, [wip_monitor_no_movement_lot_detail].[status]
		, [wip_monitor_no_movement_lot_detail].[problem_point]
		, [wip_monitor_no_movement_lot_detail].[incharge]
		, NULL as [occure_date]
		, [wip_monitor_no_movement_lot_detail].[plan_date]
	from [APCSProDB].[trans].[lots]
	inner join [APCSProDB].[trans].[days] as [days1] on [days1].[id] = [lots].[in_plan_date_id]
	inner join [APCSProDB].[trans].[days] as [days2] on [days2].[id] = [lots].[modify_out_plan_date_id]
	left join [APCSProDWH].[cac].[wip_monitor_delay_lot_condition_detail] on [wip_monitor_delay_lot_condition_detail].[lot_no] = [lots].[lot_no]
	left join [APCSProDWH].[cac].[wip_monitor_no_movement_lot_detail] on [wip_monitor_no_movement_lot_detail].[lot_no] = [lots].[lot_no]
	where [lots].[wip_state] in ('20','10','0')
		and DATEDIFF(DAY,[days2].[date_value],@date_value) >= @day_delay_condition
		and [wip_monitor_delay_lot_condition_detail].[status] is null
		and [wip_monitor_delay_lot_condition_detail].[problem_point] is null
		and [wip_monitor_delay_lot_condition_detail].[incharge] is null
		and (
			[wip_monitor_no_movement_lot_detail].[status] is not null
			or [wip_monitor_no_movement_lot_detail].[problem_point] is not null
			or [wip_monitor_no_movement_lot_detail].[incharge] is not null
		)
	

	------------------------------------insert------------------------------------
	if exists(select 1 from @table_delay_lot_condition_detail)
	begin
		insert into [APCSProDWH].[cac].[wip_monitor_delay_lot_condition_detail] 
		(
			[lot_no]
			,[status]
			,[problem_point]
			,[incharge]
			,[occure_date]
			,[plan_date]
		)
		select [detail].[lot_no]
			,[detail].[status]
			,[detail].[problem_point]
			,[detail].[incharge]
			,[detail].[occure_date]
			,[detail].[plan_date] 
		from @table_delay_lot_condition_detail as [detail]
		left outer join [APCSProDWH].[cac].[wip_monitor_delay_lot_condition_detail] as [detail2] on [detail].[lot_no] = [detail2].[lot_no]
		where [detail2].[lot_no] is null
	end
	------------------------------------insert------------------------------------
		
END
