CREATE FUNCTION [atom].[fnc_get_recipe_ver_003](
	@lot_id INT,
	@job_id INT
)
    RETURNS @table_recipe TABLE (
		[recipe] VARCHAR(30)
	)
AS
BEGIN
	----# 0: GO/NGSampleJudge หา recipe จาก flow ปัจจุบัน
	IF (@job_id = 366)
	BEGIN
		INSERT INTO @table_recipe ([recipe])
		SELECT (CASE WHEN ISNULL([lots].[is_special_flow], 0) = 1 THEN [lot_special_flows].[recipe] ELSE [device_flows].[recipe] END) --AS [recipe]
		FROM [APCSProDB].[trans].[lots]
		INNER JOIN [APCSProDB].[method].[device_flows] ON [lots].[device_slip_id] = [device_flows].[device_slip_id]  
			AND [lots].[step_no] = [device_flows].[step_no]
		LEFT JOIN [APCSProDB].[trans].[special_flows] ON [lots].[special_flow_id] = [special_flows].[id] 
			AND [lots].[is_special_flow] = 1 
		LEFT JOIN [APCSProDB].[trans].[lot_special_flows] ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
			AND [special_flows].[step_no] = [lot_special_flows].[step_no] 
		WHERE [lots].[id] = @lot_id

		--SELECT * FROM @table_recipe AS [recipe]
		--PRINT 0
		RETURN;
	END

	----# 1: หา flow จาก device_flows ของ lots
	INSERT INTO @table_recipe ([recipe])
	SELECT [recipe]
	FROM (
		SELECT [device_flows].[step_no]
			, [device_flows].[job_id]
			, [device_flows].[recipe]
			, [jobs].[name]
		FROM [APCSProDB].[trans].[lots]
		INNER JOIN [APCSProDB].[method].[device_flows] ON [device_flows].[device_slip_id] = [lots].[device_slip_id] 
		INNER JOIN [APCSProDB].[method].[jobs] ON [device_flows].[job_id] = [jobs].[id]
		WHERE [lots].[id] = @lot_id
	) AS [condition1]
	WHERE [job_id] = @job_id
		
	IF EXISTS (SELECT * FROM @table_recipe)
	BEGIN
		--SELECT * FROM @table_recipe AS [recipe]
		--PRINT 1
		RETURN;
	END

	----# 2: หา job common ใน where job_id เอา to_job_id ใช้ หาใน master flow
	INSERT INTO @table_recipe (recipe)
	SELECT [recipe]
	FROM (
		SELECT [device_flows].[step_no]
			, [job_commons].[job_id]
			, [jobs2].[name] AS [job_name]
			, [device_flows].[recipe]
			, [job_commons].[to_job_id]
			, [jobs].[name] AS [to_job_name]
		FROM [APCSProDB].[trans].[lots]
		INNER JOIN [APCSProDB].[method].[device_flows] ON [device_flows].[device_slip_id] = [lots].[device_slip_id] 
		INNER JOIN [APCSProDB].[trans].[job_commons] ON [device_flows].[job_id] = [job_commons].[to_job_id]
		INNER JOIN [APCSProDB].[method].[jobs] ON [jobs].[id] = [job_commons].[to_job_id]
		INNER JOIN [APCSProDB].[method].[jobs] AS [jobs2] ON [jobs2].[id] = [job_commons].[job_id]
		WHERE [lots].[id] = @lot_id
	) AS [condition2]
	WHERE [job_id] = @job_id

	IF EXISTS (SELECT * FROM @table_recipe)
	BEGIN
		--SELECT * FROM @table_recipe AS [recipe]
		--PRINT 2
		RETURN;
	END

	----# 3: หา job common ใน where to_job_id เอา job_id ใช้ หาใน master flow
	INSERT INTO @table_recipe (recipe)
	SELECT [recipe]
	FROM (
		SELECT [device_flows].[step_no]
			, [device_flows].[job_id]
			, [jobs2].[name] AS [job_name]
			, [device_flows].[recipe]
			, [job_commons].[to_job_id]
			, [jobs].[name] AS [to_job_name]
		FROM [APCSProDB].[trans].[lots]
		INNER JOIN [APCSProDB].[method].[device_flows] ON [device_flows].[device_slip_id] = [lots].[device_slip_id] 
		INNER JOIN [APCSProDB].[trans].[job_commons] ON [device_flows].[job_id] = [job_commons].[job_id]
		INNER JOIN [APCSProDB].[method].[jobs] ON [jobs].[id] = [job_commons].[to_job_id]
		INNER JOIN [APCSProDB].[method].[jobs] AS [jobs2] ON [jobs2].[id] = [job_commons].[job_id]
		WHERE [lots].[id] = @lot_id
	) AS [condition3]
	WHERE [to_job_id] = @job_id

	IF EXISTS (SELECT * FROM @table_recipe)
	BEGIN
		--SELECT * FROM @table_recipe AS [recipe]
		--PRINT 3
		RETURN;
	END

	----# 4-6: หา flow จาก master flow ของ Slip A
	IF ((SELECT SUBSTRING([lots].[lot_no],5,1) FROM [APCSProDB].[trans].[lots] WHERE [lots].[id] = @lot_id) = 'D')
	BEGIN
		----# 4: หา flow จาก master flow ของ Slip A
		INSERT INTO @table_recipe ([recipe])
		SELECT [recipe]
		FROM (
			SELECT [device_slips].[device_slip_id]
				, [device_slips].[step_no]
				, [device_slips].[recipe]
				, [device_slips].[job_id]
				, [device_slips].[job_name] 
			FROM [APCSProDB].[trans].[lots]
			CROSS APPLY (
				SELECT [device_slips].[device_slip_id]
					, [device_slips].[device_version]
					, [device_flows].[step_no]
					, [device_flows].[recipe]
					, [device_flows].[job_id]
					, [jobs].[name] AS [job_name]
					, DENSE_RANK() OVER (ORDER BY [device_slips].[device_version] DESC) AS [max]
				FROM (
					SELECT [device_versions].[device_name_id]
						, [device_versions].[device_type]
					FROM [APCSProDB].[method].[device_slips]
					INNER JOIN [APCSProDB].[method].[device_versions] ON [device_slips].[device_id] = [device_versions].[device_id]
					WHERE [device_slips].[device_slip_id] = [lots].[device_slip_id]	
				) AS [device_table]
				CROSS APPLY (
					SELECT [device_slips].[device_slip_id]
						, [device_slips].[version_num] AS [device_version]
						, [device_slips].[is_released]
					FROM [APCSProDB].[method].[device_slips]
					INNER JOIN [APCSProDB].[method].[device_versions] ON [device_slips].[device_id] = [device_versions].[device_id]
					WHERE [device_versions].[device_name_id] = [device_table].[device_name_id] 
						AND [device_versions].[device_type] = 0
						AND [device_slips].[is_released] = 1
				) AS [device_slips]
				INNER JOIN [APCSProDB].[method].[device_flows] ON [device_slips].[device_slip_id] = [device_flows].[device_slip_id]
				INNER JOIN [APCSProDB].[method].[jobs] ON [device_flows].[job_id] = [jobs].[id]
				WHERE [device_flows].[is_skipped] = 0
			) AS [device_slips]
			WHERE [lots].[id] = @lot_id
				AND [max] = 1
		) AS [condition4]
		WHERE [job_id] = @job_id

		IF EXISTS (SELECT * FROM @table_recipe)
		BEGIN
			--SELECT * FROM @table_recipe AS [recipe]
			--PRINT 4
			RETURN;
		END
		
		----# 5: หา job common ใน where job_id เอา to_job_id ใช้ หาใน master flow ของ Slip A
		INSERT INTO @table_recipe (recipe)
		SELECT [recipe]
		FROM (
			SELECT [device_flows].[step_no]
				, [job_commons].[job_id]
				, [jobs2].[name] AS [job_name]
				, [device_flows].[recipe]
				, [job_commons].[to_job_id]
				, [jobs].[name] AS [to_job_name]
			FROM (
				SELECT [device_slips].[device_slip_id]
					, [device_slips].[step_no]
					, [device_slips].[recipe]
					, [device_slips].[job_id]
					, [device_slips].[job_name] 
				FROM [APCSProDB].[trans].[lots]
				CROSS APPLY (
					SELECT [device_slips].[device_slip_id]
						, [device_slips].[device_version]
						, [device_flows].[step_no]
						, [device_flows].[recipe]
						, [device_flows].[job_id]
						, [jobs].[name] AS [job_name]
						, DENSE_RANK() OVER (ORDER BY [device_slips].[device_version] DESC) AS [max]
					FROM (
						SELECT [device_versions].[device_name_id]
							, [device_versions].[device_type]
						FROM [APCSProDB].[method].[device_slips]
						INNER JOIN [APCSProDB].[method].[device_versions] ON [device_slips].[device_id] = [device_versions].[device_id]
						WHERE [device_slips].[device_slip_id] = [lots].[device_slip_id]	
					) AS [device_table]
					CROSS APPLY (
						SELECT [device_slips].[device_slip_id]
							, [device_slips].[version_num] AS [device_version]
							, [device_slips].[is_released]
						FROM [APCSProDB].[method].[device_slips]
						INNER JOIN [APCSProDB].[method].[device_versions] ON [device_slips].[device_id] = [device_versions].[device_id]
						WHERE [device_versions].[device_name_id] = [device_table].[device_name_id] 
							AND [device_versions].[device_type] = 0
							AND [device_slips].[is_released] = 1
					) AS [device_slips]
					INNER JOIN [APCSProDB].[method].[device_flows] ON [device_slips].[device_slip_id] = [device_flows].[device_slip_id]
					INNER JOIN [APCSProDB].[method].[jobs] ON [device_flows].[job_id] = [jobs].[id]
					WHERE [device_flows].[is_skipped] = 0
				) AS [device_slips]
				WHERE [lots].[id] = @lot_id
					AND [max] = 1
			) AS [device_flows]
			INNER JOIN [APCSProDB].[trans].[job_commons] ON [device_flows].[job_id] = [job_commons].[to_job_id]
			INNER JOIN [APCSProDB].[method].[jobs] ON [jobs].[id] = [job_commons].[to_job_id]
			INNER JOIN [APCSProDB].[method].[jobs] AS [jobs2] ON [jobs2].[id] = [job_commons].[job_id]
		) AS [condition5]
		WHERE [job_id] = @job_id 

		IF EXISTS (SELECT * FROM @table_recipe)
		BEGIN
			--SELECT * FROM @table_recipe AS [recipe]
			--PRINT 5
			RETURN;
		END

		----# 6: หา job common ใน where to_job_id เอา job_id ใช้ หาใน master flow ของ Slip A
		INSERT INTO @table_recipe (recipe)
		SELECT [recipe]
		FROM (
			SELECT [device_flows].[step_no]
				, [device_flows].[job_id]
				, [jobs2].[name] AS [job_name]
				, [device_flows].[recipe]
				, [job_commons].[to_job_id]
				, [jobs].[name] AS [to_job_name]
			FROM (
				SELECT [device_slips].[device_slip_id]
					, [device_slips].[step_no]
					, [device_slips].[recipe]
					, [device_slips].[job_id]
					, [device_slips].[job_name] 
				FROM [APCSProDB].[trans].[lots]
				CROSS APPLY (
					SELECT [device_slips].[device_slip_id]
						, [device_slips].[device_version]
						, [device_flows].[step_no]
						, [device_flows].[recipe]
						, [device_flows].[job_id]
						, [jobs].[name] AS [job_name]
						, DENSE_RANK() OVER (ORDER BY [device_slips].[device_version] DESC) AS [max]
					FROM (
						SELECT [device_versions].[device_name_id]
							, [device_versions].[device_type]
						FROM [APCSProDB].[method].[device_slips]
						INNER JOIN [APCSProDB].[method].[device_versions] ON [device_slips].[device_id] = [device_versions].[device_id]
						WHERE [device_slips].[device_slip_id] = [lots].[device_slip_id]	
					) AS [device_table]
					CROSS APPLY (
						SELECT [device_slips].[device_slip_id]
							, [device_slips].[version_num] AS [device_version]
							, [device_slips].[is_released]
						FROM [APCSProDB].[method].[device_slips]
						INNER JOIN [APCSProDB].[method].[device_versions] ON [device_slips].[device_id] = [device_versions].[device_id]
						WHERE [device_versions].[device_name_id] = [device_table].[device_name_id] 
							AND [device_versions].[device_type] = 0
							AND [device_slips].[is_released] = 1
					) AS [device_slips]
					INNER JOIN [APCSProDB].[method].[device_flows] ON [device_slips].[device_slip_id] = [device_flows].[device_slip_id]
					INNER JOIN [APCSProDB].[method].[jobs] ON [device_flows].[job_id] = [jobs].[id]
					WHERE [device_flows].[is_skipped] = 0
				) AS [device_slips]
				WHERE [lots].[id] = @lot_id
					AND [max] = 1
			) AS [device_flows]
			INNER JOIN [APCSProDB].[trans].[job_commons] on [device_flows].[job_id] = [job_commons].[job_id]
			INNER JOIN [APCSProDB].[method].[jobs] on [jobs].[id] = [job_commons].[to_job_id]
			INNER JOIN [APCSProDB].[method].[jobs] [jobs2] on [jobs2].[id] = [job_commons].[job_id]
		) AS [condition6]
		WHERE [to_job_id] = @job_id

		IF EXISTS (SELECT * FROM @table_recipe)
		BEGIN
			--SELECT * FROM @table_recipe AS [recipe]
			--PRINT 6
			RETURN;
		END
	END

	--PRINT 'END';
	RETURN;
END;