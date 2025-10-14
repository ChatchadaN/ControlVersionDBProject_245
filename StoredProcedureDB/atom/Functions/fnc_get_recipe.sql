CREATE FUNCTION [atom].[fnc_get_recipe](
	@lot_id int,
	@job_id int
)
    RETURNS @table_recipe table (
		recipe varchar(30)
	)
AS
BEGIN
   if (@job_id = 366)
		begin
			insert into @table_recipe (recipe)
			select case when isnull(LO.is_special_flow,0) = 1 then LS.recipe else DF.recipe end --as [recipe]
			from APCSProDB.trans.lots as LO
			inner join APCSProDB.method.device_flows as DF on DF.device_slip_id = LO.device_slip_id and DF.step_no = LO.step_no 
			left outer join APCSProDB.method.device_chips as DC on DC.device_slip_id = DF.device_slip_id 
			left outer join APCSProDB.trans.special_flows as SP on SP.id = LO.special_flow_id and LO.is_special_flow = 1 
			left outer join APCSProDB.trans.lot_special_flows as LS on LS.special_flow_id = SP.id and LS.step_no = SP.step_no 
			where LO.id = @lot_id

			--select @recipe as recipe
			return;
		end


		---1 หา flow จาก master flow
		insert into @table_recipe (recipe)
		select [recipe]
		from (
			select [device_flows].[step_no]
				, [device_flows].[job_id]
				, [device_flows].[recipe]
				, [jobs].[name]
			from [APCSProDB].[trans].[lots]
			inner join [APCSProDB].[method].[device_flows] on [device_flows].[device_slip_id] = [lots].[device_slip_id] 
			inner join [APCSProDB].[method].[jobs] on [device_flows].[job_id] = [jobs].[id]
			where [lots].[id] = @lot_id
		) as condition1
		where job_id = @job_id
		
		if exists (select * from @table_recipe)
		begin
			--select @recipe as recipe
			return;
		end

		--2 หา job common ใน where job_id เอา to_job_id ใช้ หาใน master flow
		insert into @table_recipe (recipe)
		select [recipe]
		from (
			select [device_flows].[step_no]
				, [job_commons].[job_id]
				, [jobs2].[name] as [job_name]
				, [device_flows].[recipe]
				, [job_commons].[to_job_id]
				, [jobs].[name] as [to_job_name]
			from [APCSProDB].[trans].[lots]
			inner join [APCSProDB].[method].[device_flows] on [device_flows].[device_slip_id] = [lots].[device_slip_id] 
			inner join [APCSProDB].[trans].[job_commons] on [device_flows].[job_id] = [job_commons].[to_job_id]
			inner join [APCSProDB].[method].[jobs] on [jobs].[id] = [job_commons].[to_job_id]
			inner join [APCSProDB].[method].[jobs] [jobs2] on [jobs2].[id] = [job_commons].[job_id]
			where [lots].[id] = @lot_id
		) as condition2
		where job_id = @job_id

		if exists (select * from @table_recipe)
		begin
			--select @recipe as recipe
			return;
		end

		--3 หา job common ใน where to_job_id เอา job_id ใช้ หาใน master flow
		insert into @table_recipe (recipe)
		select [recipe]
		from (
			select [device_flows].[step_no]
				, [device_flows].[job_id]
				, [jobs2].[name] as [job_name]
				, [device_flows].[recipe]
				, [job_commons].[to_job_id]
				, [jobs].[name] as [to_job_name]
			from [APCSProDB].[trans].[lots]
			inner join [APCSProDB].[method].[device_flows] on [device_flows].[device_slip_id] = [lots].[device_slip_id] 
			inner join [APCSProDB].[trans].[job_commons] on [device_flows].[job_id] = [job_commons].[job_id]
			inner join [APCSProDB].[method].[jobs] on [jobs].[id] = [job_commons].[to_job_id]
			inner join [APCSProDB].[method].[jobs] [jobs2] on [jobs2].[id] = [job_commons].[job_id]
			where [lots].[id] = @lot_id
		) as condition2
		where to_job_id = @job_id

		if exists (select * from @table_recipe)
		begin
			--select @recipe as recipe
			return;
		end

		return;
END;