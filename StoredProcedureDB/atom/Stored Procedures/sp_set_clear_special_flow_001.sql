-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_clear_special_flow_001]
	-- Add the parameters for the stored procedure here
	@lot_id int,
	@special_id int,
	@flowfon int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	
	DECLARE @counter int = 0
	DECLARE @run_status varchar(50)
	-- Insert statements for procedure here
	select @counter = count([special_flows].[id])
	from [APCSProDB].[trans].[lot_special_flows]
	left join
	(
		select [LotDetail].[record_class]
		, [LotDetail].[step_no]
		, [LotDetail].[qty_in]
		, [LotDetail].[qty_pass]
		, [LotDetail].[qty_fail]
		, [LotDetail].[qty_frame_in]
		, [LotDetail].[qty_frame_pass]
		, [LotDetail].[qty_frame_fail]
		, [LotDetail].[machine_id]
		, [LotDetail].[carrier_no]
		, [LotDetail].[next_carrier_no]
		, [LotDetail].[name]
		, [LotDetail].[emp_num]
		, [LotStart].[StartTime]
		, case when ([LotStart].[StartTime] <= [LotEnd].[EndTime]) then cast([LotEnd].[EndTime] as datetime2) end as EndTime
		from
		(
			select [step_no], [machine_id], MAX([id]) as max_id
			from [APCSProDB].[trans].[lot_process_records]
			where [lot_id] = @lot_id
			group by [step_no], [machine_id]
		) as StepFlow
		inner join 
		(
			select [lot_process_records].[id]
			, [lot_process_records].[record_class]
			, [lot_process_records].[step_no]
			, [lot_process_records].[qty_in]
			, [lot_process_records].[qty_pass]
			, [lot_process_records].[qty_fail]
			, [lot_process_records].[qty_frame_in]
			, [lot_process_records].[qty_frame_pass]
			, [lot_process_records].[qty_frame_fail]
			, [lot_process_records].[machine_id]
			, [lot_process_records].[carrier_no]
			, [lot_process_records].[next_carrier_no]
			, [APCSProDB].[mc].[machines].[name]
			, [APCSProDB].[man].[users].[emp_num]
			from [APCSProDB].[trans].[lot_process_records]
			left join [APCSProDB].[mc].[machines] on [lot_process_records].[machine_id] = [machines].[id]
			left join [APCSProDB].[man].[users] on [lot_process_records].[updated_by] = [users].[id] 
			where [lot_id] = @lot_id
		) as LotDetail
		on LotDetail.id = StepFlow.max_id
	
		left join
		(
			select [step_no],[machine_id],MAX([recorded_at]) as StartTime
			from [APCSProDB].[trans].[lot_process_records]
			where [record_class] IN ('1','31') and [lot_id] = @lot_id
			group by [step_no],[machine_id]
		) as LotStart
		on LotDetail.step_no = LotStart.step_no and LotDetail.machine_id = LotStart.machine_id
	
		left join
		(
			select [step_no],[machine_id],MAX([recorded_at]) as EndTime
			from [APCSProDB].[trans].[lot_process_records]
			where [record_class] IN ('2','12','32') and [lot_id] = @lot_id
			group by [step_no],[machine_id]
		) as LotEnd
		on LotDetail.step_no = LotEnd.step_no and LotDetail.machine_id = LotEnd.machine_id
	) as LotFlow
	on [lot_special_flows].[step_no] = [LotFlow].[step_no]
	inner join [APCSProDB].[method].[jobs] on [lot_special_flows].[job_id] = [jobs].[id]
	left join [APCSProDB].[trans].[item_labels] as [item_labels1] on [item_labels1].[name] = 'lot_process_records.record_class' and [item_labels1].[val] = [LotFlow].[record_class]
	inner join [APCSProDB].[trans].[special_flows] on [special_flows].[id] = [lot_special_flows].[special_flow_id]
	where [special_flows].[lot_id] = @lot_id 
	and [special_flows].[id] = @special_id


	select 
		--@run_status = [item_labels1].[label_eng]
		@run_status = [item_labels1].[val]
	from [APCSProDB].[trans].[lot_special_flows]
	left join
	(
		select [LotDetail].[record_class]
		, [LotDetail].[step_no]
		, [LotDetail].[qty_in]
		, [LotDetail].[qty_pass]
		, [LotDetail].[qty_fail]
		, [LotDetail].[qty_frame_in]
		, [LotDetail].[qty_frame_pass]
		, [LotDetail].[qty_frame_fail]
		, [LotDetail].[machine_id]
		, [LotDetail].[carrier_no]
		, [LotDetail].[next_carrier_no]
		, [LotDetail].[name]
		, [LotDetail].[emp_num]
		, [LotStart].[StartTime]
		, case when ([LotStart].[StartTime] <= [LotEnd].[EndTime]) then cast([LotEnd].[EndTime] as datetime2) end as EndTime
		from
		(
			select [step_no], [machine_id], MAX([id]) as max_id
			from [APCSProDB].[trans].[lot_process_records]
			where [lot_id] = @lot_id
			group by [step_no], [machine_id]
		) as StepFlow
		inner join 
		(
			select [lot_process_records].[id]
			, [lot_process_records].[record_class]
			, [lot_process_records].[step_no]
			, [lot_process_records].[qty_in]
			, [lot_process_records].[qty_pass]
			, [lot_process_records].[qty_fail]
			, [lot_process_records].[qty_frame_in]
			, [lot_process_records].[qty_frame_pass]
			, [lot_process_records].[qty_frame_fail]
			, [lot_process_records].[machine_id]
			, [lot_process_records].[carrier_no]
			, [lot_process_records].[next_carrier_no]
			, [APCSProDB].[mc].[machines].[name]
			, [APCSProDB].[man].[users].[emp_num]
			from [APCSProDB].[trans].[lot_process_records]
			left join [APCSProDB].[mc].[machines] on [lot_process_records].[machine_id] = [machines].[id]
			left join [APCSProDB].[man].[users] on [lot_process_records].[updated_by] = [users].[id] 
			where [lot_id] = @lot_id
		) as LotDetail
		on LotDetail.id = StepFlow.max_id
	
		left join
		(
			select [step_no],[machine_id],MAX([recorded_at]) as StartTime
			from [APCSProDB].[trans].[lot_process_records]
			where [record_class] IN ('1','31') and [lot_id] = @lot_id
			group by [step_no],[machine_id]
		) as LotStart
		on LotDetail.step_no = LotStart.step_no and LotDetail.machine_id = LotStart.machine_id
	
		left join
		(
			select [step_no],[machine_id],MAX([recorded_at]) as EndTime
			from [APCSProDB].[trans].[lot_process_records]
			where [record_class] IN ('2','12','32') and [lot_id] = @lot_id
			group by [step_no],[machine_id]
		) as LotEnd
		on LotDetail.step_no = LotEnd.step_no and LotDetail.machine_id = LotEnd.machine_id
	) as LotFlow
	on [lot_special_flows].[step_no] = [LotFlow].[step_no]
	inner join [APCSProDB].[method].[jobs] on [lot_special_flows].[job_id] = [jobs].[id]
	left join [APCSProDB].[trans].[item_labels] as [item_labels1] on [item_labels1].[name] = 'lot_process_records.record_class' and [item_labels1].[val] = [LotFlow].[record_class]
	inner join [APCSProDB].[trans].[special_flows] on [special_flows].[id] = [lot_special_flows].[special_flow_id]
	where [special_flows].[lot_id] = @lot_id 
	and [special_flows].[id] = @special_id
	--where [device_flows].[device_slip_id] = (select device_slip_id from [APCSProDB].[trans].[lots] where [lots].[id] = @lot_id)

	-- 1 sp add by flow_patten_id > 1
	-- 2 sp has been processing
	-- 3 delete success
	IF(@flowfon = 366)
	BEGIN
		IF(@counter != 0)
		BEGIN
			IF(@run_status IS NULL or @run_status = 25 or @run_status = 23 or @run_status = 6)
			BEGIN
				SELECT 3 as status_id
				DELETE FROM [APCSProDB].[trans].[lot_special_flows]
				WHERE special_flow_id = @special_id
				DELETE FROM [APCSProDB].[trans].[special_flows]
				WHERE id = @special_id
				UPDATE [APCSProDB].[trans].[lots]
				SET [is_special_flow] = 0
				, [special_flow_id] = 0
				, [quality_state] = 0
				WHERE [id] = @lot_id
			END
			ELSE
			BEGIN
				SELECT 2 as status_id
			END
		END
		ELSE
		BEGIN
			SELECT 1 as status_id
		END
	END
	ELSE
	BEGIN
		IF(@counter = 1)
		BEGIN
			IF(@run_status IS NULL or @run_status = 25)
			BEGIN
				SELECT 3 as status_id
				DELETE FROM [APCSProDB].[trans].[lot_special_flows]
				WHERE special_flow_id = @special_id
				DELETE FROM [APCSProDB].[trans].[special_flows]
				WHERE id = @special_id
				UPDATE [APCSProDB].[trans].[lots]
				SET [is_special_flow] = 0
				, [special_flow_id] = 0
				, [quality_state] = 0
				WHERE [id] = @lot_id
			END
			ELSE
			BEGIN
				SELECT 2 as status_id
			END
		END
		ELSE
		BEGIN
			SELECT 1 as status_id
		END
	END
END


