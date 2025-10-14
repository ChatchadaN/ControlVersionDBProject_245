-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_job_flow_by_LotNo]
	-- Add the parameters for the stored procedure here
	@lot_no Varchar(50),
	@staus int = 0, --0:basic 1:หา job by lot 2:หา flow by lot
	@job_id int = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	IF (@staus = 0)
	BEGIN
		select 	lot_no
			,[device_flows].device_slip_id
			,[jobs].id as [id]
			,[jobs].name as [filter_name]
			,[device_flows].step_no
			,[device_flows].next_step_no
		from [APCSProDB].[method].[device_names]
		inner join [APCSProDB].[method].[device_versions] on [device_versions].device_name_id = [device_names].id 
		and version_num = (select MAX(version_num) from [APCSProDB].[method].[device_versions] where device_name_id = [device_names].id )
		inner join [APCSProDB].[method].[device_slips] on [device_slips].device_id = [device_versions].device_id 
		and is_released = 1
		--and [device_slips].version_num = (select MAX(version_num) FROM [APCSProDB].[method].[device_slips] where device_id = [device_versions].device_id and is_released = 1)
		inner join [APCSProDB].[method].[device_flows] on [device_flows].device_slip_id = [device_slips].device_slip_id
		inner join [APCSProDB].[method].jobs on jobs.id = [device_flows].job_id
		inner join  [APCSProDB].trans.lots on lots.device_slip_id = [device_slips].device_slip_id
		where lots.lot_no = @lot_no
		and [device_flows].[is_skipped] != 1
		order by [device_flows].step_no
	END
	ELSE IF (@staus = 1)
	BEGIN
		--- หา job by lot
		IF (@job_id IS NOT NULL)
		BEGIN
			SELECT [lots].[lot_no] , 
				   [device_flows].[device_slip_id] , 
				   [jobs].[id] AS [id] ,
				   [jobs].[name] AS [job_name] ,
				   [device_flows].[step_no] , 
				   [device_flows].[next_step_no]
			FROM [APCSProDB].[trans].[lots] WITH (NOLOCK) 
			INNER JOIN [APCSProDB].[method].[device_slips] WITH (NOLOCK) ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
			INNER JOIN [APCSProDB].[method].[device_versions] WITH (NOLOCK) ON [device_versions].[device_id] = [device_slips].[device_id]
			INNER JOIN [APCSProDB].[method].[device_names] WITH (NOLOCK) ON [device_names].[id] = [device_versions].[device_name_id]
			INNER JOIN [APCSProDB].[method].[device_flows] WITH (NOLOCK) ON [device_flows].[device_slip_id] = [lots].[device_slip_id] 
			INNER JOIN [APCSProDB].[method].[jobs] WITH (NOLOCK) ON [jobs].[id] = [device_flows].[job_id]
			WHERE [lots].[id] = (SELECT [id] FROM [APCSProDB].[trans].[lots] WHERE [lot_no] = @lot_no)
			  AND [device_flows].[is_skipped] != 1
			  AND [jobs].[id] = @job_id;
		END
	END
	ELSE IF (@staus = 2)
	BEGIN
		--- หา flow by lot
		SELECT [lots].[lot_no] , 
				[device_flows].[device_slip_id] , 
				[jobs].[id] AS [id] ,
				[jobs].[name] AS [job_name] ,
				[device_flows].[step_no] , 
				[device_flows].[next_step_no]
		FROM [APCSProDB].[trans].[lots] WITH (NOLOCK) 
		INNER JOIN [APCSProDB].[method].[device_slips] WITH (NOLOCK) ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
		INNER JOIN [APCSProDB].[method].[device_versions] WITH (NOLOCK) ON [device_versions].[device_id] = [device_slips].[device_id]
		INNER JOIN [APCSProDB].[method].[device_names] WITH (NOLOCK) ON [device_names].[id] = [device_versions].[device_name_id]
		INNER JOIN [APCSProDB].[method].[device_flows] WITH (NOLOCK) ON [device_flows].[device_slip_id] = [lots].[device_slip_id] 
		INNER JOIN [APCSProDB].[method].[jobs] WITH (NOLOCK) ON [jobs].[id] = [device_flows].[job_id]
		WHERE [lots].[id] = (SELECT [id] FROM [APCSProDB].[trans].[lots] WHERE [lot_no] = @lot_no)
			AND [device_flows].[is_skipped] != 1;
	END
END
