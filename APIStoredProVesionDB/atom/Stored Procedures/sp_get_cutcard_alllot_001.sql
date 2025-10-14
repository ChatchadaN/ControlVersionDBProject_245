-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_get_cutcard_alllot_001]
	-- Add the parameters for the stored procedure here
	@lot_no varchar(10) ,
	@step_no int = null

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;	
    -- Insert statements for procedure here
	-- PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' --- start');

	DECLARE @table TABLE
	(
		[lot_id] INT,
		[lot_no] VARCHAR(10),
		[step_no] INT,
		[job_name] VARCHAR(20),
		[flow] INT,
		[packagename] VARCHAR(10),
		[ftname] VARCHAR(20),
		[rank] NVARCHAR(5)
	)

	DECLARE @step_no_mix INT = null,
			@lot_id INT,
			@markno1 VARCHAR(10),
			@markno2 VARCHAR(10)

	SET @lot_id =
	(
		SELECT [id]
		FROM [APCSProDB].[trans].[lots] WITH (NOLOCK)
		WHERE [lot_no] = @lot_no
	);
	-----------------------------------------------------------------------------------
	-- #set flow lot
	-----------------------------------------------------------------------------------
	INSERT INTO @table
	SELECT [lots].[id] AS [lot_id],
		   [lots].[lot_no],
		   [lots].[step_no],
		   [lots].[job_name],
		   [lots].[flow],
		   [packages].[short_name] AS [packagename],
		   [device_names].[ft_name] AS [ftname],
		   [device_names].[rank] AS [rank]
	FROM
	(
		SELECT [lots].[id],
			   [lots].[lot_no],
			   [device_flows].[step_no] AS [step_no],
			   [jobs].[name] AS [job_name],
			   0 AS [flow],
			   [lots].[act_device_name_id]
		FROM [APCSProDB].[trans].[lots] WITH (NOLOCK)
			INNER JOIN [APCSProDB].[method].[device_flows] WITH (NOLOCK)
				ON [lots].[device_slip_id] = [device_flows].[device_slip_id]
			LEFT JOIN [APCSProDB].[method].[jobs] WITH (NOLOCK)
				ON [device_flows].[job_id] = [jobs].[id]
		WHERE [lots].[id] = @lot_id
			  AND [device_flows].[is_skipped] = 0
		UNION ALL
		SELECT [lots].[id],
			   [lots].[lot_no],
			   [lot_special_flows].[step_no] AS [step_no],
			   [jobs].[name] AS [job_name],
			   1 AS [flow],
			   [lots].[act_device_name_id]
		FROM [APCSProDB].[trans].[lots] WITH (NOLOCK)
			LEFT JOIN [APCSProDB].[trans].[special_flows] WITH (NOLOCK)
				ON [lots].[id] = [special_flows].[lot_id]
			LEFT JOIN [APCSProDB].[trans].[lot_special_flows] WITH (NOLOCK)
				ON [special_flows].[id] = [lot_special_flows].[special_flow_id]
			LEFT JOIN [APCSProDB].[method].[jobs] WITH (NOLOCK)
				ON [lot_special_flows].[job_id] = [jobs].[id]
		WHERE [lots].[id] = @lot_id
	) AS [lots]
	INNER JOIN [APCSProDB].[method].[device_names] 
		ON [lots].[act_device_name_id] = [device_names].[id]
	INNER JOIN [APCSProDB].[method].[packages] 
		ON [device_names].[package_id] = [packages].[id]
	ORDER BY [step_no];
	--PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' --- set flow lot');
	-----------------------------------------------------------------------------------
	-- #check flow mix
	-----------------------------------------------------------------------------------
	IF EXISTS
	(
		SELECT [lot_id]
		FROM [APCSProDB].[trans].[lot_combine] WITH (NOLOCK)
		WHERE [lot_id] = @lot_id
	)
	BEGIN
		--<< IF 1----------------------------------------------------------------
		IF EXISTS
		(
			SELECT [job_name]
			FROM @table
			WHERE [flow] = 0
				  AND [job_name] IN ( 'TP-TP', 'TP', 'FL', 'FT-TP', 'FLFTTP' )
		)
		BEGIN
			SET @step_no_mix =
			(
				SELECT TOP 1
					[step_no]
				FROM @table
				WHERE [flow] = 0
					  AND [job_name] IN ( 'TP-TP', 'TP', 'FL', 'FT-TP', 'FLFTTP' )
				ORDER BY [step_no] DESC
			);
		END
		ELSE IF EXISTS
		(
			SELECT [job_name]
			FROM @table
			WHERE [flow] = 1
				  AND [job_name] in ( 'TP-TP', 'TP', 'FL', 'FT-TP', 'FLFTTP' )
		)
		BEGIN
			SET @step_no_mix =
			(
				SELECT TOP 1
					[step_no]
				FROM @table
				WHERE [flow] = 1
					  AND [job_name] IN ( 'TP-TP', 'TP', 'FL', 'FT-TP', 'FLFTTP' )
				ORDER BY [step_no] ASC
			);
		END
		-->> IF 1----------------------------------------------------------------
	END
	--PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' --- check flow mix');
	-----------------------------------------------------------------------------------
	-- #get mark_no
	-----------------------------------------------------------------------------------
	SELECT TOP 1
		@markno1
			= IIF(SUBSTRING([lot_master].[lot_no], 5, 1) IN ( 'D' ),
				  [surpluses_master].[mark_no],
				  ISNULL([allocat_master].[MNo], [allocat_temp_master].[MNo])), --AS [markno1] 
		@markno2
			= IIF(SUBSTRING([lot_master].[lot_no], 5, 1) IN ( 'D', 'F' ),
				  '',
				  ISNULL([allocat_member].[MNo], [allocat_temp_member].[MNo]))  --AS [markno2]
	FROM [APCSProDB].[trans].[lots] AS [lot_master] WITH (NOLOCK)
		LEFT JOIN [APCSProDB].[method].[allocat] AS [allocat_master] WITH (NOLOCK)
			ON [lot_master].[lot_no] = [allocat_master].[LotNo]
		LEFT JOIN [APCSProDB].[method].[allocat_temp] AS [allocat_temp_master] WITH (NOLOCK)
			ON [lot_master].[lot_no] = [allocat_temp_master].[LotNo]
		LEFT JOIN [APCSProDB].[trans].[surpluses] AS [surpluses_master] WITH (NOLOCK)
			ON [lot_master].[lot_no] = [surpluses_master].[serial_no]
		--member-----------------------------------------------------------------------
		LEFT JOIN [APCSProDB].[trans].[lot_combine] WITH (NOLOCK)
			ON [lot_master].[id] = [lot_combine].[lot_id]
			   AND [lot_combine].[lot_id] != [lot_combine].[member_lot_id]
		LEFT JOIN [APCSProDB].[trans].[lots] AS [lot_member] WITH (NOLOCK)
			ON [lot_combine].[member_lot_id] = [lot_member].[id]
		LEFT JOIN [APCSProDB].[method].[allocat] AS [allocat_member] WITH (NOLOCK)
			ON [lot_member].[lot_no] = [allocat_member].[LotNo]
		LEFT JOIN [APCSProDB].[method].[allocat_temp] AS [allocat_temp_member] WITH (NOLOCK)
			ON [lot_member].[lot_no] = [allocat_temp_member].[LotNo]
		LEFT JOIN [APCSProDB].[trans].[surpluses] AS [surpluses_member] WITH (NOLOCK)
			ON [lot_member].[lot_no] = [surpluses_member].[serial_no]
		--member-----------------------------------------------------------------------
	WHERE [lot_master].[id] = @lot_id
	ORDER BY [lot_combine].[idx] ASC;
	--PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' --- get mark_no');
	-----------------------------------------------------------------------------------
	-- #select data
	-----------------------------------------------------------------------------------
	SELECT [lots].[lot_no],
		   [lots].[packagename],
		   [lots].[ftname],
		   ISNULL([lots].[rank], '') AS [rank],
		   [lot_process_records].[endlot],
		   [lots].[step_no],
		   CAST([lot_process_records].[job_name] AS VARCHAR) AS [job_name],
		   [lot_process_records].[machinename],
		   [lot_process_records].[ng],
		   0 AS [ngmecha],
		   CAST([lots].[ftname] AS CHAR(20)) 
			+ CAST([lots].[lot_no] AS CHAR(10)) 
			+ CAST(ISNULL(@markno1, '') AS CHAR(10))
			+ CAST([lots].[packagename] AS CHAR(10)) 
		   AS [qrcode],
		   ISNULL(@markno1, '') AS [markno1],
		   IIF([lots].[step_no] < @step_no_mix,'',ISNULL(@markno2,''))  AS [markno2]--,
		   --[ng2],
		   --[mechang_FLFTTP],
		   --[mechang_FL],
		   --[mechang_TP],
		   --[lot_process_records].[extend_data]
	FROM @table AS [lots]
		CROSS APPLY
	(
		SELECT TOP 1
			[lot_process_records].[id],
			FORMAT([lot_process_records].[recorded_at], 'yyyy-MM-dd') AS [endlot],
			[lot_process_records].[step_no],
			[machines].[name] AS [machinename],
			[jobs].[name] AS [job_name],
			[lot_process_records].[qty_last_fail] AS [ng]
			--X.Y.value('(NgAdjustQty)[1]', 'INT') AS [ng2],
			--X.Y.value('(MekaNGAdjust)[1]', 'INT') AS [mechang_FLFTTP],
			--X.Y.value('(MekaNG)[1]', 'INT') AS [mechang_FL],
			--X.Y.value('(MechaNG)[1]', 'INT') AS [mechang_TP],
			--[lot_extend_records].[extend_data]
		FROM [APCSProDB].[trans].[lot_process_records] WITH (NOLOCK) 
			LEFT JOIN [APCSProDB].[mc].[machines] WITH (NOLOCK)
				ON [lot_process_records].[machine_id] = [machines].[id]
			LEFT JOIN [APCSProDB].[method].[jobs] WITH (NOLOCK)
				ON [lot_process_records].[job_id] = [jobs].[id]
			--LEFT JOIN [APCSProDB].[trans].[lot_extend_records] WITH (NOLOCK)
			--	ON [lot_process_records].[id] = [lot_extend_records].[id]
			--OUTER APPLY [lot_extend_records].[extend_data].[nodes]('LotDataCommon') as X(Y)
		WHERE [lot_process_records].[lot_id] = [lots].[lot_id]
			  AND [lot_process_records].[step_no] = [lots].[step_no]
			  AND [lot_process_records].[record_class] = 2
		ORDER BY [lot_process_records].[id] DESC
	) AS [lot_process_records]
	WHERE [lots].[step_no] = @step_no
	ORDER BY [lots].[step_no] ASC;
	--PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' --- select data');
	--PRINT(format(getdate(), 'yyyy-MM-dd HH:mm:ss.fff') + ' --- end');
END
