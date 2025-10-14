-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  PROCEDURE [mdm].[sp_get_jig_set_list]
	   @process_id    int   = 0
	 , @category_id   int   = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
		
		SELECT  id,CONCAT(name,'  ( ',short_name,' )') AS name 
		FROM APCSProDB.jig.categories
		WHERE lsi_process_id =  @process_id


		SELECT  id,name AS name  
		FROM APCSProDB.jig.productions 
		WHERE  productions.category_id = @category_id 
		AND productions.is_disabled = 0
		ORDER BY name



END
