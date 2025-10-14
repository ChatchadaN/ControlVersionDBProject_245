-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_material_set_forslip]
	-- Add the parameters for the stored procedure here
	 @process_id INT	 =  NULL
	,@package_name NVARCHAR(MAX) =  NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
 
	SELECT	  material_sets.id 
			, material_sets.name
			, material_sets.process_id
			, material_sets.comment
			, processes.name AS process
	FROM APCSProDB.method.material_sets  
	LEFT JOIN APCSProDB.method.processes 
	ON material_sets.process_id = processes.id
	WHERE ISNULL(is_checking, 0) = 1  
	AND material_sets.name = @package_name
	AND (material_sets.process_id  = @process_id OR @process_id IS NULL)

	 
END
