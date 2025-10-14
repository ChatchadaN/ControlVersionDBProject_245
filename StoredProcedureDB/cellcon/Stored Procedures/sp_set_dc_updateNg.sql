-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_set_dc_updateNg]
	-- Add the parameters for the stored procedure here
	@OrderNo nvarchar(20), 
	@WaferLot nvarchar(20),
	@ngTotal int,
	@Package nvarchar(20)

AS
BEGIN 
	SET NOCOUNT ON;
	DECLARE @Check_Lot_No nvarchar(10) = ' '
	DECLARE @Check_Lot_No2 nvarchar(10) = ' '
	DECLARE @Check_ORDER_NO nvarchar(20) = ' '
	DECLARE @Check_HASU_LOT nvarchar(10) = ' '
	DECLARE @Check_qty_in int
	DECLARE @Check_qty_pass int 
	DECLARE @Check_qty_pass2 int 
	DECLARE @Check_qty_fail int
	DECLARE @Check_qty_fail2 int
	DECLARE @tmpTableLotDc TABLE (Lot_No varchar(20), ORDER_NO nvarchar(20),HASU_LOT nvarchar(10),qty_in int,qty_pass int ,qty_fail int)
	DECLARE @Type varchar(20)

	IF @OrderNo = ''
		Begin
			SELECT 'BYPASS' AS Status					
			RETURN 
		End

	IF @ngTotal = 0
		Begin
			SELECT 'BYPASS' AS Status					
			RETURN 
		End

	BEGIN TRY
				--นับ row
				DECLARE @sumCountRow int
				SELECT @sumCountRow = COUNT(*) FROM [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] as denpyo
						inner join [APCSProDB].[trans].lots on denpyo.LOT_NO_1 = [lots].lot_no
				WHERE
					(ORDER_NO = @OrderNo) AND (PERETTO_NO_1 LIKE @WaferLot + '%') OR
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

				DECLARE @i INT = 1
				DECLARE @lotRow nvarchar(10) = ' '
				WHILE (@i <= @sumCountRow)
					 BEGIN
								SELECT top (@i) @lotRow = LOT_NO_1 ,@Check_qty_pass = lots.qty_pass,@Check_qty_fail = lots.qty_fail , @Type = TYPE
								FROM [APCSDB].[dbo].[LCQW_UNION_WORK_DENPYO_PRINT] as denpyo
								inner join [APCSProDB].[trans].lots on denpyo.LOT_NO_1 = [lots].lot_no
								WHERE  -- (HASU_LOT <> 'HASUULOT') AND
										(ORDER_NO = @OrderNo) AND (PERETTO_NO_1 LIKE @WaferLot + '%') OR
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
										order by LOT_NO_1 desc

								 -- COMMENT ON NOV.03.2021  --> UNCOMMENT ON DEC.08.2021
								IF @Type = 'MALUTI KO' or @Type = 'MALUTI OYA'
									BEGIN
										SELECT 'BYPASS' AS Status
										RETURN
									END

								IF @Check_qty_pass >= @ngTotal
									BEGIN
										DECLARE @sumValue int = @Check_qty_pass - @ngTotal
										DECLARE @sumValueNgTotal int = @Check_qty_fail + @ngTotal
											UPDATE [APCSProDB].[trans].[lots]
											SET   qty_pass = @sumValue,
												  qty_fail = @sumValueNgTotal
											WHERE [lots].[lot_no] = @lotRow
				 
										SELECT 'TRUE' AS Status , @Check_Lot_No as lotNo, @Check_qty_pass as passValue, @ngTotal as ngValue	 , @sumValue as sumValue 
										RETURN
									END
								ELSE
									SET @ngTotal =  @ngTotal - @Check_qty_pass	
										UPDATE [APCSProDB].[trans].[lots]
										SET   qty_pass = 0,
											  qty_fail = @Check_qty_pass
										WHERE [lots].[lot_no] = @lotRow							
						SET @i = @i + 1				
				END -- WHILE

			SELECT 'FALSE' AS Status, @Check_Lot_No as lotNo ,@Check_qty_in as qtyIN, @sumValue as sumValue , @Check_qty_pass as passValue, @ngTotal as ngValue		
			RETURN
	END TRY
			BEGIN CATCH
					SELECT 'FALSE' AS Status					
					RETURN 
			END CATCH
END 
