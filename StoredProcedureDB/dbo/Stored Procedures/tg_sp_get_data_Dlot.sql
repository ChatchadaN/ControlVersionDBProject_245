-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_data_Dlot]
	-- Add the parameters for the stored procedure here
	@lotno0 char(10) ='',
	@lotno1 char(10) ='',
	@lotno2 char(10) ='',
	@lotno3 char(10)='',
	@lotno4 char(10)='',
	@lotno5 char(10)='',
	@lotno6 char(10)='',
	@lotno7 char(10)='',
	@lotno8 char(10)='',
	@lotno9 char(10)='',
	--@package char(10),
	--@device char(20),
	--@rank char(5),
	@total_pcs int,
	--@hasuu_total int,
	@empno char(6)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
		SELECT 
		Stock_Class
	   ,LotNo
	   ,PDCD
	   ,HASU_Stock_QTY
	   ,Packing_Standerd_QTY
	   ,HASU_Stock_QTY/Packing_Standerd_QTY 
	   ,(Packing_Standerd_QTY) * (@total_pcs/(Packing_Standerd_QTY)) as Qty_Full_Reel_All
	   ,ROHM_Model_Name
	   ,ASSY_Model_Name
	   ,R_Fukuoka_Model_Name
	   ,TIRank
	   ,Rank as Rank_H_Stock
	   ,TPRank
	   ,SUBRank
	   ,Mask
	   ,KNo
	   ,Tomson_Mark_1
	   ,Tomson_Mark_2
	   ,Tomson_Mark_3
	   ,ORNo
	   ,MNo
	   ,WFLotNo
	   ,LotNo_Class
	   ,Label_Class
	   ,Product_Control_Clas
	   ,Product_Class
	   ,Production_Class
	   ,Rank_No as RankNo
	   ,HINSYU_Class
	   FROM [DBxDW].[TGOG].[Temp_H_STOCK]
       --FROM DBxDW.TGOG.H_STOCK
	   --FROM [StoredProcedureDB].[dbo].[IS_H_STOCK]
	   --WHERE [Type_Name] like @package and [ASSY_Model_Name] like @device and [Rank] like @rank
	   WHERE  LotNo IN (@lotno0,@lotno1,@lotno2,@lotno3,@lotno4,@lotno5,@lotno6,@lotno7,@lotno8,@lotno9)
	   and DMY_OUT_Flag != '1' 
	   and Derivery_Date  >= (getdate() - 1095)
	   and HASU_Stock_QTY != '0'

END
