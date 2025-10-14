CREATE FUNCTION [atom].[fnc_get_mat_and_jig](
	@lot_id INT,
	@job_id INT
)
    RETURNS @table_mat_jig TABLE (
		material_set_id INT,
		jig_set_id INT
	)
AS
BEGIN

		DECLARE @type_lot VARCHAR(1)

		SET @type_lot = (SELECT SUBSTRING([lot_no],5,1) FROM [APCSProDB].[trans].[lots] WHERE [id] = @lot_id);

		IF (@job_id IN (236,289,369,222,397,93,401)) ---- #236,289 : TP, 369 : TP-TP, 222 : FT-TP, 397 : TP Rework, 93 : FLFTTP, 401 : OS+FT-TP
		BEGIN
			----# TP Rework
			INSERT INTO @table_mat_jig ([material_set_id], [jig_set_id])
			SELECT [material_set_id], [jig_set_id] 
			FROM [APCSProDB].[method].[device_flows]
			INNER JOIN [APCSProDB].[trans].[lots] 
				ON [device_flows].[device_slip_id] = [lots].[device_slip_id]
			WHERE [lots].[id] = @lot_id
				AND [device_flows].[job_id] IN (236,289,369,222,93,401) --236,289 : TP, 369 : TP-TP, 222 : FT-TP, 93 : FLFTTP, 401 : OS+FT-TP
				AND [device_flows].[is_skipped] = 0

			IF NOT EXISTS( SELECT 1 FROM @table_mat_jig ) AND (@type_lot = 'D')
			BEGIN
				INSERT INTO @table_mat_jig ([material_set_id], [jig_set_id])
				SELECT [material_set_id]
					, [jig_set_id]
				FROM (
					SELECT [device_flows].[device_slip_id]
						, [device_flows].[step_no]
						, [device_flows].[material_set_id]
						, [device_flows].[jig_set_id]
						, [jobs].[id] AS [job_id]
						, [jobs].[name] AS [job_name]
					FROM [APCSProDB].[method].[device_flows]
					INNER JOIN [APCSProDB].[method].[jobs] 
						ON [device_flows].[job_id] = [jobs].[id]
					WHERE [device_flows].[device_slip_id] = (
							SELECT [device_slip_id] FROM [APCSProDB].[method].[device_versions]
							INNER JOIN [APCSProDB].[method].[device_slips] 
								ON [device_versions].[device_id] = [device_slips].[device_id] 
								AND [device_versions].[version_num] = [device_slips].[version_num]
							WHERE [device_name_id] = (
									SELECT [act_device_name_id] FROM [APCSProDB].[trans].[lots]
									WHERE [id] = @lot_id
								) 
								AND [device_type] = 0
								AND [is_released] = 1
						)
						AND [device_flows].[is_skipped] = 0
				) AS [table_data]
				WHERE [job_id]  IN (236,289,369,222,93,401);
			END
			RETURN;
		END
		ELSE
		BEGIN
			----# Other
			IF (@type_lot = 'D')
			BEGIN
				----# D type
				INSERT INTO @table_mat_jig ([material_set_id], [jig_set_id])
				SELECT [material_set_id]
					, [jig_set_id]
				FROM (
					SELECT [device_flows].[device_slip_id]
						, [device_flows].[step_no]
						, [device_flows].[material_set_id]
						, [device_flows].[jig_set_id]
						, [jobs].[id] AS [job_id]
						, [jobs].[name] AS [job_name]
					FROM [APCSProDB].[method].[device_flows]
					INNER JOIN [APCSProDB].[method].[jobs] 
						ON [device_flows].[job_id] = [jobs].[id]
					WHERE [device_flows].[device_slip_id] = (
							SELECT [device_slip_id] FROM [APCSProDB].[method].[device_versions]
							INNER JOIN [APCSProDB].[method].[device_slips] 
								ON [device_versions].[device_id] = [device_slips].[device_id] 
								AND [device_versions].[version_num] = [device_slips].[version_num]
							WHERE [device_name_id] = (
									SELECT [act_device_name_id] FROM [APCSProDB].[trans].[lots]
									WHERE [id] = @lot_id
								) 
								AND [device_type] = 0
								AND [is_released] = 1
						)
						AND [device_flows].[is_skipped] = 0
				) AS [table_data]
				WHERE [job_id] = @job_id;
				RETURN;
			END
			ELSE
			BEGIN
				----# Other type lot
				INSERT INTO @table_mat_jig ([material_set_id], [jig_set_id])
				SELECT [material_set_id], [jig_set_id]
				FROM [APCSProDB].[method].[device_flows]
				INNER JOIN [APCSProDB].[trans].[lots] 
					ON [device_flows].[device_slip_id] = [lots].[device_slip_id]
				WHERE [lots].[id] = @lot_id
					AND [device_flows].[job_id] = @job_id
					AND [device_flows].[is_skipped] = 0;
				RETURN;
			END
		END
		RETURN;
END;