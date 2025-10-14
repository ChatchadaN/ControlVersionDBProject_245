-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_rcs_records_excel_ver002] -- Ver002
	-- Add the parameters for the stored procedure here
	@start_date	varchar(16)
	,@end_date	varchar(16)
	,@rackName	varchar(5)
	,@pkg		varchar(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from1
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT
		[LotNo]
		,[Package]
		,[Device]
		,[Rack]
		,[Address]
		,[InBy]
		,[Dept]
		,[Sect]
		,FORMAT([TimeIn], 'yyyy/MM/dd  HH:mm:ss') AS [TimeIn]
		,FORMAT([TimeOut], 'yyyy/MM/dd  HH:mm:ss') AS [TimeOut]
		,ISNULL(DATEDIFF(MINUTE,[TimeIn],[TimeOut]),DATEDIFF(MINUTE,[TimeIn],GETDATE())) AS [ProcessingTime]

	FROM
	(
			SELECT 
					[lot_no]				AS [LotNo]
					,[pkg].[name]			AS [Package]
					,[dev].[name]			AS [Device]
					,[loca].[name]			AS [Rack]
					,[loca].[address]		AS [Address]
					,[op1].[emp_num]		AS [InBy]
					,[departments].[name]	AS [Dept]
					,[sections].[name]		AS [Sect]

					,MAX (CASE [record_class]	WHEN 1	THEN [rec].[recorded_at] ELSE NULL END)	AS [TimeIn]
					,MAX (CASE [record_class]	WHEN 3	THEN [rec].[recorded_at] ELSE NULL END)	AS [TimeOut]

			FROM
					(
							SELECT		[rec].[lot_id], [rec].[location_id]
										,[rec].[recorded_by]
										,MIN([rec].[recorded_at]) AS [recorded_time]
							FROM		[DBx].[dbo].[rcs_process_records] AS [rec]
							WHERE		[rec].[recorded_at] BETWEEN @start_date AND @end_date AND [rec].[record_class] = 1
							GROUP BY	[rec].[lot_id], [rec].[location_id], [rec].[recorded_by]
					) AS [start_recorod]

			LEFT JOIN	[DBx].[dbo].[rcs_process_records]		AS [rec]	ON [start_recorod].[lot_id] = [rec].[lot_id] AND [start_recorod].[location_id] = [rec].[location_id]
			INNER JOIN	[APCSProDB].[trans].[lots]				AS [lot]	ON [rec].[lot_id] = [lot].[id]
			INNER JOIN	[APCSProDB].[trans].[locations]			AS [loca]	ON [rec].[location_id] = [loca].[id]
			INNER JOIN	[APCSProDB].[method].[packages]			AS [pkg]	ON [lot].[act_package_id] = [pkg].[id]
			INNER JOIN	[APCSProDB].[method].[device_names]		AS [dev]	ON [lot].[act_device_name_id] = [dev].[id]
			LEFT JOIN	[APCSProDB].[man].[users]				AS [op1]	ON [start_recorod].[recorded_by] = [op1].[id]
			LEFT JOIN	[APCSProDB].[man].[user_organizations]				ON [op1].[id] = [user_organizations].[user_id]
			LEFT JOIN	[APCSProDB].[man].[organizations]					ON [user_organizations].[organization_id] = [organizations].[id]
			LEFT JOIN	[APCSProDB].[man].[headquarters]					ON [organizations].[headquarter_id] = [headquarters].[id]
			LEFT JOIN	[APCSProDB].[man].[factories]						ON [headquarters].[factory_id] = [factories].[id]
			LEFT JOIN	[APCSProDB].[man].[sections]						ON [organizations].[section_id] = [sections].[id]
			LEFT JOIN	[APCSProDB].[man].[departments]						ON ([sections].[department_id] = [departments].[id] OR [organizations].[department_id] = [departments].[id])
			LEFT JOIN	[APCSProDB].[man].[divisions]						ON ([departments].[division_id] = [divisions].[id] OR [organizations].[division_id] = [divisions].[id])

			WHERE [loca].[name] LIKE '%' + @rackName + '%' AND [pkg].[name] LIKE '%' + @pkg + '%'
			GROUP BY [lot_no], [pkg].[name], [dev].[name], [loca].[name], [loca].[address], [op1].[emp_num], [departments].[name], [sections].[name]
	) AS [merge_time]
	
	ORDER BY [LotNo],[TimeIn]
END
