-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_set_hasuu_A_lot]
	-- Add the parameters for the stored procedure here
	@lotno char(10),
	@empno char(6) = ' ',
	@hasuu_lotno char(10) = ' ',
	@Pdcd char(5) = ' ',
	@MNo_Standard char(10) = ' ',
	@MNo char(10) = ' ',
	@Type_Name char(10) = ' ', 
	@ROHM_Model_Name char(20) = ' ',
	@ASSY_Model_Name char(20) = ' ',
	@R_Fukuoka_Model_Name char(20) = ' ',
	@TIRank char(5) = ' ',
	@TPRank char(5) = ' ',
	@Rank char(5) = ' ',
	@SUBRank char(3) = ' ',
	@Mask char(2) = ' ',
	@KNo char(3) = ' ',
	@Tomson_Mark_1 char(4) = ' ',
	@Tomson_Mark_2 char(4) = ' ',
	@Tomson_Mark_3 char(4) = ' ',
	@ORNo char(12) = ' ',
	@WFLotNo char(20) = ' ',
	@LotNo_Class char(1) = ' ',
	@Product_Control_Clas char(3) = ' ',
	@ProductClass char(1) = ' ',
	@ProductionClass char(1) = ' ',
	@RankNo char(6) = ' ',
	@HINSYU_Class char(1) = ' ',
	@Label_Class char(1) = ' ',
	@Out_Out_Flag char(1) = ' ',
	@QtyPass_Tranlot int = 0,
	@QTY_Lot_Standard int = 0,
	@Hasuu_Stock_QTY int,
	@Total int = 0,
	@Standerd_QTY int = 0,
	@Allocation_Date char(30) = ' '
	

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.

	---- ########## VERSION 001 ##########
	-- call 2022/12/07 Time : 16.35
	--EXEC [StoredProcedureDB].[dbo].[tg_sp_set_hasuu_A_lot_backup20221208] @lotno = @lotno			
	--	, @empno = @empno				
	--	, @hasuu_lotno = @hasuu_lotno				
	--	, @Pdcd	= @Pdcd					
	--	, @MNo_Standard	= @MNo_Standard			
	--	, @MNo = @MNo					
	--	, @Type_Name = @Type_Name			
	--	, @ROHM_Model_Name = @ROHM_Model_Name		
	--	, @ASSY_Model_Name = @ASSY_Model_Name	
	--	, @R_Fukuoka_Model_Name = @R_Fukuoka_Model_Name	
	--	, @TIRank = @TIRank				
	--	, @TPRank = @TPRank				
	--	, @Rank = @Rank				
	--	, @SUBRank = @SUBRank				
	--	, @Mask = @Mask				
	--	, @KNo = @KNo				
	--	, @Tomson_Mark_1 = @Tomson_Mark_1			
	--	, @Tomson_Mark_2 = @Tomson_Mark_2			
	--	, @Tomson_Mark_3 = @Tomson_Mark_3			
	--	, @ORNo = @ORNo				
	--	, @WFLotNo = @WFLotNo				
	--	, @LotNo_Class = @LotNo_Class			
	--	, @Product_Control_Clas	= @Product_Control_Clas	
	--	, @ProductClass	= @ProductClass			
	--	, @ProductionClass = @ProductionClass			
	--	, @RankNo = @RankNo				
	--	, @HINSYU_Class = @HINSYU_Class		
	--	, @Label_Class = @Label_Class			
	--	, @Out_Out_Flag = @Out_Out_Flag		
	--	, @QtyPass_Tranlot = @QtyPass_Tranlot		
	--	, @QTY_Lot_Standard	= @QTY_Lot_Standard		
	--	, @Hasuu_Stock_QTY = @Hasuu_Stock_QTY		
	--	, @Total = @Total		
	--	, @Standerd_QTY = @Standerd_QTY		
	--	, @Allocation_Date = @Allocation_Date		
	---- ########## VERSION 001 ##########

	---- ########## VERSION 002 ##########
	--call new store create 2022/12/07 Time : 09.31
	------------------------------------------------------------------------------------------------
	EXEC [StoredProcedureDB].[dbo].[tg_sp_set_hasuu_A_lot_new] @lotno = @lotno			
	,@empno		= @empno				
	,@hasuu_lotno	= @hasuu_lotno				
	,@Pdcd	= @Pdcd					
	,@MNo_Standard	= @MNo_Standard			
	,@MNo	= @MNo					
	,@Type_Name		= @Type_Name			
	,@ROHM_Model_Name	= @ROHM_Model_Name		
	,@ASSY_Model_Name	= @ASSY_Model_Name	
	,@R_Fukuoka_Model_Name	= @R_Fukuoka_Model_Name	
	,@TIRank		= @TIRank				
	,@TPRank		= @TPRank				
	,@Rank		= @Rank				
	,@SUBRank	= @SUBRank				
	,@Mask		= @Mask				
	,@KNo		= @KNo				
	,@Tomson_Mark_1	= @Tomson_Mark_1			
	,@Tomson_Mark_2	= @Tomson_Mark_2			
	,@Tomson_Mark_3	= @Tomson_Mark_3			
	,@ORNo		= @ORNo				
	,@WFLotNo	= @WFLotNo				
	,@LotNo_Class	= @LotNo_Class			
	,@Product_Control_Clas	= @Product_Control_Clas	
	,@ProductClass	= @ProductClass			
	,@ProductionClass	= @ProductionClass			
	,@RankNo		= @RankNo				
	,@HINSYU_Class	= @HINSYU_Class		
	,@Label_Class	= @Label_Class			
	,@Out_Out_Flag	= @Out_Out_Flag		
	,@QtyPass_Tranlot	= @QtyPass_Tranlot		
	,@QTY_Lot_Standard	= @QTY_Lot_Standard		
	,@Hasuu_Stock_QTY	= @Hasuu_Stock_QTY		
	,@Total				= @Total		
	,@Standerd_QTY		= @Standerd_QTY		
	,@Allocation_Date	= @Allocation_Date		
	------------------------------------------------------------------------------------------------
	---- ########## VERSION 002 ##########
END
