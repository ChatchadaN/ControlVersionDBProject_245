-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_set_wip_monitor_process_table]
	-- Add the parameters for the stored procedure here
	@status_id int
	, @package varchar(50)
	, @process varchar(50)
	, @problem_point varchar(200) = NULL
	, @action_item varchar(200) = NULL
	, @target int = NULL
	, @incharge varchar(50) = NULL
	, @occure_date date = NULL
	, @plan_date date = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF(@status_id = 1)
	BEGIN
		IF EXISTS(select * from [APCSProDWH].[cac].[wip_monitor_process_table_detail] where [package] = @package and [process] = @process)
		BEGIN
			UPDATE [APCSProDWH].[cac].[wip_monitor_process_table_detail]
			SET [problem_point] = @problem_point
				, [action_item] = @action_item
				, [target] = @target
				, [incharge] = @incharge
				, [occure_date] = @occure_date
				, [plan_date] = @plan_date
			WHERE [package] = @package
			and [process] = @process
		END
		ELSE
		BEGIN
			INSERT INTO [APCSProDWH].[cac].[wip_monitor_process_table_detail]
			([package]
			, [process]
			, [problem_point]
			, [action_item]
			, [target]
			, [incharge]
			, [occure_date]
			, [plan_date])
			VALUES
			(@package
			, @process
			, @problem_point
			, @action_item
			, @target
			, @incharge
			, @occure_date
			, @plan_date)
		END
	END
	ELSE
	BEGIN
		DELETE FROM [APCSProDWH].[cac].[wip_monitor_process_table_detail]
		WHERE [package] = @package
		and [process] = @process
	END
END
