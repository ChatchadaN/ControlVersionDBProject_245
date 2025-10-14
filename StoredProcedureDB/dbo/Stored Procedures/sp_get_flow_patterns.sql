-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_flow_patterns]
	-- Add the parameters for the stored procedure here
	@keyword varchar(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT fdt.flow_pattern_id, fdt.job_id, jobs.name, pros.name
	FROM APCSProDB.method.flow_details AS fdt
	INNER JOIN APCSProDB.method.jobs ON fdt.job_id = jobs.id
	INNER JOIN APCSProDB.method.processes AS pros on jobs.process_id = pros.id
	WHERE fdt.flow_pattern_id IN (
								  SELECT flow_pattern_id
								  FROM APCSProDB.method.flow_details AS fdt
								  INNER JOIN APCSProDB.method.flow_patterns AS fpt ON fdt.flow_pattern_id = fpt.id
								  WHERE fpt.comments like '%' + @keyword + '%'
								  GROUP BY flow_pattern_id
								  HAVING COUNT(flow_pattern_id) = 1)
END
