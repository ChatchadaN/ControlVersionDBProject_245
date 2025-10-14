-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE cac.sp_set_setting_leadtime_sum
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DELETE FROM [APCSProDWH].[cac].[setting_leadtime_temp]
	INSERT INTO [APCSProDWH].[cac].[setting_leadtime_temp]
	([device_slip_id]
	, [step_no]
	, [lead_time_sum])
	SELECT [temp_data].[device_slip_id]
		, [temp_data].[step_no]
		, MAX([temp_data].[lead_time_sum]) as [lead_time_sum]
	FROM (SELECT [device_flows].[device_slip_id]
	, [device_flows].[step_no]
	, SUM([device_flows].[lead_time]) OVER (PARTITION BY [device_flows].[device_slip_id] ORDER BY [device_flows].[step_no]
			ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) as [lead_time_sum]
	FROM [APCSProDB].[method].[device_flows]
	inner join [APCSProDB].[method].[device_slips] on [device_slips].[device_slip_id] = [device_flows].[device_slip_id]
	inner join [APCSProDB].[method].[device_versions] on [device_versions].[device_id] = [device_slips].[device_id]
	inner join [APCSProDB].[method].[device_names] on [device_names].[id] = [device_versions].[device_name_id]
	inner join [APCSProDB].[method].[packages] on [packages].[id] = [device_names].[package_id]) as [temp_data]
	GROUP BY [temp_data].[device_slip_id], [temp_data].[step_no]

	UPDATE [APCSProDB].[method].[device_flows]
	SET [device_flows].[lead_time_sum] = [setting_leadtime_temp].[lead_time_sum]
	FROM [APCSProDB].[method].[device_flows]
	INNER JOIN [APCSProDWH].[cac].[setting_leadtime_temp] ON [setting_leadtime_temp].[device_slip_id] = [device_flows].[device_slip_id]
		and [setting_leadtime_temp].[step_no] = [device_flows].[step_no]
END
