-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_insp_path_ng]
	-- Add the parameters for the stored procedure here
	@JobName VARCHAR(50)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT 
		CASE (select process.name from APCSProDB.method.jobs	as jobs
		inner join APCSProDB.method.processes as process on process.id = jobs.process_id
		where jobs.name = @JobName)
			WHEN 'DB' THEN 'DB'
			WHEN 'WB' THEN 'WB'
			WHEN 'FL Inspect' THEN 'FL'
			WHEN 'FT Inspect' THEN 'FT'
			WHEN 'INSP. after TP' THEN 'TP'
			WHEN 'Bari INSP.' THEN 'DB'
			WHEN 'DBcure' THEN 'DB'
			WHEN 'X-Ray After' THEN 'XRAY'
			WHEN 'Auto X-Rayr' THEN 'XRAY'
			ELSE NULL
		END AS RESULT
END
