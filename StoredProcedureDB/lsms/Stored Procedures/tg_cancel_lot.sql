
CREATE PROCEDURE [lsms].[tg_cancel_lot]
	-- Add the parameters for the stored procedure here
	  @master_lot VARCHAR(10)
	, @emp_id INT = NULL
	, @function_type INT --#1 : Get Data Hasuu(faction), 2: Update Data, 3 : Get Master lot
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @lot_id int = 0

	SELECT @lot_id = id 
	FROM [APCSProDB].[trans].[lot_informations] 
	WHERE [lot_no] = @master_lot


	IF (@function_type = 1)
	BEGIN
		SELECT [lot_info].[id]
			, [lot_info].[lot_no]
			, [lot_cb].[member_lot_id]
			, [surpluses].[serial_no]
			, [lot_info].[type_name]
			, [lot_info].[tr_no]
			, [lot_info].[hfe_rank]
			, [lot_info].[qty_pass] AS [qty]
			, [lot_info].[pack_unit_qty] AS [qty_standard]
			--, ([lot_info].[qty_pass]/[lot_info].[pack_unit_qty]) * [lot_info].[pack_unit_qty] AS [qty_shipment]
			, [lot_info].[output_qty] AS [qty_shipment]
			--, ([lot_info].[qty_pass] - (([lot_info].[qty_pass]/[lot_info].[pack_unit_qty]) * [lot_info].[pack_unit_qty])) AS [qty_surpluses]
			, ISNULL([surpluses].[surpluses_qty],0) AS [qty_surpluses]
			, [surpluses].[pcs] AS [qty_faction]
		FROM [APCSProDB].[trans].[lot_informations] AS [lot_info]
		RIGHT JOIN [APCSProDB].[trans].[lot_combine] AS [lot_cb] ON [lot_info].[id] = [lot_cb].[lot_id]
		LEFT JOIN [APCSProDB].[trans].[surpluses] ON [lot_cb].[member_lot_id] = [surpluses].[lot_id]
		WHERE [lot_info].[lot_no] = @master_lot
	END
	ELSE IF (@function_type = 2)
	BEGIN
		------------------------------------------------------------------------------------
		--- Start Date modify : 2025/01/08 Time : 22.14 ---
		------------------------------------------------------------------------------------
		DECLARE @count_lot_combine INT;
		DECLARE @check_count_lot_tg0 INT;

		--Check if there is data lot in lot_combine table.
		SET @count_lot_combine = ( 
			SELECT COUNT([lot_combine].[lot_id])
			FROM [APCSProDB].[trans].[lot_combine]
			WHERE [lot_combine].[lot_id] = @lot_id
			GROUP BY [lot_combine].[lot_id]
		);

		--Check data is Tg-0 yes or no ?.
		SET @check_count_lot_tg0 = ( 
			SELECT COUNT([lot_combine].[lot_id])
			FROM [APCSProDB].[trans].[lot_combine]
			WHERE [lot_combine].[lot_id] = @lot_id
				AND [lot_combine].[lot_id] != [lot_combine].[member_lot_id]
			GROUP BY [lot_combine].[lot_id]
		);

		IF ( @count_lot_combine > 0 )
		BEGIN
			IF ( @check_count_lot_tg0 = 0 AND @count_lot_combine = 1 )
			BEGIN
				--- TG-0
				DELETE FROM [APCSProDB].[trans].[lot_combine] WHERE [lot_id] = @lot_id;
				DELETE FROM [APCSProDB].[trans].[surpluses] WHERE [lot_id] = @lot_id;
			END
			ELSE
			BEGIN
				--- TG + Hasuu
				UPDATE [surpluses]
				SET [surpluses].[in_stock] = 2
					, [surpluses].[updated_at] = GETDATE()
					, [surpluses].[updated_by] = @emp_id
				FROM [APCSProDB].[trans].[surpluses] 
				INNER JOIN [APCSProDB].[trans].[lot_combine] ON [surpluses].[lot_id] = [lot_combine].[member_lot_id]
				WHERE [lot_combine].[lot_id] = @lot_id
				AND [lot_combine].[lot_id] != [lot_combine].[member_lot_id]; 
				
				DELETE FROM [APCSProDB].[trans].[lot_combine] WHERE [lot_id] = @lot_id;
				DELETE FROM [APCSProDB].[trans].[surpluses] WHERE [lot_id] = @lot_id;
			END

			SELECT 'TRUE' AS [Is_Pass] 
				, N'Cancel TG data is success' AS [Error_Message_ENG]
				, N'ลบข้อมูลสำเร็จ' AS [Error_Message_THA] 
				, '' AS [Handling];
			RETURN;
		END
		ELSE
		BEGIN
			--- @count_lot_combine = 0
			SELECT 'FALSE' AS [Is_Pass] 
				, N'TG Data not found' AS [Error_Message_ENG]
				, N'ไม่พบข้อมูลการทำ TG' AS [Error_Message_THA] 
				, '' AS [Handling];
			RETURN;
		END
		------------------------------------------------------------------------------------
		--- End Date modify : 2025/01/08 Time : 22.14 ---
		------------------------------------------------------------------------------------
	END
	ELSE IF (@function_type = 3) --#Add fuction get master lot 2025/04/08 Time : 10.53 by Aomsin
	BEGIN
		SELECT [lot_info].[id]
			, [lot_info].[lot_no]
			, [lot_info].[type_name]
			, [lot_info].[tr_no]
			, [lot_info].[hfe_rank]
			, [lot_info].[qty_pass] AS [qty]
			, [lot_info].[pack_unit_qty] AS [qty_standard]
			, [lot_info].[output_qty] AS [qty_shipment]
			, ISNULL([surpluses].[surpluses_qty],0) AS [qty_surpluses]
			, [surpluses].[pcs] AS [qty_faction]
		FROM [APCSProDB].[trans].[lot_informations] AS [lot_info]
		LEFT JOIN [APCSProDB].[trans].[surpluses] ON [lot_info].[id] = [surpluses].[lot_id]
		WHERE [lot_info].[lot_no] = @master_lot
	END
END
