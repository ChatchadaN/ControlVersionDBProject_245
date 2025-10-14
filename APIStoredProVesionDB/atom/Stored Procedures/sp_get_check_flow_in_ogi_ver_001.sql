
CREATE PROCEDURE [atom].[sp_get_check_flow_in_ogi_ver_001]	
	-- Add the parameters for the stored procedure here	
	@lot_id int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -------------------------------------------------------------------------------------------------
	if exists(select 1 from [APCSProDB].[trans].[lots] where id = @lot_id)
	begin
		----------------------------------------------------------------------------------
		declare	@step_no int = null
   
		select @step_no = isnull([lot_special_flows].[step_no],[lots].[step_no]) ---as [step_no]
		from [APCSProDB].[trans].[lots]                                                                                   
		left join [APCSProDB].[trans].[special_flows] on [lots].[is_special_flow] = 1                                    
			and [lots].[special_flow_id] = [special_flows].[id]                                                            
		left join [APCSProDB].[trans].[lot_special_flows] on [special_flows].[id] = [lot_special_flows].[special_flow_id] 
			and [special_flows].[step_no] = [lot_special_flows].[step_no]                                                 
		where lots.id = @lot_id;

		if exists(
			select check_data.step_no
			from (
				select flow.step_no,j.name as job_name,lpr.record_class
				from (
					select df.step_no,df.job_id,df.act_process_id 
					from APCSProDB.trans.lots as l
					inner join APCSProDB.method.device_flows as df on l.device_slip_id = df.device_slip_id
						and df.is_skipped != 1
					where l.id = @lot_id
					union all
					select lsf.step_no,lsf.job_id,lsf.act_process_id
					from APCSProDB.trans.special_flows as sf
					inner join APCSProDB.trans.lot_special_flows as lsf on sf.id = lsf.special_flow_id
					where sf.lot_id = @lot_id
				) as flow
				inner join APCSProDB.method.jobs as j on flow.job_id = j.id
				left join APCSProDB.trans.lot_process_records as lpr on flow.step_no = lpr.step_no
					and record_class = 2 -- 2 End lot
					and lpr.lot_id = @lot_id
			) as check_data
			where record_class is null
				and step_no < @step_no
		)
		begin
			------------------------------------------------------------------------------
			select 'FALSE' as Is_Pass
				, 'The production flow is incomplete. !!' AS Error_Message_ENG
				, N'flow การผลิตดำเนินการไม่ครบ !!' AS Error_Message_THA 
				, '' AS Handling
			------------------------------------------------------------------------------
		end
		else begin
			------------------------------------------------------------------------------
			select 'TRUE' as Is_Pass
				, '' AS Error_Message_ENG
				, '' AS Error_Message_THA 
				, '' AS Handling
			------------------------------------------------------------------------------
		end
		----------------------------------------------------------------------------------
	end
	else begin
		------------------------------------------------------------------------------
		select 'FALSE' as Is_Pass
			, 'lot no not found. !!' AS Error_Message_ENG
			, N'ไม่พบ lot no !!' AS Error_Message_THA 
			, '' AS Handling
		------------------------------------------------------------------------------
	end
    -------------------------------------------------------------------------------------------------
END

