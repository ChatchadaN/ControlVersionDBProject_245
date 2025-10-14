-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_hasuuALot_Lable]
	-- Add the parameters for the stored procedure here
	@lotno varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT top (1) 
	LotNo
	,QTY
	,QTY/Packing_Standerd_QTY As Reel
	,([QTY])%([Packing_Standerd_QTY]) as Hasuu_Total
	,Type_Name
	,ASSY_Model_Name
	,ROHM_Model_Name
	,TPRank as  Rank
	,MNo
	,WFLotNo
	,Packing_Standerd_QTY
	,ROHM_Model_Name+SPACE(3)+'009131'+LotNo+'001' As DeviceandOpNoandLotNoandWhat
	,ROHM_Model_Name+SPACE(3)+Rank As DeviceannRank
	,QTY-([QTY])%([Packing_Standerd_QTY]) As total
	--from DBxDW.TGOG.MIX_HIST
	--from OPENDATASOURCE ('SQLNCLI', 'Data Source = 10.28.1.144;User ID=LSI;Password=LSI;' ).[DBLSISHT].[dbo].[MIX_HIST]
	from DBxDW.TGOG.MIX_HIST
	where LotNo = @lotno
	--where LotNo = '2001A6143V'

	
END
