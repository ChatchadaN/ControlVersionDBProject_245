-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_allocat]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- Insert statements for procedure here

	-------------------------------------------------------------------------------------------------------
	-- (1) delete table allocat
	-------------------------------------------------------------------------------------------------------
	DELETE FROM [APCSProDB].[method].[allocat];

	-------------------------------------------------------------------------------------------------------
	-- (2) insert from is.allocat to pro.allocat
	-------------------------------------------------------------------------------------------------------
	INSERT INTO [APCSProDB].[method].[allocat]
		( [LotNo]
		, [Type_Name]
		, [ROHM_Model_Name]
		, [ASSY_Model_Name]
		, [R_Fukuoka_Model_Name]
		, [TIRank]
		, [Rank]
		, [TPRank]
		, [SUBRank]
		, [PDCD]
		, [Mask]
		, [KNo]
		, [MNo]
		, [ORNo]
		, [Packing_Standerd_QTY]
		, [Tomson1]
		, [Tomson2]
		, [Tomson3]
		, [WFLotNo]
		, [LotNo_Class]
		, [User_Code]
		, [Product_Control_Cl_1]
		, [Product_Class]
		, [Production_Class]
		, [Rank_No]
		, [HINSYU_Class]
		, [Label_Class]
		, [OUT_OUT_FLAG]
		, [allocation_Date]
		, [allocation_QTY]
		, [Print_Flag]
		, [Timestamp_Date]
		, [Timestamp_Time] )
	SELECT [LotNo]
		, [Type_Name]
		, [ROHM_Model_Name]
		, [ASSY_Model_Name]
		, [R_Fukuoka_Model_Name]
		, [TIRank]
		, [Rank]
		, [TPRank]
		, [SUBRank]
		, [PDCD]
		, [Mask]
		, [KNo]
		, [MNo]
		, [ORNo]
		, [Packing_Standerd_QTY]
		, [Tomson1]
		, [Tomson2]
		, [Tomson3]
		, [WFLotNo]
		, [LotNo_Class]
		, [User_Code]
		, [Product_Control_Cl_1]
		, [Product_Class]
		, [Production_Class]
		, [Rank_No]
		, [HINSYU_Class]
		, [Label_Class]
		, [OUT_OUT_FLAG]
		, [allocation_Date]
		, [allocation_QTY]
		, [Print_Flag]
		, [Timestamp_Date]
		, [Timestamp_Time]
	FROM [ISDB].[DBLSISHT].[dbo].[ALLOCAT];
END
