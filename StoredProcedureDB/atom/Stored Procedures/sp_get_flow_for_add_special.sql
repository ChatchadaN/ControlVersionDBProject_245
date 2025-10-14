-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_flow_for_add_special]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT [flow_patterns].[id]
		, CASE
			WHEN [jobs].[name] = '100% INSP.' THEN 
				CASE 
					WHEN [processes].[name] = 'FL Inspect' THEN 'FL ' + [jobs].[name]
					WHEN [processes].[name] = 'FT Inspect' THEN 'FT ' + [jobs].[name]
					ELSE [jobs].[name]
				END
			ELSE [jobs].[name]
		END AS [job_name]
	FROM [APCSProDB].[method].[flow_patterns] 
	INNER JOIN [APCSProDB].[method].[flow_details] ON [flow_patterns].[id] = [flow_details].[flow_pattern_id]
	INNER JOIN [APCSProDB].[method].[jobs] ON [flow_details].[job_id] = [jobs].[id]
	INNER JOIN [APCSProDB].[method].[processes] ON [jobs].[process_id] = [processes].[id]
	CROSS APPLY (
		SELECT COUNT([flow_details].[flow_pattern_id]) AS [cc]
		FROM [APCSProDB].[method].[flow_details] 
		WHERE [flow_details].[flow_pattern_id] = [flow_patterns].[id]
			AND [flow_patterns].[assy_ft_class] = 'S'
			AND [flow_patterns].[is_released] = 1
		GROUP BY [flow_details].[flow_pattern_id]
		HAVING COUNT([flow_details].[flow_pattern_id]) = 1
	) AS [count_flow]
	WHERE [flow_patterns].[assy_ft_class] = 'S'
		AND [flow_patterns].[is_released] = 1
	ORDER BY [jobs].[name];
END