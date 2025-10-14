-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_manual_recall_lot_data]
	-- Add the parameters for the stored procedure here
	@lot_no VARCHAR(10)
	, @qty_adjust INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- Insert statements for procedure here
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
		, ISNULL('EXEC [trans].[sp_get_manual_recall_lot_data] @lot_no = ''' + @lot_no + ''''
			+ ', @qty_adjust = ' + ISNULL(CAST(@qty_adjust AS VARCHAR), 'NULL')
			,'EXEC [trans].[sp_get_manual_recall_lot_data] @lot_no = NULL'
			+ ', @qty_adjust = ' + ISNULL(CAST(@qty_adjust AS VARCHAR), 'NULL'))
		, @lot_no;
	
	SELECT  @qty_adjust AS [qty_pass]
		, 0 AS [qty_combined]
		, IIF(@qty_adjust < [device_names].[pcs_per_pack]
			, @qty_adjust 
			, CASE 
				WHEN ( @qty_adjust / [device_names].[pcs_per_pack] ) <= 0 
				THEN @qty_adjust 
				ELSE @qty_adjust - (( @qty_adjust / [device_names].[pcs_per_pack] ) * [device_names].[pcs_per_pack] ) 
			END 
		) AS [qty_hasuu]
		, IIF(@qty_adjust < [device_names].[pcs_per_pack]
			, 0 
			, CASE 
				WHEN ( @qty_adjust / [device_names].[pcs_per_pack] ) <= 0 
				THEN @qty_adjust 
				ELSE ( @qty_adjust / [device_names].[pcs_per_pack] ) * [device_names].[pcs_per_pack] 
			END 
		) AS [qty_out]
		--, [device_names].[pcs_per_pack] 
	FROM [APCSProDB].[trans].[lots] 
	INNER JOIN [APCSProDB].[method].[device_names]
		ON [lots].[act_device_name_id] = [device_names].[id]
	WHERE [lots].[lot_no] = @lot_no;
END
