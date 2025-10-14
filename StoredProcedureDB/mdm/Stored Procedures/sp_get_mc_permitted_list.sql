-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_mc_permitted_list]
	-- Add the parameters for the stored procedure here
	@id int = 0	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT [permitted_machine_id]
      ,[machine_id]
	  ,machines.name as machine_name
	  ,CASE WHEN [qc_state] = 0 THEN NULL ELSE [qc_state] END AS [qc_state]
      ,[qc_comment]
      ,[permitted_machine_machines].[updated_at]
      ,[permitted_machine_machines].[updated_by]
	FROM [APCSProDB].[mc].[permitted_machine_machines]
	inner join APCSProDB.mc.machines on permitted_machine_machines.machine_id = machines.id
	WHERE permitted_machine_id = @id
END
