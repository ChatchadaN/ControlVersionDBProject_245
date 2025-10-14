-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_ukebarai_data_ver_002]
	-- Add the parameters for the stored procedure here
	@lot_id INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @LotID INT = 0
		, @JobID INT = 0
		, @date VARCHAR(6) = NULL
		, @time VARCHAR(4) = NULL
		, @good_qty INT = 0
		, @ng_qty INT = 0
		, @shipment_qty INT = 0
		, @LotNo VARCHAR(10) 
		, @process_no INT = 0
		, @job_name VARCHAR(100)

    -- Insert statements for procedure here
	--<<--------------------------------------------------------------------------
	--- ** log exec
	-->>-------------------------------------------------------------------------
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
		, 'EXEC [dbo].[sp_set_ukebarai_data_ver_002] @lot_id = ' + ISNULL(CAST(@lot_id AS VARCHAR(100)),'')
		, (SELECT CAST([lot_no] AS VARCHAR(10)) FROM [APCSProDB].[trans].[lots] WHERE [id] = @lot_id);
	--------------------------------------------------------------------------
	--- **  select data insert [APCSProDWH].[dbo].[ukebarais]
	-------------------------------------------------------------------------
	SELECT TOP (1) @LotID = lot_id
		, @JobID = job_id 
		, @date = FORMAT([lot_process_records].[recorded_at], 'yyMMdd') 
		, @time = FORMAT([lot_process_records].[recorded_at], 'HHmm')
		, @good_qty = [lot_process_records].[qty_last_pass]
		, @ng_qty = [lot_process_records].[qty_last_fail]
		, @shipment_qty = IIF([lot_process_records].[process_id] = 18, ISNULL([lot_process_records].[qty_out], 0), 0)
	FROM [APCSProDB].[trans].[lot_process_records]
	WHERE [lot_process_records].[lot_id] = @lot_id 
		AND [lot_process_records].[record_class] = 2
	ORDER BY [lot_process_records].[id] DESC;  

	SELECT @LotNo = TRIM([lots].[lot_no]) 
	FROM [APCSProDB].[trans].[lots]
	WHERE [lots].[id] = @lot_id;

	SELECT @process_no = 
		( CASE WHEN [jobs].[name] IN ('DB','DB1','DB1(3)','DB1(2)') THEN 201
			WHEN [jobs].[name] IN ('WB', 'WB1', 'WB2') THEN 203
			WHEN [jobs].[name] IN ('MP') THEN 206
			WHEN [jobs].[name] IN ('PL') THEN 502
			WHEN [jobs].[name] IN ('FL', 'FLFT', 'FLFTTP', 'FL(OS1)') THEN 750
			WHEN [jobs].[name] IN ('AUTO(1)'
				, 'OS+AUTO(1)'
				, 'AUTO(1) SBLSYL'
				, 'FT-TP'
				, 'OS+FT-TP'
				, 'FT-TP SBLSYL'
				, 'OS+FT-TP SBLSYL'
				, 'AUTO(Lapis)'
				, 'AUTO(1) BIN27'
				, 'AUTO(1) BIN27-CF'
				, 'AUTO(1) RE') THEN 892 
			WHEN [jobs].[name] IN ('AUTO(2)', 'AUTO(2) SBLSYL') THEN 893
			WHEN [jobs].[name] IN ('AUTO(3)', 'AUTO(3) SBLSYL', 'AUTO(3) BIN27'
				, 'AUTO(3) BIN27-CF') THEN 894
			WHEN [jobs].[name] IN ('AUTO(4)', 'AUTO(4) SBLSYL') THEN 895
			WHEN [jobs].[name] IN ('AUTO(5)', 'AUTO(5) SBLSYL', 'AUTO(6)') THEN 896
			WHEN [jobs].[name] IN ('OS') THEN 891
			WHEN [jobs].[name] IN ('TP', 'TP-TP', 'TP Rework') THEN 1001
			WHEN [jobs].[name] IN ('OUT GOING INSP') THEN 1201
			WHEN [jobs].[name] IN ('PKG DICER', 'PKG･DICER') THEN 252
			ELSE 0
		END )
	FROM [APCSProDB].[method].[jobs]
	INNER JOIN [APCSProDB].[method].[processes] on [jobs].[process_id] = [processes].[id]
	WHERE [jobs].[id] = @JobID;

	IF (@process_no != 0)
	BEGIN
		----------------------check good_qty & ng_qty & shipment_qty -----------------------
		IF (@good_qty < 0) OR (@ng_qty < 0) OR (@shipment_qty < 0)
		BEGIN
			INSERT INTO [APCSProDWH].[dbo].[ukebarai_errors]
				( [lot_no]
				, [process_no]
				, [date]
				, [time]
				, [good_qty]
				, [ng_qty]
				, [shipment_qty]
				, [mc_name] )
			VALUES
				( @Lotno
				, @process_no
				, @date
				, @time
				, @good_qty
				, @ng_qty
				, @shipment_qty
				, HOST_NAME() );
		END
		ELSE 
		BEGIN
			INSERT INTO [APCSProDWH].[dbo].[ukebarais]
				( [lot_no]
				, [process_no]
				, [date]
				, [time]
				, [good_qty]
				, [ng_qty]
				, [shipment_qty]
				, [mc_name] )
			VALUES
				( @Lotno
				, @process_no
				, @date
				, @time
				, @good_qty
				, @ng_qty
				, @shipment_qty
				, HOST_NAME() );
		END
	END
END
