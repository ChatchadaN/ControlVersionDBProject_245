-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_get_setting_input_plan]
	-- Add the parameters for the stored procedure here
	@package_name varchar(50) = '%'
	, @plan_start_date varchar(10) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT [package]
      , [plan_start_date]
      , [input_plan_per_day_lot]
      , [input_plan_per_month_lot]
      , [input_plan_per_day_pcs]
      , [input_plan_per_month_pcs]
	from [APCSProDWH].[cac].[setting_input_plan]
	where [package] like @package_name
	and [plan_start_date] like @plan_start_date
END
