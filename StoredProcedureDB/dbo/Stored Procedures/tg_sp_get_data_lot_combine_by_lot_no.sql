-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_data_lot_combine_by_lot_no]
	-- Add the parameters for the stored procedure here
	@lot_no VARCHAR(10) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @MemberLotNo VARCHAR(10) = @lot_no;
	----------------------------------------------------------------------------------------------------------
	DECLARE @Counter INT 
	DECLARE @CounterTotal INT 
	--//table data
	DECLARE @table TABLE(
		[LotId] INT,
		[LotNo] VARCHAR(10),
		[MemberLotId] INT,
		[MemberLotNo] VARCHAR(10),
		[Floor] INT
	)
	--//table data loop
	DECLARE @table2 TABLE(
		[MemberLotNo] VARCHAR(10)
	)
	----------------------------------------------------------------------------------------------------------
	IF (@MemberLotNo IS NOT NULL AND @MemberLotNo != '')
	BEGIN
		BEGIN TRY  
			SET @Counter = 1
			SET @CounterTotal = 1
			WHILE ( @Counter <= @CounterTotal)
			BEGIN
				--//row 1 data from @MemberLotNo
				IF (@Counter = 1)
				BEGIN
					DELETE FROM @table2;
					INSERT INTO @table2 ([MemberLotNo])
					SELECT [lot_no] FROM [APCSProDB].[trans].[lots] WHERE [lot_no] = @MemberLotNo;
				END
				----------------------------------------------------------------------------------------------------------
				--//Check data exists
				IF EXISTS(
					SELECT [lots].[id] AS [LotId] 
						, [lots].[lot_no] AS [LotNo]
						, [m_lots].[id] AS [MemberLotId] 
						, [m_lots].[lot_no] AS [MemberLotNo]
					FROM  [APCSProDB].[trans].[lot_combine]
					INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = [lot_combine].[lot_id]
					INNER JOIN [APCSProDB].[trans].[lots] AS [m_lots] ON [m_lots].[id] = [lot_combine].[member_lot_id]
					WHERE [m_lots].[lot_no] IN (SELECT [MemberLotNo] FROM @table2)
				)
				BEGIN
					----------------------------------------------------------------------------------------------------------
					--//set data to @table
					INSERT INTO @table 
					(
						[LotId],
						[LotNo],
						[MemberLotId],
						[MemberLotNo],
						[Floor]
					)
					SELECT [lots].[id] AS [LotId] 
						, [lots].[lot_no] AS [LotNo]
						, [m_lots].[id] AS [MemberLotId] 
						, [m_lots].[lot_no] AS [MemberLotNo]
						, @Counter AS [Floor]
					FROM  [APCSProDB].[trans].[lot_combine]
					INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = [lot_combine].[lot_id]
					INNER JOIN [APCSProDB].[trans].[lots] AS [m_lots] ON [m_lots].[id] = [lot_combine].[member_lot_id]
					WHERE [m_lots].[lot_no] IN (SELECT [MemberLotNo] FROM @table2)
						AND [lots].[id] != [m_lots].[id];
					----------------------------------------------------------------------------------------------------------
					--//set data next loop
					DELETE FROM @table2;
					INSERT INTO @table2 ([MemberLotNo])
					SELECT [m_lots].[lot_no] AS [MemberLotNo]
					FROM  [APCSProDB].[trans].[lot_combine]
					INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[id] = [lot_combine].[lot_id]
					INNER JOIN [APCSProDB].[trans].[lots] AS [m_lots] ON [m_lots].[id] = [lot_combine].[member_lot_id]
					WHERE [m_lots].[lot_no] IN (SELECT [LotNo] FROM @table WHERE [Floor] = @Counter AND [LotId] != [MemberLotId]);
					----------------------------------------------------------------------------------------------------------
					SET @CounterTotal = @CounterTotal + 1;
				END
				----------------------------------------------------------------------------------------------------------
				SET @Counter = @Counter  + 1;
			END
			--//Select Data
			SELECT [DataLot].[LotNo] AS [LotNo]
				, [packages].[name] AS [Type_Name]
				, [device_names].[name] AS [ROHM_Model_Name]
				, [device_names].[assy_name] AS [ASSY_Model_Name]
				, [device_names].[rank] AS [TIRank]
				, [device_names].[rank] AS [Rank]
				, [device_names].[tp_rank] AS [TPRank]
				, [surpluses].[mark_no] AS [MNo]
				, [device_names].[pcs_per_pack] AS [Packing_Standerd_QTY]
				, [surpluses].[qc_instruction] AS [Tomson3]
				, [DataLot].[LotNo] AS [Standard_LotNo]
				, [DataLot].[MemberLotNo] AS [Complement_LotNo_1]
				, [surpluses].[mark_no] AS [Standard_MNo]
				, [mem_surpluses].[mark_no] AS [Complement_MNo_1]
				, [lots].[qty_pass] AS [Standerd_QTY]
				, [mem_surpluses].[pcs] AS [Complement_QTY_1]
				, [lots].[qty_out] AS [Shipment_QTY]
				, ([lots].[qty_out] + [surpluses].[pcs]) AS [Good_Product_QTY]
				, [lot_combine].[created_by] AS [OPNo]
				, [lot_combine].[created_at] AS [Timestamp_Date]
				, [DataLot].[Floor]
			FROM @table AS [DataLot]
			INNER JOIN [APCSProDB].[trans].[lots] ON [DataLot].[LotId] = [lots].[id]
			INNER JOIN [APCSProDB].[method].[device_names] ON [lots].[act_device_name_id] = [device_names].[id]
			INNER JOIN [APCSProDB].[method].[packages] ON [device_names].[package_id] = [packages].[id]
			INNER JOIN [APCSProDB].[trans].[lot_combine] ON [DataLot].[LotId] = [lot_combine].[lot_id]
				AND [DataLot].[MemberLotId] = [lot_combine].[member_lot_id]
			LEFT JOIN [APCSProDB].[trans].[surpluses] ON [DataLot].[LotId] = [surpluses].[lot_id]
			LEFT JOIN [APCSProDB].[trans].[surpluses] AS [mem_surpluses] ON [DataLot].[MemberLotId] = [mem_surpluses].[lot_id]
			ORDER BY [DataLot].[Floor] ASC;
		END TRY  
		BEGIN CATCH  
			DELETE FROM @table;
			--//No Data
			SELECT NULL AS [LotNo]
				, NULL AS [Type_Name]
				, NULL AS [ROHM_Model_Name]
				, NULL AS [ASSY_Model_Name]
				, NULL AS [TIRank]
				, NULL AS [Rank]
				, NULL AS [TPRank]
				, NULL AS [MNo]
				, NULL AS [Packing_Standerd_QTY]
				, NULL AS [Tomson3]
				, NULL AS [Standard_LotNo]
				, NULL AS [Complement_LotNo_1]
				, NULL AS [Standard_MNo]
				, NULL AS [Complement_MNo_1]
				, NULL AS [Standerd_QTY]
				, NULL AS [Complement_QTY_1]
				, NULL AS [Shipment_QTY]
				, NULL AS [Good_Product_QTY]
				, NULL AS [OPNo]
				, NULL AS [Timestamp_Date]
				, NULL AS [Floor]
			FROM @table AS [DataLot]
		END CATCH  
	END
	ELSE
	BEGIN
		--//No Data
		SELECT NULL AS [LotNo]
			, NULL AS [Type_Name]
			, NULL AS [ROHM_Model_Name]
			, NULL AS [ASSY_Model_Name]
			, NULL AS [TIRank]
			, NULL AS [Rank]
			, NULL AS [TPRank]
			, NULL AS [MNo]
			, NULL AS [Packing_Standerd_QTY]
			, NULL AS [Tomson3]
			, NULL AS [Standard_LotNo]
			, NULL AS [Complement_LotNo_1]
			, NULL AS [Standard_MNo]
			, NULL AS [Complement_MNo_1]
			, NULL AS [Standerd_QTY]
			, NULL AS [Complement_QTY_1]
			, NULL AS [Shipment_QTY]
			, NULL AS [Good_Product_QTY]
			, NULL AS [OPNo]
			, NULL AS [Timestamp_Date]
			, NULL AS [Floor]
		FROM @table AS [DataLot]
	END	
	----------------------------------------------------------------------------------------------------------
END
