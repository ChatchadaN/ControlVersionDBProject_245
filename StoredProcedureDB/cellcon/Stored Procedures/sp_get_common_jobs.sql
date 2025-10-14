-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_get_common_jobs]
	-- Add the parameters for the stored procedure here
	@fromJobId int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT a.job_id AS fromJobId
		 , b.name AS fromJobName
		 , a.to_job_id AS toJobId
		 , c.name AS toJobName 
		 , a.bom_job_id AS bomJobId
		 , CASE WHEN d.name like 'AUTO(%' THEN REPLACE(REPLACE(d.name, '(', ''), ')', '') ELSE d.name END AS bomJobName
	FROM APCSProDB.trans.job_commons AS a 
	INNER JOIN APCSProDB.method.jobs AS b ON a.job_id = b.id 
	INNER JOIN APCSProDB.method.jobs AS c ON a.to_job_id = c.id
	INNER JOIN APCSProDB.method.jobs AS d ON a.bom_job_id = d.id
	WHERE a.job_id = @fromJobId
END
