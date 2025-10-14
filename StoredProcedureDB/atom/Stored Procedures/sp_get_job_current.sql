-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_job_current]
	-- Add the parameters for the stored procedure here
	@lot_no varchar(10),
	@flow_pattern_id int = 0,
	@step_no int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	if (@flow_pattern_id = 0)
	begin
		select [lots].[step_no]
			, [lots].[job_name]
		from (
			select [lot_special_flows].[step_no] as [step_no]
				, [jobs].[name] as [job_name]
			from [APCSProDB].[trans].[lots] with (nolock)
			left join [APCSProDB].[trans].[special_flows] with (nolock) on [lots].[id] = [special_flows].[lot_id]
			left join [APCSProDB].[trans].[lot_special_flows] with (nolock) on [special_flows].[id] = [lot_special_flows].[special_flow_id]
			left join [APCSProDB].[method].[jobs] with (nolock) on [lot_special_flows].[job_id] = [jobs].[id]
			where [lots].[lot_no] = @lot_no
			union all
			select [device_flows].[step_no] as [step_no]
				, [jobs].[name] as [job_name]
			from [APCSProDB].[trans].[lots] with (nolock)
			inner join [APCSProDB].[method].[device_flows] with (nolock) on [lots].[device_slip_id] = [device_flows].[device_slip_id]
			left join [APCSProDB].[method].[jobs] with (nolock) on [device_flows].[job_id] = [jobs].[id]
			where [lots].[lot_no] = @lot_no
		) as [lots]
		where [lots].[step_no] = @step_no;
	end
	else
	begin
		declare @job_name varchar(max) = ''

		select @job_name = @job_name + CONCAT(iif(@job_name = '','',' -> '),[jobs].[name])
		from [APCSProDB].[method].[flow_patterns] with (nolock) 
		inner join [APCSProDB].[method].[flow_details] with (nolock) on [flow_patterns].[id] = [flow_details].[flow_pattern_id]
		inner join [APCSProDB].[method].[jobs] with (nolock) on [flow_details].[job_id] = [jobs].[id]
		where [flow_patterns].[id] = @flow_pattern_id

		select null as [step_no]
			, @job_name as [job_name];
	end
END
