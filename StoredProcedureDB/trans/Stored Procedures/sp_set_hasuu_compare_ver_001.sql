-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_hasuu_compare_ver_001]
	-- Add the parameters for the stored procedure here
	--@in_stock int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	begin transaction;
	begin try
		---------------------------------------------------------------------------
		--(1) Declare
		---------------------------------------------------------------------------	
		declare @table_h_stock table 
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
			)
		declare @r int = 0;
		---------------------------------------------------------------------------
		--(2) insert h_stock to @table_h_stock
		---------------------------------------------------------------------------	
		insert into @table_h_stock
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
		select [H_STOCK].[LotNo] as [lot_no]
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
		from (
			select *
			from openrowset ('SQLNCLI', 'Server= 10.28.1.144;Database=DBLSISHT;Uid=ship;Pwd=ship', 
				'SELECT [H_STOCK].[LotNo]
					, [H_STOCK].[HASU_Stock_QTY]
					, [H_STOCK].[PDCD]
					, [H_STOCK].[Tomson_Mark_3]
					, [H_STOCK].[MNo]
					, [H_STOCK].[User_Code]
					, [H_STOCK].[Product_Control_Clas]
					, [H_STOCK].[Product_Class]
					, [H_STOCK].[Production_Class]
					, [H_STOCK].[Rank_No]
					, [H_STOCK].[HINSYU_Class]
					, [H_STOCK].[Label_Class]
					, [H_STOCK].[Stock_Class] 
					, [H_STOCK].[DMY_OUT_Flag]
					, [H_STOCK].[Timestamp_Date]
				FROM [DBLSISHT].[dbo].[H_STOCK] WHERE [H_STOCK].[DMY_OUT_Flag] != 1')
		) as [H_STOCK]
		---------------------------------------------------------------------------
		--(3) insert from h_stock with out surpluses
		---------------------------------------------------------------------------	
		insert into [APCSProDB].[trans].[surpluses]
		(
			[id]
			, [lot_id]
			, [pcs]
			, [serial_no]
			, [in_stock]
			, [location_id]
			, [acc_location_id]
			, [created_at]
			, [created_by]
			, [updated_at]
			, [updated_by]
			, [reprint_count]
			, [pdcd]
			, [qc_instruction]
			, [mark_no]
			, [original_lot_id]
			, [machine_id]
			, [user_code]
			, [product_control_class]
			, [product_class]
			, [production_class]
			, [rank_no]
			, [hinsyu_class]
			, [label_class]
			, [stock_class]
		)
		select [nu].[id] + row_number() over (order by [lots].[id]) as [id]
			, [lots].[id] as [lot_id]
			, [h_stock].[pcs]
			, [lots].[lot_no] as [serial_no]
			, 2 as [in_stock]
			, NULL as [location_id]
			, NULL as [acc_location_id]
			--, GETDATE() as [created_at]
			, [h_stock].[created_date] as [created_at]
			, 1339 as [created_by]
			--, GETDATE() as [updated_at]
			, [h_stock].[created_date] as [updated_at]
			, 1339 as [updated_by]
			, NULL as [reprint_count]
			, [h_stock].[pdcd]
			, [h_stock].[qc_instruction]
			, [h_stock].[mark_no]
			, NULL as [original_lot_id]
			, NULL as [machine_id]
			, [h_stock].[User_Code] as [user_code]
			, [h_stock].[product_control_class]
			, [h_stock].[product_class]
			, [h_stock].[production_class]
			, [h_stock].[rank_no]
			, [h_stock].[hinsyu_class]
			, [h_stock].[label_class]
			, [h_stock].[stock_class]
		from [APCSProDB].[trans].[lots]
		inner join [APCSProDB].[trans].[numbers] as nu on [nu].[name] = 'surpluses.id'
		left join [APCSProDB].[trans].[surpluses] on [lots].[id] = [surpluses].[lot_id]
		left join @table_h_stock as [h_stock] on [lots].[lot_no] = [h_stock].[lot_no]
		where [h_stock].[lot_no] is not null
			and [surpluses].[serial_no] is null
			and substring([h_stock].[lot_no],5,1) = 'D'
			and [lots].[wip_state] <> 200;
		---------------------------------------------------------------------------
		--(4) update numbers surpluses.id
		---------------------------------------------------------------------------	
		set @r = @@ROWCOUNT;
		if (@r != 0)
		begin
			UPDATE [APCSProDB].[trans].[numbers]
			SET [id] = [id] + @r
			WHERE [name] = 'surpluses.id';
		end
		---------------------------------------------------------------------------
		--(5) commit
		---------------------------------------------------------------------------	
		commit transaction;
	end try
	begin catch
		rollback transaction;
	end catch;

END
