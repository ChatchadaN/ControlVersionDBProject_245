-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_ois_set]
	-- Add the parameters for the stored procedure here
	@id int = 0	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	SET @id = CASE WHEN @id = 0 THEN NULL ELSE @id END

    -- Insert statements for procedure here
	BEGIN
	SELECT [ois_sets].[id]
      ,[ois_sets].[name]
      ,[ois_sets].[comment]
      ,[ois_sets].process_id
	  ,processes.name AS processes
      ,[ois_sets].[created_at]
      ,[ois_sets].[created_by]
      ,[ois_sets].[updated_at]
      ,[ois_sets].[updated_by]
	FROM APCSProDB.[method].[ois_sets]
	INNER JOIN APCSProDB.method.processes ON processes.id = [ois_sets].process_id
	WHERE [ois_sets].[id] =  @id  OR  @id  IS NULL
	END

	------------------------Comment Show--------------------------------
	--------------------------------------------------------------------
END
