-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,Update Call Table Interface to Is Server 2023/02/02 time : 11.24 ,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [tg].[sp_get_check_data_ogi_by_cellcon]
	-- Add the parameters for the stored procedure here
	@lot_no VARCHAR(10) = '', 
	@function INT = 0, ----# 1:checkCountLabelTotal ,2:checkLastLabel ,3:checkDisableReel, 4:checkVersionLabel, 5:getDataInputOGI, 6:CheckLotMagic
	@no_reel INT = 0 ----# 4:checkVersionLabel only
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		( [record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no] )
	SELECT GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [tg].[sp_get_check_data_ogi_by_cellcon] @lot_no = ''' + ISNULL(CAST(@lot_no AS VARCHAR),'NULL') + ''''
			+ ' , @function = ' + ISNULL(CAST(@function AS VARCHAR),'NULL')
			+ ' , @no_reel = ' + ISNULL(CAST(@no_reel AS VARCHAR),'NULL')
		, ISNULL(CAST(@lot_no AS VARCHAR),'NULL');
	--=====================================================================================================================================================================================
	----# 1:checkCountLabelTotal
	IF (@function = 1)
	BEGIN
		IF EXISTS(SELECT [id] FROM [APCSProDB].[trans].[lots] WHERE [lot_no] = @lot_no AND [pc_instruction_code] = 13)
		BEGIN
			IF EXISTS(SELECT [type_of_label] FROM [APCSProDB].[trans].[label_issue_records] WHERE [lot_no] = @lot_no AND [type_of_label] = IIF(SUBSTRING(@lot_no,5,1) = 'D',20,2))  --support new pc request version edit date 2024/01/12 time : 13.02 by Aomsin
			--IF EXISTS(SELECT [type_of_label] FROM [APCSProDB].[trans].[label_issue_records] WHERE [lot_no] = @lot_no AND [type_of_label] = 2)
			BEGIN
				INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
					( [record_at]
					, [record_class]
					, [login_name]
					, [hostname]
					, [appname]
					, [command_text]
					, [lot_no] )
				SELECT GETDATE()
					, '4'
					, ORIGINAL_LOGIN()
					, HOST_NAME()
					, APP_NAME()
					, 'RETURN EXEC [tg].[sp_get_check_data_ogi_by_cellcon] [Status] = TRUE'
						+ ' , [Title] = checkCountLabelTotal'
						+ ' , [CountNo] = ' + ISNULL(CAST(COUNT([type_of_label]) AS VARCHAR),'NULL')
					, ISNULL(CAST(@lot_no AS VARCHAR),'NULL')
				FROM [APCSProDB].[trans].[label_issue_records] 
				WHERE [lot_no] = @lot_no 
					AND [type_of_label] = IIF(SUBSTRING(@lot_no,5,1) = 'D',20,2);  

				SELECT 'TRUE' AS [Status]
					, 'checkCountLabelTotal' AS [Title]
					, COUNT([type_of_label]) AS [CountNo] 
				FROM [APCSProDB].[trans].[label_issue_records] 
				WHERE [lot_no] = @lot_no 
					AND [type_of_label] = IIF(SUBSTRING(@lot_no,5,1) = 'D',20,2);  --support new pc request version edit date 2024/01/12 time : 13.02 by Aomsin
					--AND [type_of_label] = 2
			END
			ELSE
			BEGIN
				SELECT 'FALSE' AS [Status]
					, 'checkCountLabelTotal' AS [Title]
					, 0 AS [CountNo]; 
			END 
		END
		ELSE
		BEGIN
			DECLARE @TUBE VARCHAR(20) = '';

			SELECT @TUBE = IIF([material].[TUBE] IS NULL,'NO USE','USE')-- AS [TUBE]
			FROM [APCSProDB].[trans].[lots]
			OUTER APPLY (
				---# find material_sets from device_flows
				SELECT [device_flows].[job_id]
					, [jobs].[name] AS [job_deviceflow]
					, [device_flows].[material_set_id]
					, [material_sets].[name] AS [materialSet]
					, [material_sets].[process_id]
					, [mt].[TUBE]
				FROM [APCSProDB].[method].[device_flows] 
				INNER JOIN [APCSProDB].[method].[jobs] ON [jobs].[id] = [device_flows].[job_id]
				INNER JOIN [APCSProDB].[method].[processes] ON [processes].[id] = [jobs].[process_id]
				LEFT JOIN [APCSProDB].[method].[material_sets] ON [material_sets].[id] = [device_flows].[material_set_id] 
				OUTER APPLY (
					---# pivot material
					SELECT [TUBE]
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
						FOR [details] IN ([TUBE])
					) AS [pivot1]
				) AS [mt]
				WHERE [device_flows].[device_slip_id] = [lots].[device_slip_id]
					AND [processes].[id] = 18
			) AS [material]
			WHERE [lots].[lot_no] = @lot_no;

			IF (@TUBE = 'NO USE')
			BEGIN
				IF EXISTS(SELECT [type_of_label] FROM [APCSProDB].[trans].[label_issue_records] WHERE [lot_no] = @lot_no AND [type_of_label] IN (3,0))
				BEGIN
					INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
						( [record_at]
						, [record_class]
						, [login_name]
						, [hostname]
						, [appname]
						, [command_text]
						, [lot_no] )
					SELECT GETDATE()
						, '4'
						, ORIGINAL_LOGIN()
						, HOST_NAME()
						, APP_NAME()
						, 'RETURN EXEC [tg].[sp_get_check_data_ogi_by_cellcon] [Status] = TRUE'
							+ ' , [Title] = checkCountLabelTotal'
							+ ' , [CountNo] = ' + ISNULL(CAST(COUNT([type_of_label]) AS VARCHAR),'NULL')
						, ISNULL(CAST(@lot_no AS VARCHAR),'NULL')
					FROM [APCSProDB].[trans].[label_issue_records] 
					WHERE [lot_no] = @lot_no 
						AND [type_of_label] IN (3,0);   

					SELECT 'TRUE' AS [Status]
						, 'checkCountLabelTotal' AS [Title]
						, COUNT([type_of_label]) AS [CountNo] 
					FROM [APCSProDB].[trans].[label_issue_records] 
					WHERE [lot_no] = @lot_no 
						AND [type_of_label] IN (3,0);  
				END
				ELSE
				BEGIN
					SELECT 'FALSE' AS [Status]
						, 'checkCountLabelTotal' AS [Title]
						, 0 AS [CountNo]; 
				END 
			END
			ELSE
			BEGIN
				IF EXISTS(SELECT [id] FROM [APCSProDB].[trans].[lots] WHERE [lot_no] = @lot_no AND [pc_instruction_code] != 11)
				BEGIN
					IF EXISTS(SELECT [type_of_label] FROM [APCSProDB].[trans].[label_issue_records] WHERE [lot_no] = @lot_no AND [type_of_label] IN (3,0))
					BEGIN
						INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
							( [record_at]
							, [record_class]
							, [login_name]
							, [hostname]
							, [appname]
							, [command_text]
							, [lot_no] )
						SELECT GETDATE()
							, '4'
							, ORIGINAL_LOGIN()
							, HOST_NAME()
							, APP_NAME()
							, 'RETURN EXEC [tg].[sp_get_check_data_ogi_by_cellcon] [Status] = TRUE'
								+ ' , [Title] = checkCountLabelTotal'
								+ ' , [CountNo] = ' + ISNULL(CAST(COUNT([type_of_label]) AS VARCHAR),'NULL')
							, ISNULL(CAST(@lot_no AS VARCHAR),'NULL')
						FROM [APCSProDB].[trans].[label_issue_records] 
						WHERE [lot_no] = @lot_no 
							AND [type_of_label] IN (3,0);   

						SELECT 'TRUE' AS [Status]
							, 'checkCountLabelTotal' AS [Title]
							, COUNT([type_of_label]) AS [CountNo] 
						FROM [APCSProDB].[trans].[label_issue_records] 
						WHERE [lot_no] = @lot_no 
							AND [type_of_label] IN (3,0);  
					END
					ELSE
					BEGIN
						--print
						print 'tube FALSE 1'
						SELECT 'FALSE' AS [Status]
							, 'checkCountLabelTotal' AS [Title]
							, 0 AS [CountNo];
					END 
				END
				ELSE
				BEGIN
					print 'tube FALSE 2'
					--SELECT 'FALSE' AS [Status]
					--	, 'checkCountLabelTotal' AS [Title]
					--	, 0 AS [CountNo];

					SELECT 'TRUE' AS [Status]   --edit condition tube shipment (std.) 2024/01/12 by Aomsin
							, 'checkCountLabelTotal' AS [Title]
							, COUNT([type_of_label]) AS [CountNo] 
						FROM [APCSProDB].[trans].[label_issue_records] 
						WHERE [lot_no] = @lot_no 
							AND [type_of_label] IN (3,0);  
				END
			END
		END
	END
	--=====================================================================================================================================================================================
	----# 2:checkLastLabel 
	ELSE IF (@function = 2)
	BEGIN
		IF EXISTS(SELECT [id] FROM [APCSProDB].[trans].[lots] WHERE [lot_no] = @lot_no AND ([pc_instruction_code] != 13 OR [pc_instruction_code] IS NULL))
		BEGIN
			IF EXISTS(SELECT [id] FROM [APCSProDB].[trans].[lots] WHERE [lot_no] = @lot_no AND [pc_instruction_code] = 11)
			BEGIN
				IF EXISTS(SELECT [no_reel] FROM [APCSProDB].[trans].[label_issue_records] WHERE [lot_no] = @lot_no AND [type_of_label] IN (2,3))
				BEGIN
					INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
						( [record_at]
						, [record_class]
						, [login_name]
						, [hostname]
						, [appname]
						, [command_text]
						, [lot_no] )
					SELECT GETDATE()
						, '4'
						, ORIGINAL_LOGIN()
						, HOST_NAME()
						, APP_NAME()
						, 'RETURN EXEC [tg].[sp_get_check_data_ogi_by_cellcon] [Status] = TRUE'
							+ ' , [Title] = checkLastLabel'
							+ ' , [lastReel] = ' + ISNULL(CAST(MAX(CAST([no_reel] AS INT)) AS VARCHAR),'NULL')
							--+ ' , [lastReel] = ' + ISNULL(CAST(COUNT(CAST([no_reel] AS INT)) AS VARCHAR),'NULL')
							+ ' , [ReelCount] = ' + ISNULL(CAST(COUNT([no_reel]) AS VARCHAR),'NULL')
						, ISNULL(CAST(@lot_no AS VARCHAR),'NULL')
					FROM [APCSProDB].[trans].[label_issue_records] 
					WHERE [lot_no] = @lot_no 
						AND [type_of_label] IN (2,3);  

					SELECT 'TRUE' AS [Status]
						, 'checkLastLabel' AS [Title]
						, MAX(CAST([no_reel] AS INT)) AS [lastReel]
						--, COUNT(CAST([no_reel] AS INT)) AS [lastReel] 
						, COUNT([no_reel]) AS [ReelCount] 
					FROM [APCSProDB].[trans].[label_issue_records] 
					WHERE [lot_no] = @lot_no 
						AND [type_of_label] IN (2,3);
				END
				ELSE
				BEGIN
					SELECT 'FALSE' AS [Status]
						, 'checkLastLabel' AS [Title]
						, 0 AS [lastReel] 
						, 0 AS [ReelCount] ;
				END
			END
			ELSE
			BEGIN
				IF EXISTS(SELECT [no_reel] FROM [APCSProDB].[trans].[label_issue_records] WHERE [lot_no] = @lot_no AND [type_of_label] = 3)
				BEGIN
					INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
						( [record_at]
						, [record_class]
						, [login_name]
						, [hostname]
						, [appname]
						, [command_text]
						, [lot_no] )
					SELECT GETDATE()
						, '4'
						, ORIGINAL_LOGIN()
						, HOST_NAME()
						, APP_NAME()
						, 'RETURN EXEC [tg].[sp_get_check_data_ogi_by_cellcon] [Status] = TRUE'
							+ ' , [Title] = checkLastLabel'
							+ ' , [lastReel] = ' + ISNULL(CAST(MAX(CAST([no_reel] AS INT)) AS VARCHAR),'NULL')
							+ ' , [ReelCount] = ' + ISNULL(CAST(COUNT([no_reel]) AS VARCHAR),'NULL')
						, ISNULL(CAST(@lot_no AS VARCHAR),'NULL')
					FROM [APCSProDB].[trans].[label_issue_records] 
					WHERE [lot_no] = @lot_no 
						AND [type_of_label] = 3;

					SELECT 'TRUE' AS [Status]
						, 'checkLastLabel' AS [Title]
						, MAX(CAST([no_reel] AS INT)) AS [lastReel] 
						, COUNT([no_reel]) AS [ReelCount] 
					FROM [APCSProDB].[trans].[label_issue_records] 
					WHERE [lot_no] = @lot_no 
						AND [type_of_label] = 3;
				END
				ELSE
				BEGIN
					SELECT 'FALSE' AS [Status]
						, 'checkLastLabel' AS [Title]
						, 0 AS [lastReel] 
						, 0 AS [ReelCount];
				END
			END
		END
		ELSE
		BEGIN
			SELECT 'TRUE' AS [Status]
				, 'checkLastLabel' AS [Title]
				, 1 AS [lastReel] 
				, 1 AS [ReelCount];
		END
	END
	--=====================================================================================================================================================================================
	----# 3:checkDisableReel
	ELSE IF (@function = 3)
	BEGIN
		IF EXISTS(SELECT [no_reel] FROM [APCSProDB].[trans].[label_issue_records] WHERE [lot_no] = @lot_no AND [type_of_label] = 0)
		BEGIN
			INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
				( [record_at]
				, [record_class]
				, [login_name]
				, [hostname]
				, [appname]
				, [command_text]
				, [lot_no] )
			SELECT GETDATE()
				, '4'
				, ORIGINAL_LOGIN()
				, HOST_NAME()
				, APP_NAME()
				, 'RETURN EXEC [tg].[sp_get_check_data_ogi_by_cellcon] [Status] = TRUE'
					+ ' , [Title] = checkDisableReel'
					+ ' , [no_reel] = ' + (SELECT CAST(ISNULL( STUFF( ( SELECT CONCAT(',', CAST([no_reel] AS INT)) FROM [APCSProDB].[trans].[label_issue_records] WHERE [lot_no] = @lot_no AND [type_of_label] = 0 FOR XML PATH ('')), 1, 1, '' ), 'NULL' ) AS VARCHAR(MAX) ) )
				, ISNULL(CAST(@lot_no AS VARCHAR),'NULL');

			SELECT 'TRUE' AS [Status]
				, 'checkDisableReel' AS [Title]
				, (SELECT CAST(ISNULL( STUFF( ( SELECT CONCAT(',', CAST([no_reel] AS INT)) FROM [APCSProDB].[trans].[label_issue_records] WHERE [lot_no] = @lot_no AND [type_of_label] = 0 FOR XML PATH ('')), 1, 1, '' ), 'NULL' ) AS VARCHAR(MAX) ) ) AS [no_reel];
		END
		ELSE
		BEGIN
			SELECT 'FALSE' AS [Status]
				, 'checkDisableReel' AS [Title]
				, 0 AS [no_reel];
		END
	END
	--=====================================================================================================================================================================================
	----# 4:checkVersionLabel
	ELSE IF (@function = 4)
	BEGIN
		IF EXISTS(SELECT [id] FROM [APCSProDB].[trans].[lots] WHERE [lot_no] = @lot_no AND [pc_instruction_code] = 13)
		BEGIN
			IF EXISTS(SELECT [no_reel] FROM [APCSProDB].[trans].[label_issue_records] WHERE [lot_no] = @lot_no AND [no_reel] = @no_reel AND [type_of_label] = IIF(SUBSTRING(@lot_no,5,1) = 'D',20,2)) --support new pcrequest
			--IF EXISTS(SELECT [no_reel] FROM [APCSProDB].[trans].[label_issue_records] WHERE [lot_no] = @lot_no AND [no_reel] = 1 AND [type_of_label] = 2) --edit by aomsin 2024/01/09 time 14.14
			BEGIN
				INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
					( [record_at]
					, [record_class]
					, [login_name]
					, [hostname]
					, [appname]
					, [command_text]
					, [lot_no] )
				SELECT GETDATE()
					, '4'
					, ORIGINAL_LOGIN()
					, HOST_NAME()
					, APP_NAME()
					, 'RETURN EXEC [tg].[sp_get_check_data_ogi_by_cellcon] [Status] = TRUE'
						+ ' , [Title] = checkVersionLabel'
						+ ' , [qrcode_detail] = ' + ISNULL(CAST([qrcode_detail] AS VARCHAR(MAX)),'NULL')
						+ ' , [type_of_label] = ' + ISNULL(CAST([type_of_label]  AS VARCHAR(MAX)),'NULL')
						+ ' , [no_reel] = ' + ISNULL(CAST([no_reel] AS VARCHAR(MAX)),'NULL')
					, ISNULL(CAST(@lot_no AS VARCHAR),'NULL')
				FROM [APCSProDB].[trans].[label_issue_records] 
				WHERE [lot_no] = @lot_no 
					AND [no_reel] = 1 
					AND [type_of_label] = IIF(SUBSTRING(@lot_no,5,1) = 'D',20,2);
					--AND [type_of_label] = 2;

				SELECT 'TRUE' AS [Status]
					, 'checkVersionLabel' AS [Title]
					, TRIM([qrcode_detail]) AS [qrcode_detail]
					, [type_of_label]
					, [no_reel]
				FROM [APCSProDB].[trans].[label_issue_records] 
				WHERE [lot_no] = @lot_no 
					AND [no_reel] = 1 
					AND [type_of_label] = IIF(SUBSTRING(@lot_no,5,1) = 'D',20,2);
					--AND [type_of_label] = 2;
			END
			ELSE
			BEGIN
				SELECT 'FALSE' AS [Status]
					, 'checkVersionLabel' AS [Title]
					, NULL AS [qrcode_detail]
					, NULL AS [type_of_label]
					, NULL AS [no_reel];
			END
		END
		ELSE
		BEGIN
			IF EXISTS(SELECT [no_reel] FROM [APCSProDB].[trans].[label_issue_records] WHERE [lot_no] = @lot_no AND [no_reel] = @no_reel AND [type_of_label] IN (3,0))
			BEGIN
				INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
					( [record_at]
					, [record_class]
					, [login_name]
					, [hostname]
					, [appname]
					, [command_text]
					, [lot_no] )
				SELECT GETDATE()
					, '4'
					, ORIGINAL_LOGIN()
					, HOST_NAME()
					, APP_NAME()
					, 'RETURN EXEC [tg].[sp_get_check_data_ogi_by_cellcon] [Status] = TRUE'
						+ ' , [Title] = checkVersionLabel'
						+ ' , [qrcode_detail] = ' + ISNULL(CAST([qrcode_detail] AS VARCHAR(MAX)),'NULL')
						+ ' , [type_of_label] = ' + ISNULL(CAST([type_of_label]  AS VARCHAR(MAX)),'NULL')
						+ ' , [no_reel] = ' + ISNULL(CAST([no_reel] AS VARCHAR(MAX)),'NULL') + ',' + CAST(@no_reel as varchar(5))
					, ISNULL(CAST(@lot_no AS VARCHAR),'NULL')
				FROM [APCSProDB].[trans].[label_issue_records] 
				WHERE [lot_no] = @lot_no 
					AND [no_reel] = @no_reel 
					AND [type_of_label] IN (3,0);

				print 'TRUE checkVersionLabel' + ',' + CAST(@no_reel as varchar(5))
				SELECT 'TRUE' AS [Status]
					, 'checkVersionLabel' AS [Title]
					, TRIM([qrcode_detail]) AS [qrcode_detail]
					, [type_of_label]
					, [no_reel]
				FROM [APCSProDB].[trans].[label_issue_records] 
				WHERE [lot_no] = @lot_no 
					AND [no_reel] = @no_reel 
					AND [type_of_label] IN (3,0);
			END
			ELSE
			BEGIN
				SELECT 'FALSE' AS [Status]
					, 'checkVersionLabel' AS [Title]
					, NULL AS [qrcode_detail]
					, NULL AS [type_of_label]
					, NULL AS [no_reel];
			END
		END

	END
	--=====================================================================================================================================================================================
	----# 5:getDataInputOGI, 6:CheckLotMagic
	ELSE IF (@function = 5)
	BEGIN
		IF EXISTS(SELECT [qty_hasuu] FROM [APCSProDB].[trans].[lots] WHERE [lot_no] = @lot_no)
		BEGIN
			INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
				( [record_at]
				, [record_class]
				, [login_name]
				, [hostname]
				, [appname]
				, [command_text]
				, [lot_no] )
			SELECT GETDATE()
				, '4'
				, ORIGINAL_LOGIN()
				, HOST_NAME()
				, APP_NAME()
				, 'RETURN EXEC [tg].[sp_get_check_data_ogi_by_cellcon] [Status] = TRUE'
					+ ' , [Title] = getDataInputOGI'
					+ ' , [qty_hasuu] = ' + ISNULL(CAST([qty_hasuu]  AS VARCHAR),'NULL')
				, ISNULL(CAST(@lot_no AS VARCHAR),'NULL')
			FROM [APCSProDB].[trans].[lots]
			WHERE [lot_no] = @lot_no;

			SELECT 'TRUE' AS [Status]
				, 'getDataInputOGI' AS [Title]
				, IIF([pc_instruction_code] = 11,([qty_out] + [qty_hasuu]),[qty_out]) AS [Shipment]  --#Update 2025/01/08 Time : 15.55 by Aomsin
			FROM [APCSProDB].[trans].[lots]
			WHERE [lot_no] = @lot_no;
		END
		ELSE
		BEGIN
			SELECT 'FALSE' AS [Status]
				, 'getDataInputOGI' AS [Title]
				, 0 AS [Shipment];
		END
	END
	--=====================================================================================================================================================================================
	----# 6:CheckLotMagic
	ELSE IF (@function = 6)
	BEGIN
		IF EXISTS(SELECT [lot_id] FROM [APCSProDB].[trans].[lot_combine] WHERE [lot_id] = (SELECT [id] FROM [APCSProDB].[trans].[lots] WHERE [lot_no] = @lot_no))
		BEGIN
			INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
				( [record_at]
				, [record_class]
				, [login_name]
				, [hostname]
				, [appname]
				, [command_text]
				, [lot_no] )
			SELECT GETDATE()
				, '4'
				, ORIGINAL_LOGIN()
				, HOST_NAME()
				, APP_NAME()
				, 'RETURN EXEC [tg].[sp_get_check_data_ogi_by_cellcon] [Status] = TRUE'
					+ ' , [Title] = CheckLotMagic'
					+ ' , [CountNo] = ' + ISNULL(CAST(COUNT([lot_id])  AS VARCHAR),'NULL')
				, ISNULL(CAST(@lot_no AS VARCHAR),'NULL')
			FROM [APCSProDB].[trans].[lot_combine] 
			WHERE [lot_id] = (
				SELECT [id] 
				FROM [APCSProDB].[trans].[lots] 
				WHERE [lot_no] = @lot_no
			);

			SELECT 'TRUE' AS [Status]
				, 'CheckLotMagic' AS [Title]
				, COUNT([lot_id]) AS [CountNo]
			FROM [APCSProDB].[trans].[lot_combine] 
			WHERE [lot_id] = (
				SELECT [id] 
				FROM [APCSProDB].[trans].[lots] 
				WHERE [lot_no] = @lot_no
			);
		END
		ELSE
		BEGIN
			SELECT 'FALSE' AS [Status]
				, 'CheckLotMagic' AS [Title]
				, 0 AS [CountNo];
		END
	END
	--=====================================================================================================================================================================================
	----# 7:Check data type label in 4,5,6 before printing
	ELSE IF (@function = 7)
	BEGIN
		IF EXISTS(SELECT [lot_no] FROM [APCSProDB].[trans].[label_issue_records] WHERE [lot_no] = @lot_no and type_of_label in (4,5,6,21))
		BEGIN
			INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
				( [record_at]
				, [record_class]
				, [login_name]
				, [hostname]
				, [appname]
				, [command_text]
				, [lot_no] )
			SELECT GETDATE()
				, '4'
				, ORIGINAL_LOGIN()
				, HOST_NAME()
				, APP_NAME()
				, 'RETURN EXEC [tg].[sp_get_check_data_ogi_by_cellcon] [Status] = TRUE'
					+ ' , [Title] = There is label data by Function : 7 (Check data type label in 4,5,6,21 before printing)'
				, ISNULL(CAST(@lot_no AS VARCHAR),'NULL'
			)
			
			SELECT 'TRUE' AS [Status]
				, 'There is label data' AS [Title]
				, COUNT([lot_id]) AS [CountNo]
			FROM [APCSProDB].[trans].[lot_combine] 
			WHERE [lot_id] = (
				SELECT [id] 
				FROM [APCSProDB].[trans].[lots] 
				WHERE [lot_no] = @lot_no
			);
		END
		ELSE
		BEGIN
			INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
				( [record_at]
				, [record_class]
				, [login_name]
				, [hostname]
				, [appname]
				, [command_text]
				, [lot_no] )
			SELECT GETDATE()
				, '4'
				, ORIGINAL_LOGIN()
				, HOST_NAME()
				, APP_NAME()
				, 'RETURN EXEC [tg].[sp_get_check_data_ogi_by_cellcon] [Status] = FALSE'
					+ ' , [Title] = Can not label data of ogi process by Function : 7 (Check data type label in 4,5,6,21 before printing)'
				, ISNULL(CAST(@lot_no AS VARCHAR),'NULL'
			)

			SELECT 'FALSE' AS [Status]
				, 'Can not label data of ogi process' AS [Title]
				, 0 AS [CountNo];
		END
	END
	--=====================================================================================================================================================================================
	ELSE IF (@function = 8)  --Date modify 2024/05/24 time : 15.21 by Aomsin
	BEGIN
		DECLARE @is_logo tinyint = null

		SELECT @is_logo = dn.required_ul_logo FROM APCSProDB.trans.lots 
		INNER JOIN APCSProDB.method.device_names AS dn on lots.act_device_name_id = dn.id
		WHERE lot_no = @lot_no

		IF @is_logo = 0
		BEGIN
			SELECT 'FALSE' AS [Status]
				, 'Logo is not used' AS [Title]
				, 0 AS [required_ul_logo];
		END
		ELSE IF @is_logo = 1
		BEGIN
			SELECT 'TRUE' AS [Status]
				, 'UL Logo is used' AS [Title]
				, @is_logo AS [required_ul_logo];
		END
		ELSE IF @is_logo = 2
		BEGIN
			SELECT 'TRUE' AS [Status]
				, 'Test Marking Logo is used' AS [Title]
				, @is_logo AS [required_ul_logo];
		END
		ELSE
		BEGIN
			IF @is_logo = null
			BEGIN
				SELECT 'FALSE' AS [Status]
					, 'Logo is not used and data is null' AS [Title]
					, ISNULL(0,@is_logo) AS [required_ul_logo];
			END
			ELSE
			BEGIN
				SELECT 'TRUE' AS [Status]  --Used in case of new logo.
					, 'Logo is used' AS [Title]
					, @is_logo AS [required_ul_logo];
			END
		END
	END
	--=====================================================================================================================================================================================
END
