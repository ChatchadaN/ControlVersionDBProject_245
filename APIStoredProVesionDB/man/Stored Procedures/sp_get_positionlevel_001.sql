-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
Create PROCEDURE [man].[sp_get_positionlevel_001]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT p.[id] as position_id
      ,p.[name] as position_name
      ,p.[short_name] as position_short_name
      ,p.[positions_code]
      ,p.[employee_level_id]
	  ,el.id as employee_id
	  ,el.name as level_name
	  ,el.short_name as employee_short_name
	  ,el.level_code
  FROM [DWH].[man].[positions] p 
  INNER JOIN [DWH].[man].[employee_levels] el ON el.id = p.employee_level_id
END
