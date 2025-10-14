-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_hasuu_compare]
	-- Add the parameters for the stored procedure here
	--@in_stock int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	-----------------------------------------------------------------------------
	----(1) declare
	-----------------------------------------------------------------------------	
	----(1.1) declare h_stock
	--declare @table_h_stock table 
	--( 
	--	[lot_no] [varchar](10) NULL, 
	--	[pcs] [int] NOT NULL,
	--	[pdcd] [varchar](5) NULL,
	--	[qc_instruction] [char](20) NULL,
	--	[mark_no] [char](20) NULL,
	--	[user_code] [char](4) NULL,
	--	[product_control_class] [char](3) NULL,
	--	[product_class] [char](1) NULL,
	--	[production_class] [char](1) NULL,
	--	[rank_no] [char](6) NULL,
	--	[hinsyu_class] [char](1) NULL,
	--	[label_class] [char](1) NULL,
	--	[stock_class] [char](2) NULL,
	--	[in_stock] [int] NULL,
	--	[created_date] [datetime] NULL
	--)

	----(1.2) declare surpluses
	--declare @table_surpluses table 
	--(
	--	[lot_id] [int] NOT NULL,
	--	[pcs] [int] NOT NULL,
	--	[serial_no] [varchar](20) NULL,
	--	[in_stock] [tinyint] NOT NULL,
	--	[location_id] [int] NULL,
	--	[acc_location_id] [int] NULL,
	--	[created_at] [datetime] NULL,
	--	[created_by] [int] NULL,
	--	[updated_at] [datetime] NULL,
	--	[updated_by] [int] NULL,
	--	[reprint_count] [smallint] NULL,
	--	[pdcd] [varchar](5) NULL,
	--	[qc_instruction] [char](20) NULL,
	--	[mark_no] [char](20) NULL,
	--	[original_lot_id] [int] NULL,
	--	[machine_id] [int] NULL,
	--	[user_code] [char](4) NULL,
	--	[product_control_class] [char](3) NULL,
	--	[product_class] [char](1) NULL,
	--	[production_class] [char](1) NULL,
	--	[rank_no] [char](6) NULL,
	--	[hinsyu_class] [char](1) NULL,
	--	[label_class] [char](1) NULL,
	--	[stock_class] [char](2) NULL
	--)
	-----------------------------------------------------------------------------
	----(2) insert to @table
	-----------------------------------------------------------------------------	
	----(2.1) insert to @table_h_stock
	--insert into @table_h_stock
	--select [LotNo]
	--	, [HASU_Stock_QTY]
	--	, [PDCD]
	--	, [Tomson_Mark_3]
	--	, [MNo]
	--	, [User_Code]
	--	, [Product_Control_Clas]
	--	, [Product_Class]
	--	, [Production_Class]
	--	, [Rank_No]
	--	, [HINSYU_Class]
	--	, [Label_Class]
	--	, [Stock_Class] 
	--	, [DMY_OUT_Flag]
	--	, [Timestamp_Date]
	--from [ISDB].[DBLSISHT].[dbo].[H_STOCK] 
	--where [DMY_OUT_Flag] != 1
	--	and [LotNo] like '____D____V';

	----(2.2) insert to @table_surpluses
	--insert into @table_surpluses
	--select [lots].[id] as [lot_id]
	--	, [h_stock].[pcs]
	--	, [lots].[lot_no] as [serial_no]
	--	, 2 as [in_stock]
	--	, NULL as [location_id]
	--	, NULL as [acc_location_id]
	--	, [h_stock].[created_date] as [created_at]
	--	, 1339 as [created_by]
	--	, [h_stock].[created_date] as [updated_at]
	--	, 1339 as [updated_by]
	--	, NULL as [reprint_count]
	--	, [h_stock].[pdcd]
	--	, [h_stock].[qc_instruction]
	--	, [h_stock].[mark_no]
	--	, NULL as [original_lot_id]
	--	, NULL as [machine_id]
	--	, [h_stock].[User_Code] as [user_code]
	--	, [h_stock].[product_control_class]
	--	, [h_stock].[product_class]
	--	, [h_stock].[production_class]
	--	, [h_stock].[rank_no]
	--	, [h_stock].[hinsyu_class]
	--	, [h_stock].[label_class]
	--	, [h_stock].[stock_class]
	--from [APCSProDB].[trans].[lots]
	--inner join @table_h_stock as [h_stock] on [lots].[lot_no] = [h_stock].[lot_no]
	--left join [APCSProDB].[trans].[surpluses] on [lots].[id] = [surpluses].[lot_id]
	--where [surpluses].[serial_no] is null
	--	and [lots].[wip_state] != 200;
	-----------------------------------------------------------------------------
	----(3) insert to surpluses,surpluse_records
	-----------------------------------------------------------------------------	
	--if exists (select lot_id from @table_surpluses)
	--begin
	--	--(3.1) insert to surpluses
	--	declare @r_surpluses int = 0;

	--	insert into [APCSProDB].[trans].[surpluses]
	--		( [id]
	--		, [lot_id]
	--		, [pcs]
	--		, [serial_no]
	--		, [in_stock] 
	--		, [location_id]
	--		, [acc_location_id]
	--		, [created_at]
	--		, [created_by]
	--		, [updated_at]
	--		, [updated_by]
	--		, [reprint_count] 
	--		, [pdcd]
	--		, [qc_instruction]
	--		, [mark_no]
	--		, [original_lot_id]
	--		, [machine_id]
	--		, [user_code]
	--		, [product_control_class]
	--		, [product_class]
	--		, [production_class]
	--		, [rank_no]
	--		, [hinsyu_class]
	--		, [label_class]
	--		, [stock_class] )
	--	select [nu].[id] + row_number() over (order by (select 0)) as [id]
	--		, [lot_id]
	--		, [pcs]
	--		, [serial_no]
	--		, [in_stock] 
	--		, [location_id]
	--		, [acc_location_id]
	--		, [created_at]
	--		, [created_by]
	--		, [updated_at]
	--		, [updated_by]
	--		, [reprint_count] 
	--		, [pdcd]
	--		, [qc_instruction]
	--		, [mark_no]
	--		, [original_lot_id]
	--		, [machine_id]
	--		, [user_code]
	--		, [product_control_class]
	--		, [product_class]
	--		, [production_class]
	--		, [rank_no]
	--		, [hinsyu_class]
	--		, [label_class]
	--		, [stock_class]
	--	from @table_surpluses as surpluses
	--	inner join [APCSProDB].[trans].[numbers] as nu on [nu].[name] = 'surpluses.id';

	--	set @r_surpluses = @@ROWCOUNT;
	--	if (@r_surpluses != 0)
	--	begin
	--		update [APCSProDB].[trans].[numbers]
	--		set [id] = [id] + @r_surpluses
	--		where [name] = 'surpluses.id';
	--	end

	--	--(3.2) insert to surpluse_records
	--	insert into [APCSProDB].[trans].[surpluse_records]
	--		( [recorded_at]
	--		, [operated_by]
	--		, [record_class]
	--		, [surpluse_id]
	--		, [lot_id]
	--		, [pcs]
	--		, [serial_no]
	--		, [in_stock]
	--		, [location_id]
	--		, [acc_location_id]
	--		, [reprint_count]
	--		, [created_at]
	--		, [created_by]
	--		, [updated_at]
	--		, [updated_by]
	--		, [product_code]
	--		, [qc_instruction]
	--		, [mark_no]
	--		, [original_lot_id]
	--		, [machine_id]
	--		, [user_code]
	--		, [product_control_class]
	--		, [product_class]
	--		, [production_class]
	--		, [rank_no]
	--		, [hinsyu_class]
	--		, [label_class]
	--		, [transfer_flag]
	--		, [transfer_pcs]
	--		, [stock_class]
	--		, [is_ability] )
	--	select GETDATE() AS [recorded_at]
	--		, 1339 AS [operated_by]
	--		, 1 AS [record_class]
	--		, [surpluses].[id] AS [surpluse_id]
	--		, [surpluses].[lot_id]
	--		, [surpluses].[pcs]
	--		, [surpluses].[serial_no]
	--		, [surpluses].[in_stock]
	--		, [surpluses].[location_id]
	--		, [surpluses].[acc_location_id]
	--		, [surpluses].[reprint_count]
	--		, [surpluses].[created_at]
	--		, [surpluses].[created_by]
	--		, GETDATE() AS [updated_at]
	--		, 1339 AS [updated_by]
	--		, [surpluses].[pdcd] AS  [product_code]
	--		, [surpluses].[qc_instruction]
	--		, [surpluses].[mark_no]
	--		, [surpluses].[original_lot_id]
	--		, [surpluses].[machine_id]
	--		, [surpluses].[user_code]
	--		, [surpluses].[product_control_class]
	--		, [surpluses].[product_class]
	--		, [surpluses].[production_class]
	--		, [surpluses].[rank_no]
	--		, [surpluses].[hinsyu_class]
	--		, [surpluses].[label_class]
	--		, [surpluses].[transfer_flag]
	--		, [surpluses].[transfer_pcs]
	--		, [surpluses].[stock_class]
	--		, [surpluses].[is_ability]
	--	from [APCSProDB].[trans].[surpluses]
	--	inner join @table_surpluses as [table_surpluses] on [surpluses].[lot_id] = [table_surpluses].[lot_id];
	--end

	-----------------------------------------------------------------------------
	----(4) insert to PROCESS_RECALL_IF
	-----------------------------------------------------------------------------	
	--insert into [APCSProDWH].[dbo].[PROCESS_RECALL_IF]
	--select [PROCESS_RECALL].* 
	--from [APCSProDB].[trans].[lots]
	--inner join [ISDB].[DBLSISHT].[dbo].[PROCESS_RECALL] 
	--	on [lots].[lot_no] COLLATE SQL_Latin1_General_CP1_CI_AS = [PROCESS_RECALL].[NEWLOT] COLLATE SQL_Latin1_General_CP1_CI_AS
	--left join [APCSProDWH].[dbo].[PROCESS_RECALL_IF] 
	--	on [lots].[lot_no] = [PROCESS_RECALL_IF].[NEWLOT] 
	--where [lots].[wip_state] = 20
	--	and [lots].[lot_no] like '____D____V'
	--	and [PROCESS_RECALL_IF].[NEWLOT] IS NULL;
	-----------------------------------------------------------------------------------------------
	DECLARE @cursor_lot_no VARCHAR(10)

	DECLARE @table_lot_recall TABLE ( 
		[lot_no] [varchar](10) NULL 
	)

	---- check lot_no
	INSERT INTO @table_lot_recall
	SELECT [lots].[lot_no]
	FROM [APCSProDB].[trans].[lots]
	INNER JOIN (
		SELECT [H_STOCK].[LotNo] AS [lot_no]
		FROM [ISDB].[DBLSISHT].[dbo].[H_STOCK]
		INNER JOIN [ISDB].[DBLSISHT].[dbo].[PROCESS_RECALL] 
			ON [H_STOCK].[LotNo] = [PROCESS_RECALL].[NEWLOT]
		WHERE [H_STOCK].[DMY_OUT_Flag] != 1
			AND [H_STOCK].[LotNo] LIKE '____D____V'
			AND SUBSTRING([H_STOCK].[LotNo],1,2) = FORMAT(GETDATE(), 'yy')
	) AS [h_stock] 
		ON [lots].[lot_no] COLLATE SQL_Latin1_General_CP1_CI_AS = [h_stock].[lot_no] COLLATE SQL_Latin1_General_CP1_CI_AS
	LEFT JOIN [APCSProDB].[trans].[surpluses] 
		ON [lots].[id] = [surpluses].[lot_id]
	LEFT JOIN [APCSProDWH].[dbo].[PROCESS_RECALL_IF] 
		ON [lots].[lot_no] = [PROCESS_RECALL_IF].[NEWLOT]
	WHERE [surpluses].[serial_no] IS NULL
	    AND [PROCESS_RECALL_IF].[NEWLOT] IS NULL
		AND [lots].[wip_state] NOT IN (200,210);

	IF EXISTS ( SELECT TOP 1 [lot_no] FROM @table_lot_recall )
	BEGIN
		---- Cursor Table
		DECLARE cursor_lot_recall CURSOR FOR 
		SELECT [lot_no] FROM @table_lot_recall;
		---- Open cursor
		OPEN cursor_lot_recall
		FETCH NEXT FROM cursor_lot_recall
		INTO @cursor_lot_no 
		---- Loop cursor
		WHILE (@@FETCH_STATUS = 0) ---- @@FETCH_STATUS -1 End, 0 Loop 
		BEGIN 
			---- # MIX_HIST
			IF NOT EXISTS (SELECT TOP 1 [HASUU_LotNo] FROM [APCSProDWH].[dbo].[MIX_HIST_IF] WHERE [HASUU_LotNo] = @cursor_lot_no)
			BEGIN
				INSERT INTO [APCSProDWH].[dbo].[MIX_HIST_IF]
				SELECT * FROM [ISDB].[DBLSISHT].[dbo].[MIX_HIST] WHERE [HASUU_LotNo] = @cursor_lot_no; 
			END
			---- # LSI_SHIP
			IF NOT EXISTS (SELECT TOP 1 [LotNo] FROM [APCSProDWH].[dbo].[LSI_SHIP_IF] WHERE [LotNo] = @cursor_lot_no)
			BEGIN
				INSERT INTO [APCSProDWH].[dbo].[LSI_SHIP_IF]
				SELECT * FROM [ISDB].[DBLSISHT].[dbo].[LSI_SHIP] WHERE [LotNo] = @cursor_lot_no; 
			END
			---- # H_STOCK
			IF NOT EXISTS (SELECT TOP 1 [LotNo] FROM [APCSProDWH].[dbo].[H_STOCK_IF] WHERE [LotNo] = @cursor_lot_no)
			BEGIN
				INSERT INTO [APCSProDWH].[dbo].[H_STOCK_IF]
				SELECT * FROM [ISDB].[DBLSISHT].[dbo].[H_STOCK] WHERE [LotNo] = @cursor_lot_no;
			END
			---- # PROCESS_RECALL
			IF NOT EXISTS (SELECT TOP 1 [NEWLOT] FROM [APCSProDWH].[dbo].[PROCESS_RECALL_IF] WHERE [NEWLOT] = @cursor_lot_no)
			BEGIN
				INSERT INTO [APCSProDWH].[dbo].[PROCESS_RECALL_IF]
				SELECT * FROM [ISDB].[DBLSISHT].[dbo].[PROCESS_RECALL] WHERE [NEWLOT] = @cursor_lot_no;
			END
			---- Next cursor
			FETCH NEXT FROM cursor_lot_recall ---- Fetch next cursor
			INTO @cursor_lot_no;  ---- Next into variable
		END
		---- Close cursor
		CLOSE cursor_lot_recall; 
		DEALLOCATE cursor_lot_recall; 
	END
END
