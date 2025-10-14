
CREATE PROCEDURE [lsms].[sp_get_surpluses_edit]
	-- Add the parameters for the stored procedure here
	@surpluses_lot VARCHAR(10)
	, @qty_surpluses int = 0
	, @in_stock_value tinyint = null
	, @emp_id int = null
	, @is_function int ---# 1: Show Data Edit , 2: Update pcs

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	IF (@is_function = 1)
	----------------------------------------------------------------------------
	----- # get data edit inventory
	----------------------------------------------------------------------------
	BEGIN
		SELECT [surpluses].[lot_id]
			, [surpluses].[pcs]
			, [surpluses].[serial_no] 
			, [surpluses].[in_stock] 
		FROM [APCSProDB].[trans].[surpluses] 
		WHERE [surpluses].serial_no = @surpluses_lot
	END

	ELSE IF (@is_function = 2)
	----------------------------------------------------------------------------
	----- # Update data edit inventory
	----------------------------------------------------------------------------
	BEGIN
		BEGIN TRY
			UPDATE APCSProDB.trans.surpluses
				SET pcs = @qty_surpluses  
					, in_stock = (CASE 
						WHEN @in_stock_value is null THEN [surpluses].[in_stock]
						ELSE @in_stock_value
					END)
					, updated_at = GETDATE()
					, updated_by = @emp_id
			WHERE serial_no = @surpluses_lot
		
			SELECT 'TRUE' AS [Is_pass]
				, 'Data saved successfully' AS [Error_Message_ENG]
				, '' AS [Error_Message_THA] 
				, '' AS [Handling];
			RETURN;
		END TRY

		BEGIN CATCH
			SELECT 'FALSE' AS [Is_pass]
				, 'Data not saved' AS [Error_Message_ENG]
				, '' AS [Error_Message_THA] 
				, '' AS [Handling];
			RETURN;
		END CATCH
	END
END
