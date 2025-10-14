-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_jig_set]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT jig_sets.id
	, jig_sets.[name]
	, jig_sets.code
	, jig_sets.process_id  
	, processes.[name] AS Process
	, jig_sets.comment
	, jig_sets.created_at
	, jig_sets.created_by
	, jig_sets.updated_at
	, jig_sets.updated_by  
	, jig_sets.is_disable
	FROM [APCSProDB].[method].jig_sets  
	LEFT JOIN [APCSProDB].method.processes 
	ON processes.id = jig_sets.process_id
	WHERE  jig_sets.process_id IS NOT NULL
	ORDER BY  jig_sets.[name]  , jig_sets.process_id  


END
