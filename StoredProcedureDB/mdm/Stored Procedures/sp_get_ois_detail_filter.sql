-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_ois_detail_filter]
	-- Add the parameters for the stored procedure here
	@filter	INT = 1
	, @package_id		varchar(50) = ''
	, @equipType		varchar(50) = ''

--1: Package 2: Device 3: Process 4:TestFlow common 5:production_category 6: Version  7: Equipment Type 8: Equipment name
----------------------------------------------------------------------------------------------------------------

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN

		SET @package_id = CASE WHEN @package_id = '' THEN NULL ELSE @package_id END
		SET @equipType = CASE WHEN @equipType = '' THEN NULL ELSE @equipType END

	----------------------------------------------------------------------------------------------------------------
		/****** Script for SelectTopNRows command from SSMS  ******/

		IF (@filter = 1)
		BEGIN
			PRINT 'Package'

			SELECT 
				CAST(id AS VARCHAR) AS [filter_id]
				, packages.name  AS [filter_name]
			FROM APCSProDB.method.packages

		END

		ELSE IF (@filter = 2)
		BEGIN
			PRINT 'Device'

			SELECT 
				CAST(MAX(device_names.id) AS VARCHAR) AS [filter_id]
				, device_names.ft_name AS [filter_name]
			FROM APCSProDB.[method].[device_slips]
			INNER JOIN APCSProDB.method.device_versions on[device_slips].device_id = device_versions.device_id
			INNER JOIN APCSProDB.method.device_names on device_versions.device_name_id = device_names.id 
			INNER JOIN APCSProDB.method.device_flows on[device_slips].[device_slip_id] = device_flows.device_slip_id 
			INNER JOIN APCSProDB.method.jobs on device_flows.job_id = jobs.id
			INNER JOIN APCSProDB.method.processes on device_flows.act_process_id = processes.id
			INNER join [APCSProDB].[method].[packages] ON [packages].[id] = [device_names].[package_id]
			WHERE 
				([packages].[id] = @package_id OR @package_id IS NULL)
				AND [device_slips].is_released = 1
				AND device_names.ft_name IS NOT NULL
			GROUP BY device_names.ft_name
			ORDER BY device_names.ft_name

		END

		ELSE IF (@filter = 3)
		BEGIN
			PRINT 'Process'

			SELECT
				CAST(processes.id AS VARCHAR) AS [filter_id]
				,processes.name AS [filter_name]
			FROM APCSProDB.method.processes
			WHERE id IN (8,9,10,12)
			ORDER BY processes.name
		END

		ELSE IF (@filter = 4)
		BEGIN
			PRINT 'TestFlow'

			SELECT 
				CAST(j2.id AS VARCHAR) AS [filter_id]
				,j2.name AS [filter_name]
			FROM APCSProDB.trans.job_commons
			INNER JOIN APCSProDB.method.jobs j1 on job_commons.job_id = j1.id
			INNER JOIN APCSProDB.method.jobs j2 on job_commons.to_job_id = j2.id
			group by j2.id ,j2.name
		END

		ELSE IF (@filter = 5)
		BEGIN
			PRINT 'production_category'

			SELECT val AS [filter_id]
			,label_eng AS [filter_name]	
			FROM APCSProDB.trans.item_labels
			WHERE item_labels.name = 'lots.production_category'
			AND val IN (0,30,31)
		END

		ELSE IF (@filter = 6)
		BEGIN
			PRINT 'Version'

			SELECT 
			'' AS [filter_id]
			,version_num  AS [filter_name]
			FROM APCSProDB.method.ois_recipe_versions
			GROUP BY version_num
		END

		ELSE IF (@filter = 7)
		BEGIN
			PRINT 'Equipment Type'

			SELECT 
			'' AS [filter_id]
			,[categories].[short_name] AS [filter_name]
			FROM [APCSProDB].[jig].[categories]
			WHERE [short_name] != ''
			Group by short_name

		END

		ELSE IF (@filter = 8)
		BEGIN
			PRINT 'Equipment name'

			SELECT 
				CAST( productions.id AS VARCHAR) AS [filter_id]
				, IIF(productions.spec IS NULL,productions.[name],productions.spec) as [filter_name]
			FROM APCSProDB.jig.productions
			INNER JOIN APCSProDB.jig.categories ON productions.category_id = categories.id 
			WHERE (categories.short_name = @equipType OR @equipType IS NULL)
			ORDER BY category_id
		END

	END
END