-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_set_dcwf_subtractNG] 
	-- Add the parameters for the stored procedure here
	@tmpwftb WaferLotList readonly, @ngtotal int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result SETs from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @tmpTableLotDc TABLE (Lot_No varchar(20))
	DECLARE @i int = 0, @WaferLot nvarchar(20), @OrderNo nvarchar(20)
	DECLARE @AssyLot nvarchar(20), @pass int, @fail int, @sumQty int, @in_qty int

    -- Insert statements for procedure here
	
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history] ([record_at], [record_class], [login_name], [hostname], [appname], [command_text])
	SELECT GETDATE(), '4', ORIGINAL_LOGIN(), HOST_NAME(), APP_NAME()
	,'EXEC [dbo].[sp_SET_dcwf_subtractNG] @NGTotal = ''' + CONVERT(VARCHAR, @ngtotal) + ''' '


	SELECT @i = COUNT(WaferLot) FROM @tmpwftb

	WHILE @i >0
	BEGIN
		SELECT TOP (@i) @WaferLot = waferlot, @OrderNo = orderno FROM @tmpwftb

		--SELECT @WaferLot, @OrderNo

		INSERT INTO @tmpTableLotDc SELECT LOT_NO_1
		FROM [APCSProDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT]
		WHERE   (ORDER_NO = @OrderNo) AND (PERETTO_NO_1 LIKE @WaferLot + '%') OR
				(ORDER_NO = @OrderNo) AND (PERETTO_NO_2 LIKE @WaferLot + '%') OR
				(ORDER_NO = @OrderNo) AND (PERETTO_NO_3 LIKE @WaferLot + '%') OR
				(ORDER_NO = @OrderNo) AND (PERETTO_NO_4 LIKE @WaferLot + '%') OR
				(ORDER_NO = @OrderNo) AND (PERETTO_NO_5 LIKE @WaferLot + '%') OR
				(ORDER_NO = @OrderNo) AND (PERETTO_NO_6 LIKE @WaferLot + '%') OR
				(ORDER_NO = @OrderNo) AND (PERETTO_NO_7 LIKE @WaferLot + '%') OR
				(ORDER_NO = @OrderNo) AND (PERETTO_NO_8 LIKE @WaferLot + '%') OR
				(ORDER_NO = @OrderNo) AND (PERETTO_NO_9 LIKE @WaferLot + '%') OR
				(ORDER_NO = @OrderNo) AND (PERETTO_NO_10 LIKE @WaferLot + '%') OR
				(ORDER_NO = @OrderNo) AND (PERETTO_NO_11 LIKE @WaferLot + '%') OR
				(ORDER_NO = @OrderNo) AND (PERETTO_NO_12 LIKE @WaferLot + '%')
				ORDER BY LOT_NO_1 DESC

		SET @i = @i - 1
	END

	--SELECT Lot_No, qty_in, qty_pass ,qty_fail FROM [APCSProDB].[trans].lots WHERE lot_no in (SELECT * FROM @tmpTableLotDc) 

	SELECT @i = COUNT(Lot_No) FROM [APCSProDB].[trans].lots WHERE lot_no in (SELECT * FROM @tmpTableLotDc) 
	
	SELECT @sumQty = SUM(qty_pass) FROM [APCSProDB].[trans].lots WHERE lot_no in (SELECT * FROM @tmpTableLotDc) 

	IF @sumQty < @ngtotal BEGIN  SELECT 'FALSE' AS Status, 'NG TOTAL มากกว่าจำนวนงานทั้งหมด' AS Message, 'กรุณตรวจสอบอีกครัง หรือติดต่อ System' AS Handler RETURN  END

	WHILE @i >0
	BEGIN
		SELECT TOP (@i)  @AssyLot = Lot_No  , @pass = qty_pass , @fail = qty_fail, @in_qty = qty_in FROM [APCSProDB].[trans].lots WHERE lot_no in (SELECT * FROM @tmpTableLotDc) 

		--SELECT @AssyLot

		IF @pass > 0 
		BEGIN
			IF @ngtotal > @pass
			BEGIN
				SET @ngtotal = @ngtotal - @pass
				SET @fail = @fail + @pass
				SET @pass = 0
			END
			ELSE
			BEGIN
				SET @fail = @fail + @ngtotal
				SET @pass = @pass - @ngtotal
				SET @ngtotal = 0
			END
		END

		IF @in_qty <> @pass + @fail BEGIN  SELECT 'FALSE' AS Status, 'Input Total ไม่เท่ากับจำนวน Pass + NG' AS Message, 'กรุณตรวจสอบอีกครัง หรือติดต่อ System' AS Handler RETURN     BREAK  END

		--SELECT @AssyLot AS Lot, @pass AS Pass, @fail AS Fail, @ngtotal AS NGTotal
		UPDATE [APCSProDB].[trans].[lots] SET qty_pass = @pass, qty_fail = @fail WHERE lot_no = @AssyLot
	
		INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history] ([record_at], [record_class], [login_name], [hostname], [appname], [command_text], [lot_no])
		SELECT GETDATE(), '4', ORIGINAL_LOGIN(), HOST_NAME(), APP_NAME()
		,'EXEC [dbo].[sp_SET_dcwf_subtractNG]Detail @WFLot = ''' + CONVERT(VARCHAR, @WaferLot) + ''' @Pass = ''' + CONVERT(VARCHAR, @pass) + ''' @Fail = ''' + CONVERT(VARCHAR, @fail) + ''' '
		,@AssyLot

		IF @ngtotal = 0 BEGIN SELECT 'TRUE' AS Status, '' AS Message, '' AS Handler  RETURN     BREAK  END
		SET @i = @i - 1
	END
END
