-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_data_lot]
	-- Add the parameters for the stored procedure here
	 @lot_no		NVARCHAR(20)		
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;	

    -- Insert statements for procedure here
	SELECT ISNULL(TRIM([lots].[lot_no]),'') AS [LotNo]
		, ISNULL(TRIM(lots.carrier_no),'')  AS [Carrier]
		, ISNULL(TRIM([packages].[name]),'') AS [Package]
		, ISNULL(TRIM([device_names].[name]),'') AS [Device]
		, ISNULL(TRIM([device_names].[tp_rank]),'')  AS [TPRank]
		, ISNULL([locations].[name],'') AS [RackLocation]
		, CASE WHEN [lots].[is_special_flow] =  1 THEN lot_special_flows.step_no ELSE lots.step_no END AS [StepNo]
		, CASE WHEN [lots].[is_special_flow] =  1 THEN ISNULL(TRIM(jobspecial.name),'') ELSE ISNULL(TRIM(jobmaster.name),'') END AS [JobName]
		, CASE WHEN [lots].[is_special_flow] =  1 THEN [jobspecial].[process_id] ELSE [jobmaster].[process_id] END AS [ProcessID]
		, [days].[date_value] as [ShipmentDate]
		, IIF(CASE WHEN [lots].[is_special_flow] =  1 THEN [special_flows].[quality_state] ELSE [lots].[quality_state] END = 0,0,1)  AS [quality_state]
		, ISNULL(lots.e_slip_id,'')    AS e_slip_id
		, ''   AS department
		, DATEDIFF(DAY , [days].date_value, GETDATE())   AS delay_day
		, ISNULL(memos.val,'') AS QC_MEMO
		,  CASE WHEN 
				CASE WHEN [lots].[is_special_flow] =  1 THEN [special_flows].[quality_state] ELSE [lots].[quality_state] END = 0 
						THEN  CASE WHEN DATEDIFF(DAY ,[days].date_value, GETDATE()) <= 0 THEN 'NORMALL'
						ELSE 'DELAY' END 
			ELSE 'ABDELAY' END AS  presentation
	FROM [APCSProDB].[trans].[lots]  
	INNER JOIN [APCSProDB].[method].[device_names] ON [lots].[act_device_name_id] = [device_names].[id]
	INNER JOIN [APCSProDB].[method].[packages] ON [device_names].[package_id] = [packages].[id]
	LEFT JOIN APCSProDB.trans.special_flows ON [lots].[is_special_flow] = 1 
	AND [lots].[special_flow_id] = [special_flows].[id]
	LEFT JOIN APCSProDB.trans.lot_special_flows ON [special_flows].[id] = [lot_special_flows].[special_flow_id] 
	AND [special_flows].[step_no] = [lot_special_flows].[step_no]
	INNER JOIN APCSProDB.method.jobs AS [jobmaster] ON [lots].[act_job_id] = [jobmaster].[id]
	LEFT JOIN APCSProDB.method.jobs AS [jobspecial] ON [lot_special_flows].[job_id] = [jobspecial].[id]
	LEFT JOIN [APCSProDB].[trans].[locations] ON [lots].[location_id] = [locations].[id]
	LEFT JOIN [APCSProDB].[trans].[days] on [lots].[modify_out_plan_date_id] = [days].[id] 
	LEFT JOIN APCSProDB.trans.memos  on [lots].qc_memo_id = memos.[id] 
	WHERE ( [lots].lot_no = @lot_no OR e_slip_id = @lot_no)
	ORDER BY [lots].[lot_no]
END
