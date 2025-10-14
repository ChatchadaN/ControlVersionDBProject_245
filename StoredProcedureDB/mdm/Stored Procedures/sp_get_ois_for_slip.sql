-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_ois_for_slip]
	-- Add the parameters for the stored procedure here
	@Device VARCHAR(50)
	, @process_id INT 
	, @job_id INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure her

	/****** Script for SelectTopNRows command from SSMS  ******/	
	BEGIN
		DECLARE @commonjob_id int

		SELECT @commonjob_id = to_job_id
		FROM APCSProDB.trans.job_commons
		WHERE job_id = @job_id

		SELECT DISTINCT ois_sets.id,ois_sets.name,ois_sets.comment,ois_sets.process_id,processes.name as processes,job_id,jobs.name AS jobs
		FROM APCSProDB.method.ois_sets 
			INNER JOIN APCSProDB.method.ois_set_lists ON ois_set_lists.ois_set_id = ois_sets.id
			INNER JOIN APCSProDB.method.ois_recipes ON ois_set_lists.ois_recipe_id = ois_recipes.id
			INNER JOIN APCSProDB.method.processes ON ois_sets.process_id = processes.id
			INNER JOIN APCSProDB.method.jobs ON ois_recipes.job_id = jobs.id
		--WHERE ois_sets.name like '%' + @Device + '%' and ois_sets.process_id = @process_id and ois_recipes.job_id = @job_id
		WHERE ois_sets.name = @Device 
			AND ois_sets.process_id = @process_id 
			AND ois_recipes.job_id = @commonjob_id
	END
END
