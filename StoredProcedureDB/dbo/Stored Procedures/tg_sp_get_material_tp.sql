-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_material_tp]
	-- Add the parameters for the stored procedure here
	 @Assy_Name char(20)
	,@Process_Name Char(50)
	,@lotno varchar(10) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @checkmat_name char(50);
    -- Insert statements for procedure here

	IF @lotno = ''
	BEGIN
		BEGIN TRY
				SELECT [device_slip_id]
				,[device_id]
				,[Package]
				,[device]
				,[device_type]
				,[job_id]
				,[job_deviceflow]
				,[material_set_id]
				,[materialSet]
				,[process_id]
				--,[material_group_id]
				 --,[mat_name]
				--,[Reel]
				--,[CoverTape]
				--,[EmbossTape] 
				,case when [Reel]  = '' or [Reel] is null  then '' else [Reel] end as Reel
				,case when [Cover Tape] = '' or [Cover Tape] is null  then '' else [Cover Tape] end as CoverTape
				,case when [Emboss Tape] = '' or [Emboss Tape] is null then '' else [Emboss Tape]  end as EmbossTape
				,case when @checkmat_name = 'NULL' then 'FALSE' else 'TURE' end as STATUS
			FROM (	SELECT ds.device_slip_id 
						,ds.device_id
						,pk.name as Package
						,dn.name as device
						,d_vs.device_type
						,job_id
						,job.name as job_deviceflow
						,dv_f.material_set_id
						,mat_set.name as materialSet
						,mat_set.process_id
						--,mat_set_list.material_group_id
						,CAST(pd.name as nvarchar(50)) as mat_name
						,pd.details 
					FROM  APCSProDB.method.device_names as dn
 					LEFT JOIN APCSProDB.method.packages as pk ON dn.package_id = pk.id 
 					LEFT JOIN APCSProDB.method.device_versions as d_vs ON dn.id = d_vs.device_name_id 
 					LEFT JOIN APCSProDB.method.device_slips as ds ON d_vs.device_id = ds.device_id 
 						AND d_vs.version_num = ds.version_num 
 						AND ds.is_released = 1 
 						AND d_vs.device_type = 6
 					LEFT JOIN APCSProDB.method.device_flows as dv_f ON ds.device_slip_id = dv_f.device_slip_id
 					LEFT JOIN APCSProDB.method.jobs as job ON job.id = dv_f.job_id
					LEFT JOIN APCSProDB.method.processes as pro ON pro.id = job.process_id
 					LEFT JOIN APCSProDB.method.material_sets as mat_set ON mat_set.id = dv_f.material_set_id 
 						--AND (mat_set.process_id = dv_f.job_id OR mat_set.process_id = pro.id)
 					LEFT JOIN APCSProDB.method.material_set_list as mat_set_list ON mat_set_list.id = mat_set.id
 					LEFT JOIN APCSProDB.material.productions as pd ON pd.id = mat_set_list.material_group_id
					WHERE (ds.is_released = 1) 
						AND dn.assy_name = @Assy_Name
						AND (job.name = @Process_Name or job.name = 'TP-TP')

			) As Table1
			PIVOT
			(
				max([mat_name])
				FOR details In([Reel], [Cover Tape], [Emboss Tape],[ALUMINUM])
			) As Pivot1
		END TRY
		BEGIN CATCH
				SELECT 'FALSE' AS Status ,'Gat Data Error !!' AS Error_Message_ENG,N'ไม่พบข้อมูล !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
				RETURN
		END CATCH
	END
	ELSE
	BEGIN
		--add condition search data by lotno --> update by aomsin (2023/08/25 time : 16.12)
		SELECT [lots].[lot_no]
			, [device_names].[assy_name]
			, [device_slips].[device_slip_id]
			, [device_slips].[device_id]
			, [packages].[name] AS [Package]
			, [device_names].[name] AS [device]
			, [device_versions].[device_type]
			, [material].[job_id]
			, [material].[job_deviceflow]
			, [material].[material_set_id]
			, [material].[materialSet]
			, [material].[process_id]
			, ISNULL([material].[Reel], '') as Reel
			, ISNULL([material].[Cover Tape], '') as CoverTape
			, ISNULL([material].[Emboss Tape], '') as EmbossTape
		FROM [APCSProDB].[trans].[lots]
		INNER JOIN [APCSProDB].[method].[device_slips] ON [device_slips].[device_slip_id] = [lots].[device_slip_id]
		INNER JOIN [APCSProDB].[method].[device_versions] ON [device_versions].[device_id] = [device_slips].[device_id]
		INNER JOIN [APCSProDB].[method].[device_names] ON [device_names].[id] = [device_versions].[device_name_id]
		INNER JOIN [APCSProDB].[method].[packages] ON [packages].[id] = [device_names].[package_id]
		INNER JOIN [APCSProDB].[method].[package_groups] ON [package_groups].[id] = [packages].[package_group_id]
		OUTER APPLY (
			---# find material_sets from device_flows
			SELECT [device_flows].[job_id]
				, [jobs].[name] AS [job_deviceflow]
				, [device_flows].[material_set_id]
				, [material_sets].[name] AS [materialSet]
				, [material_sets].[process_id]
				, [mt].[Reel]
				, [mt].[Cover Tape]
				, [mt].[Emboss Tape]
				, [mt].[ALUMINUM]
			FROM [APCSProDB].[method].[device_flows] 
			INNER JOIN [APCSProDB].[method].[jobs] ON [jobs].[id] = [device_flows].[job_id]
			INNER JOIN [APCSProDB].[method].[processes] ON [processes].[id] = [jobs].[process_id]
			LEFT JOIN [APCSProDB].[method].[material_sets] ON [material_sets].[id] = [device_flows].[material_set_id] 
			OUTER APPLY (
				---# pivot material
				SELECT [Reel]
					, [Cover Tape]
					, [Emboss Tape]
					, [ALUMINUM]
				FROM (
					SELECT CAST([productions].[name] AS NVARCHAR(50)) AS [mat_name]
						, [productions].[details] 
					FROM [APCSProDB].[method].[material_set_list]
					LEFT JOIN [APCSProDB].[material].[productions] ON [productions].[id] = [material_set_list].[material_group_id]
					WHERE [material_set_list].[id] = [material_sets].[id]
				) AS [data_pivot]
				PIVOT
				(
					MAX([mat_name])
					FOR [details] IN ([Reel], [Cover Tape], [Emboss Tape], [ALUMINUM])
				) AS [pivot1]
			) AS [mt]
			WHERE [device_flows].[device_slip_id] = [lots].[device_slip_id]
				AND ([jobs].[name] IN ('TP','TP-TP'))
		) AS [material]
		WHERE [lots].[lot_no] = @lotno
	END
END
