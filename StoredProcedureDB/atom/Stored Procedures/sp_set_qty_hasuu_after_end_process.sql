-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_qty_hasuu_after_end_process]
	-- Add the parameters for the stored procedure here
	 @lot_id INT,
	 @qty INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	--	( [record_at]
	--	, [record_class]
	--	, [login_name]
	--	, [hostname]
	--	, [appname]
	--	, [command_text]
	--	, [lot_no] )
	--SELECT GETDATE()
	--	, '4'
	--	, ORIGINAL_LOGIN()
	--	, HOST_NAME()
	--	, APP_NAME()
	--	, 'EXEC [atom].[sp_set_qty_hasuu_after_end_process] @lot_id = ' + CAST(@lot_id AS VARCHAR(20)) 
	--		+ ', @qty = ' + CAST(@qty AS VARCHAR(20)) 
	--	, (SELECT [lot_no] FROM [APCSProDB].[trans].[lots] WHERE [id] = @lot_id);

	DECLARE @pc_code INT = 0
		, @lot_no VARCHAR(10)
		, @type_lot VARCHAR(1)
		, @qty_total INT
		, @qty_hasuu INT
		, @qty_out INT

	SELECT @lot_no = [lots].[lot_no]
		, @pc_code = IIF( [lots].[pc_instruction_code] IS NULL OR [lots].[pc_instruction_code] = '', 0, [lots].[pc_instruction_code] )
		, @type_lot = SUBSTRING([lots].[lot_no], 5, 1)
		, @qty_total = (@qty + ISNULL([lots].[qty_combined], 0))
		, @qty_out = ([device_names].[pcs_per_pack] * (@qty_total / [device_names].[pcs_per_pack]))
		, @qty_hasuu = (@qty_total % [device_names].[pcs_per_pack])
	FROM [APCSProDB].[trans].[lots]
	INNER JOIN [APCSProDB].[method].[device_names] ON [device_names].[id] = [lots].[act_device_name_id]
	WHERE [lots].[id] = @lot_id;

	IF (@pc_code = 13)
	BEGIN
		---- 13
		IF (@type_lot != 'D')
		BEGIN
			PRINT 'update qty_out';
			SELECT @qty_out AS [qty_out]
			FROM [APCSProDB].[trans].[lots] 
			WHERE [id] = @lot_id;
			----UPDATE [APCSProDB].[trans].[lots] 
			----SET [qty_out] = [qty_out]
			----WHERE [id] = @lot_id;
		END
		ELSE 
		BEGIN
			PRINT 'update qty_hasuu,qty_out';
			SELECT @qty_out AS [qty_out]
				, @qty_hasuu AS [qty_hasuu]
				, [lots].[qty_out] - @qty
			FROM [APCSProDB].[trans].[lots] 
			WHERE [id] = @lot_id;
			----UPDATE [APCSProDB].[trans].[lots] 
			----SET [qty_out] = [qty_out]
			----	, [qty_hasuu] = [qty_hasuu]
			----WHERE [id] = @lot_id;
		END
	END
	ELSE 
	BEGIN
		---- != 13 
		IF (@pc_code = 11)
		BEGIN
			---- 11
			PRINT 'update qty_out or qty_hasuu on tran.lots table and pcs on surpluses and label issue_record';
			SELECT @qty_out AS [qty_out]
				, @qty_hasuu AS [qty_hasuu]
			FROM [APCSProDB].[trans].[lots] 
			WHERE [id] = @lot_id;
			--UPDATE [APCSProDB].[trans].[lots]
			--SET [qty_out] = @qty_out
			--	, [qty_hasuu] = @qty_hasuu
			--WHERE [id] = @lot_id;


			SELECT @qty_hasuu AS [pcs]
				, [updated_at]
				, [updated_by]
			FROM [APCSProDB].[trans].[surpluses]
			WHERE [lot_id] = @lot_id;
			--UPDATE [APCSProDB].[trans].[surpluses]
			--SET [pcs] = @qty_hasuu
			--	, [updated_at] = GETDATE()
			--	, [updated_by] = '1'
			--WHERE [lot_id] = @lot_id;
		END
		ELSE 
		BEGIN
			---- NULL, 0, 1
			PRINT 'update qty_out or qty_hasuu on tran.lots table and pcs on surpluses and label issue_record';
			---- # Update qty_out, qty_hasuu on [trans].[lots]
			SELECT @qty_out AS [qty_out]
				, @qty_hasuu AS [qty_hasuu]
			FROM [APCSProDB].[trans].[lots] 
			WHERE [id] = @lot_id;
			--UPDATE [APCSProDB].[trans].[lots]
			--SET [qty_out] = @qty_out
			--	, [qty_hasuu] = @qty_hasuu
			--WHERE [id] = @lot_id;

			---- # Update pcs on [trans].[surpluses]
			SELECT @qty_hasuu AS [pcs]
				, [updated_at]
				, [updated_by]
			FROM [APCSProDB].[trans].[surpluses]
			WHERE [lot_id] = @lot_id;
			--UPDATE [APCSProDB].[trans].[surpluses]
			--SET [pcs] = @qty_hasuu
			--	, [updated_at] = GETDATE()
			--	, [updated_by] = '1'
			--WHERE [lot_id] = @lot_id;
		END

		---- # Update qty on label
		--BEGIN TRY
		--	EXEC [dbo].[tg_sp_set_qty_fristlot_update_ver2] @lot_no = @lot_no
		--		, @qty = @qty_total
		--		, @is_inspec_value = 0
		--END TRY
		--BEGIN CATCH  
		--	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		--		( [record_at]
		--		, [record_class]
		--		, [login_name]
		--		, [hostname]
		--		, [appname]
		--		, [command_text]
		--		, [lot_no] )
		--	SELECT GETDATE()
		--		, '4'
		--		, ORIGINAL_LOGIN()
		--		, HOST_NAME()
		--		, APP_NAME()
		--		, 'EXEC [atom].[sp_set_qty_hasuu_after_end_process] @lot_id = ' + CAST(@lot_id AS VARCHAR(20)) 
		--			+ ', @qty = ' + CAST(@qty AS VARCHAR(20)) 
		--			+ N' RETURN : FALSE, MESSAGE :ไม่สามารถ Update ข้อมูล จำนวนงาน ใน Tran.Label_Issue_Record ได้'
		--		, (SELECT [lot_no] FROM [APCSProDB].[trans].[lots] WHERE [id] = @lot_id);
		--	RETURN;
		--END CATCH  
	END
END
