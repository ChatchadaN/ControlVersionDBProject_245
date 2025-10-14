-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_hasuu_compare_manual]
	-- Add the parameters for the stored procedure here
	@lot_no VARCHAR(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here

	DECLARE @table_h_stock TABLE 
	( 
		[lot_no] [varchar](10) NULL, 
		[pcs] [int] NOT NULL,
		[pdcd] [varchar](5) NULL,
		[qc_instruction] [char](20) NULL,
		[mark_no] [char](20) NULL,
		[user_code] [char](4) NULL,
		[product_control_class] [char](3) NULL,
		[product_class] [char](1) NULL,
		[production_class] [char](1) NULL,
		[rank_no] [char](6) NULL,
		[hinsyu_class] [char](1) NULL,
		[label_class] [char](1) NULL,
		[stock_class] [char](2) NULL,
		[in_stock] [int] NULL,
		[created_date] [datetime] NULL
	);

	INSERT INTO @table_h_stock
	(
		[lot_no]
		, [pcs]
		, [pdcd]
		, [qc_instruction]
		, [mark_no]
		, [user_code]
		, [product_control_class]
		, [product_class]
		, [production_class]
		, [rank_no]
		, [hinsyu_class]
		, [label_class]
		, [stock_class]
		, [in_stock]
		, [created_date]
	)
	SELECT [H_STOCK].[LotNo] as [lot_no]
		, [H_STOCK].[HASU_Stock_QTY] as [pcs]
		, [H_STOCK].[PDCD] as [pdcd]
		, [H_STOCK].[Tomson_Mark_3] as [qc_instruction]
		, [H_STOCK].[MNo] as [mark_no]
		, [H_STOCK].[User_Code] as [user_code]
		, [H_STOCK].[Product_Control_Clas] as [product_control_class]
		, [H_STOCK].[Product_Class] as [product_class]
		, [H_STOCK].[Production_Class] as [production_class]
		, [H_STOCK].[Rank_No] as [rank_no]
		, [H_STOCK].[HINSYU_Class] as [hinsyu_class]
		, [H_STOCK].[Label_Class] as [label_class]
		, [H_STOCK].[Stock_Class] as [stock_class]
		, [H_STOCK].[DMY_OUT_Flag] as [in_stock]
		, [H_STOCK].[Timestamp_Date] as [created_date]
	FROM [ISDB].[DBLSISHT].[dbo].[H_STOCK] 
	WHERE [H_STOCK].[LotNo] = @lot_no;


	UPDATE [APCSProDB].[trans].[surpluses]
	SET [surpluses].[pdcd] = [H_STOCK].[pdcd]
		, [surpluses].[qc_instruction] = [H_STOCK].[qc_instruction]
		, [surpluses].[mark_no] = [H_STOCK].[mark_no]
		, [surpluses].[user_code] = [H_STOCK].[user_code]
		, [surpluses].[product_control_class] = [H_STOCK].[product_control_class]
		, [surpluses].[product_class] = [H_STOCK].[product_class]
		, [surpluses].[production_class] = [H_STOCK].[production_class]
		, [surpluses].[rank_no] = [H_STOCK].[rank_no]
		, [surpluses].[hinsyu_class] = [H_STOCK].[hinsyu_class]
		, [surpluses].[label_class] = [H_STOCK].[label_class]
		, [surpluses].[stock_class] = [H_STOCK].[stock_class]
	FROM [APCSProDB].[trans].[surpluses]
	INNER JOIN @table_h_stock as [H_STOCK] on [surpluses].[serial_no] = [H_STOCK].[lot_no]
	WHERE [surpluses].[serial_no] = @lot_no;
END
