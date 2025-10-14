-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cac].[sp_get_main_all_temp]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	/****** Script for SelectTopNRows command from SSMS  ******/
--SELECT LEFT([setting_job_groups].[description], CHARINDEX(' ',[setting_job_groups].[description]) -1) as LockProcess
--	, RIGHT([setting_job_groups].[description], LEN([setting_job_groups].[description]) - CHARINDEX(' ',[setting_job_groups].[description])) as WIP
--	, CONVERT(varchar(10), [setting_package_input_limit].[wip_lot_count]) + '/' + CONVERT(varchar(10), [setting_package_input_limit].[target_value]) as ACTSETTING
--	, [setting_package_input_limit].[wip_lot_count]
--	, [setting_package_input_limit].[target_value]
--  FROM [APCSProDWH].[dwh].[setting_package_input_limit]
--  inner join [APCSProDWH].[dwh].[setting_job_groups] on [setting_job_groups].[id] = [setting_package_input_limit].[target_id]
--  where [setting_package_input_limit].[package_id] = 242
--  order by [setting_job_groups].[id]
END
