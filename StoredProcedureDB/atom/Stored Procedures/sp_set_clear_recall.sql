-- =============================================
-- Author:		<Kittitat P.>
-- Create date: <2023/02/16>
-- Description:	<Create recall_lot (D lot) in trans.surpluses>
-- =============================================
CREATE PROCEDURE [atom].[sp_set_clear_recall]
	-- Add the parameters for the stored procedure here
	@lot_no VARCHAR(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	----------------------------------------------------------------------------
	----- # log exec stored procedure
	----------------------------------------------------------------------------
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	(
		[record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no]
	)
	SELECT GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, ISNULL('EXEC [atom].[sp_set_clear_recall] @lot_no = ''' + @lot_no + '''','EXEC [atom].[sp_set_clear_recall] @lot_no = NULL')
		, @lot_no;

	BEGIN TRANSACTION
	BEGIN TRY
		DECLARE @trans_lots_id INT = (SELECT [id] FROM [APCSProDB].[trans].[lots] WITH (NOLOCK) WHERE [lot_no] = @lot_no);
		----------------------------------------------------------------------------
		----- # clear trans.special_flows
		----------------------------------------------------------------------------
		PRINT '<---- special_flows ' + FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss');
		IF EXISTS(SELECT [lot_id] FROM [APCSProDB].[trans].[special_flows] WITH (NOLOCK) WHERE [lot_id] = @trans_lots_id)
		BEGIN
			DELETE FROM [APCSProDB].[trans].[special_flows] 
			WHERE [lot_id] = @trans_lots_id;
		END
		PRINT '<---- special_flows ' + FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss');
		----------------------------------------------------------------------------
		----- # clear trans.lots
		----------------------------------------------------------------------------
		PRINT '<---- lots ' + FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss');
		IF EXISTS(SELECT [id] FROM [APCSProDB].[trans].[lots] WITH (NOLOCK) WHERE [id] = @trans_lots_id)
		BEGIN
			--DELETE FROM [APCSProDB].[trans].[lots] 
			--WHERE [id] = @trans_lots_id;
			UPDATE [APCSProDB].[trans].[lots]
			SET [wip_state] = 200
				, [quality_state] = 0
				, [is_special_flow] = 0
				, [special_flow_id] = NULL
			WHERE [id] = @trans_lots_id;
		END
		PRINT '<---- lots ' + FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss');
		----------------------------------------------------------------------------
		----- # clear trans.surpluses
		----------------------------------------------------------------------------
		PRINT '<---- surpluses ' + FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss');
		IF EXISTS(SELECT [lot_id] FROM [APCSProDB].[trans].[surpluses] WITH (NOLOCK) WHERE [lot_id] = @trans_lots_id)
		BEGIN
			DELETE FROM [APCSProDB].[trans].[surpluses] 
			WHERE [lot_id] = @trans_lots_id;
		END
		PRINT '<---- surpluses ' + FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss');
		----------------------------------------------------------------------------
		----- # clear trans.surpluses_records
		----------------------------------------------------------------------------
		PRINT '<---- surpluse_records ' + FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss');
		IF EXISTS(SELECT [lot_id] FROM [APCSProDB].[trans].[surpluse_records] WITH (NOLOCK) WHERE [lot_id] = @trans_lots_id)
		BEGIN
			DELETE FROM [APCSProDB].[trans].[surpluse_records] 
			WHERE [lot_id] = @trans_lots_id;
		END
		PRINT '<---- surpluse_records ' + FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss');
		----------------------------------------------------------------------------
		----- # clear trans.lot_combine
		----------------------------------------------------------------------------
		PRINT '<---- lot_combine ' + FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss');
		IF EXISTS(SELECT [lot_id] FROM [APCSProDB].[trans].[lot_combine] WITH (NOLOCK) WHERE [lot_id] = @trans_lots_id)
		BEGIN
			DELETE FROM [APCSProDB].[trans].[lot_combine] 
			WHERE [lot_id] = @trans_lots_id;
		END
		PRINT '<---- lot_combine ' + FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss');
		----------------------------------------------------------------------------
		----- # clear trans.lot_combine_records
		----------------------------------------------------------------------------
		PRINT '<---- lot_combine_records ' + FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss');
		IF EXISTS(SELECT [lot_id] FROM [APCSProDB].[trans].[lot_combine_records] WITH (NOLOCK) WHERE [lot_id] = @trans_lots_id)
		BEGIN
			DELETE FROM [APCSProDB].[trans].[lot_combine_records] 
			WHERE [lot_id] = @trans_lots_id;
		END
		PRINT '<---- lot_combine_records ' + FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss');
		----------------------------------------------------------------------------
		----- # clear trans.label_issue_records
		----------------------------------------------------------------------------
		PRINT '<---- label_issue_records ' + FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss');
		IF EXISTS(SELECT [lot_no] FROM [APCSProDB].[trans].[label_issue_records] WITH (NOLOCK) WHERE [lot_no] = @lot_no)
		BEGIN
			DELETE FROM [APCSProDB].[trans].[label_issue_records] 
			WHERE [lot_no] = @lot_no;
		END
		PRINT '<---- label_issue_records ' + FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss');
		----------------------------------------------------------------------------
		----- # clear trans.label_issue_records_hist
		----------------------------------------------------------------------------
		--PRINT '<---- label_issue_records_hist ' + FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss');
		--IF EXISTS(SELECT [lot_no] FROM [APCSProDB].[trans].[label_issue_records_hist] WITH (NOLOCK) WHERE [lot_no] = @lot_no)
		--BEGIN
		--	DELETE FROM [APCSProDB].[trans].[label_issue_records_hist] 
		--	WHERE [lot_no] = @lot_no;
		--END
		--PRINT '<---- label_issue_records_hist ' + FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss');
		----------------------------------------------------------------------------
		----- # clear MIX_HIST
		----------------------------------------------------------------------------
		PRINT '<---- MIX_HIST ' + FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss');
		IF EXISTS(SELECT [HASUU_LotNo] FROM [APCSProDWH].[dbo].[MIX_HIST_IF] WITH (NOLOCK) WHERE [HASUU_LotNo] = @lot_no)
		BEGIN
			DELETE FROM [APCSProDWH].[dbo].[MIX_HIST_IF]
			WHERE [HASUU_LotNo] = @lot_no;
		END
		PRINT '<---- MIX_HIST ' + FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss');
		----------------------------------------------------------------------------
		----- # clear LSI_SHIP
		----------------------------------------------------------------------------
		PRINT '<---- LSI_SHIP ' + FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss');
		IF EXISTS(SELECT [LotNo] FROM [APCSProDWH].[dbo].[LSI_SHIP_IF] WITH (NOLOCK) WHERE [LotNo] = @lot_no)
		BEGIN
			DELETE FROM [APCSProDWH].[dbo].[LSI_SHIP_IF]
			WHERE [LotNo] = @lot_no;
		END
		PRINT '<---- LSI_SHIP ' + FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss');
		----------------------------------------------------------------------------
		----- # clear H_STOCK
		----------------------------------------------------------------------------
		PRINT '<---- H_STOCK ' + FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss');
		IF EXISTS(SELECT [LotNo] FROM [APCSProDWH].[dbo].[H_STOCK_IF] WITH (NOLOCK) WHERE [LotNo] = @lot_no)
		BEGIN
			DELETE FROM [APCSProDWH].[dbo].[H_STOCK_IF]
			WHERE [LotNo] = @lot_no;
		END
		PRINT '<---- H_STOCK ' + FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss');
		----------------------------------------------------------------------------
		----- # clear PROCESS_RECALL
		----------------------------------------------------------------------------
		PRINT '<---- PROCESS_RECALL ' + FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss');
		IF EXISTS(SELECT [NEWLOT] FROM [APCSProDWH].[dbo].[PROCESS_RECALL_IF] WITH (NOLOCK) WHERE [NEWLOT] = @lot_no)
		BEGIN
			DELETE FROM [APCSProDWH].[dbo].[PROCESS_RECALL_IF]
			WHERE [NEWLOT] = @lot_no;
		END
		PRINT '<---- PROCESS_RECALL ' + FORMAT(GETDATE(),'yyyy-MM-dd HH:mm:ss');
		-----------------------------------------------------------------------------
		COMMIT TRANSACTION;
		SELECT 'TRUE' AS [Is_Pass] 
			, '' AS [Error_Message_ENG]
			, N'' AS [Error_Message_THA] 
			, N'' AS [Handling];
		RETURN;
		-----------------------------------------------------------------------------
	END TRY
	BEGIN CATCH
		-----------------------------------------------------------------------------
		ROLLBACK TRANSACTION;
		SELECT 'FALSE' AS [Is_Pass] 
			, 'delete data error !!' AS [Error_Message_ENG]
			, N'ลบข้อมูลไม่สำเร็จ !!' AS [Error_Message_THA] 
			, N'กรุณาติดต่อ system' AS [Handling];
		RETURN;
		-----------------------------------------------------------------------------
	END CATCH
END
