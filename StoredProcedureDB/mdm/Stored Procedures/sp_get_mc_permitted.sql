-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_mc_permitted]
	-- Add the parameters for the stored procedure here
	@id int = 0	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN
	SET @id = CASE WHEN @id = 0 THEN NULL ELSE @id END
		SELECT [permitted_machines].[id]
	      ,[permitted_machines].[name]
		  ,CASE WHEN [symbol_machine_id] = 0 THEN NULL ELSE [symbol_machine_id] END AS [symbol_machine_id]
	      ,[permitted_machines].[created_at]
	      ,user1.emp_num AS[created_by]
		FROM [APCSProDB].[mc].[permitted_machines]
		LEFT JOIN[APCSProDB].man.users AS user1 ON [permitted_machines].created_by = user1.id 
		WHERE [permitted_machines].[id] =  @id  OR  @id  IS NULL
  END
END
