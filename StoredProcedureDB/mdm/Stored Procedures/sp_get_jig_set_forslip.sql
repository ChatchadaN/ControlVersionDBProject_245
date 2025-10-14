-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_jig_set_forslip]
	-- Add the parameters for the stored procedure here
	 @process_id INT  
	,@package_name NVARCHAR(MAX) =  NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
 
	SELECT	  jig_sets.id 
			, jig_sets.name
			, jig_sets.process_id
			, jig_sets.code
			, jig_sets.comment
			, processes.name AS process
	FROM  APCSProDB.method.jig_sets  
	LEFT JOIN  APCSProDB.method.processes 
	ON jig_sets.process_id		= processes.id 
	WHERE jig_sets.name			= @package_name
	AND (jig_sets.process_id	=  @process_id OR @process_id  IS NULL)
	AND  ISNULL(is_disable, 0)  = 0 

	 
END
