-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_hasuu_compare_bk001]
	-- Add the parameters for the stored procedure here
	--@in_stock int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here

	BEGIN TRY 
		--INSERT [surpluses]
		DECLARE @r INT = 0;
		INSERT INTO [APCSProDB].[trans].[surpluses]([id]
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
			, [stock_class])
		SELECT [nu].[id] + row_number() over (order by [lots].[id]) as [id]
			, [lots].[id] as [lot_id]
			, [H_STOCK].[HASU_Stock_QTY] as [pcs]
			, [lots].[lot_no] as [serial_no]
			, 2 as [in_stock]
			, NULL as [location_id]
			, NULL as [acc_location_id]
			, GETDATE() as [created_at]
			, 1339 as [created_by]
			, GETDATE() as [updated_at]
			, 1339 as [updated_by]
			, NULL as [reprint_count]
			, [H_STOCK].[PDCD] as [pdcd]
			, [H_STOCK].[Tomson_Mark_3] as [qc_instruction]
			, [H_STOCK].[MNo] as [mark_no]
			, NULL as [original_lot_id]
			, NULL as [machine_id]
			, [H_STOCK].[User_Code] as [user_code]
			, [H_STOCK].[Product_Control_Clas] as [product_control_class]
			, [H_STOCK].[Product_Class] as [product_class]
			, [H_STOCK].[Production_Class] as [production_class]
			, [H_STOCK].[Rank_No] as [rank_no]
			, [H_STOCK].[HINSYU_Class] as [hinsyu_class]
			, [H_STOCK].[Label_Class] as [label_class]
			, [H_STOCK].[Stock_Class] as [stock_class]
		FROM [APCSProDB].[trans].[lots]
		INNER JOIN [APCSProDB].[trans].[numbers] AS nu ON [nu].[name] = 'surpluses.id'
		LEFT JOIN [APCSProDB].[trans].[surpluses] on [lots].[id] = [surpluses].[lot_id]
		LEFT JOIN (SELECT *
			FROM OPENROWSET('SQLNCLI', 'Server= 10.28.1.144;Database=DBLSISHT;Uid=ship;Pwd=ship', 
							'SELECT * FROM [DBLSISHT].[dbo].[H_STOCK] WHERE DMY_OUT_Flag != 1')
		) as [H_STOCK] on [lots].[lot_no] = [H_STOCK].[LotNo]

		WHERE [H_STOCK].[LotNo] is not null
			AND [surpluses].[serial_no] is null;
			--AND [H_STOCK].[DMY_OUT_Flag] != 1;
			--AND [H_STOCK].[HASU_Stock_QTY] > 0)

		SET @r = @@ROWCOUNT
		UPDATE [APCSProDB].[trans].[numbers]
		SET [id] = [id] + @r
		WHERE [name] = 'surpluses.id';
		--INSERT [surpluses]

		-- Update check flag before update to mli02_lsi(IS)
		update [APCSProDB].[trans].[surpluses]
		set [surpluses].[pdcd] = [H_STOCK].[PDCD]
			, [surpluses].[qc_instruction] = [H_STOCK].[Tomson_Mark_3]
			, [surpluses].[mark_no] = [H_STOCK].[MNo]
			, [surpluses].[user_code] = [H_STOCK].[User_Code]
			, [surpluses].[product_control_class] = [H_STOCK].[Product_Control_Clas]
			, [surpluses].[product_class] = [H_STOCK].[Product_Class]
			, [surpluses].[production_class] = [H_STOCK].[Production_Class]
			, [surpluses].[rank_no] = [H_STOCK].[Rank_No]
			, [surpluses].[hinsyu_class] = [H_STOCK].[HINSYU_Class]
			, [surpluses].[label_class] = [H_STOCK].[Label_Class]
			, [surpluses].[stock_class] = [H_STOCK].[Stock_Class]
		from [APCSProDB].[trans].[surpluses]
		inner join (SELECT *
			FROM OPENROWSET('SQLNCLI', 'Server= 10.28.1.144;Database=DBLSISHT;Uid=ship;Pwd=ship', 
							'SELECT * FROM [DBLSISHT].[dbo].[H_STOCK]')
		) as [H_STOCK] on [surpluses].[serial_no] = [H_STOCK].[LotNo]
		--where [surpluses].in_stock = @in_stock
		--where [surpluses].in_stock = 2
		--	and ([surpluses].pdcd is null or [surpluses].qc_instruction is null or [surpluses].mark_no is null)
		where ([surpluses].pdcd is null or [surpluses].qc_instruction is null or [surpluses].mark_no is null);
	END TRY  
	BEGIN CATCH  
		SELECT  
			ERROR_NUMBER() AS ErrorNumber  
			,ERROR_SEVERITY() AS ErrorSeverity  
			,ERROR_STATE() AS ErrorState  
			,ERROR_PROCEDURE() AS ErrorProcedure  
			,ERROR_MESSAGE() AS ErrorMessage;  
	END CATCH;  
END
