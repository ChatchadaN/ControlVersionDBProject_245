-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_set_setting_input_plan]
	-- Add the parameters for the stored procedure here
	@status_id int = 1
	, @package_name varchar(50)
	, @plan_start_date varchar(10)
	, @input_plan_per_day_lot int = NULL
	, @input_plan_per_month_lot int = NULL
	, @input_plan_per_day_pcs int = NULL
	, @input_plan_per_month_pcs int = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF(@status_id = 1)
	BEGIN
		IF EXISTS(select * from [APCSProDWH].[cac].[setting_input_plan] where [package] like @package_name and [plan_start_date] like @plan_start_date)
		BEGIN
			UPDATE [APCSProDWH].[cac].[setting_input_plan]
			SET [input_plan_per_day_lot] = @input_plan_per_day_lot
			  ,[input_plan_per_month_lot] = @input_plan_per_month_lot
			  ,[input_plan_per_day_pcs] = @input_plan_per_day_pcs
			  ,[input_plan_per_month_pcs] = @input_plan_per_month_pcs
			WHERE [package] = @package_name
			and [plan_start_date] = @plan_start_date
		END
		ELSE
		BEGIN
			INSERT INTO [APCSProDWH].[cac].[setting_input_plan]
			([package]
           , [plan_start_date]
           , [input_plan_per_day_lot]
           , [input_plan_per_month_lot]
           , [input_plan_per_day_pcs]
           , [input_plan_per_month_pcs])
			VALUES
			(@package_name
			, @plan_start_date
			, @input_plan_per_day_lot
			, @input_plan_per_month_lot
			, @input_plan_per_day_pcs
			, @input_plan_per_month_pcs)
		END
	END
	ELSE
	BEGIN
		DELETE FROM [APCSProDWH].[cac].[setting_input_plan]
		WHERE [package] = @package_name
		and [plan_start_date] = @plan_start_date
	END
END
