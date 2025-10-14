-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_hasuu_Lable]
	-- Add the parameters for the stored procedure here
	@lotno varchar(10)
	
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @LotNoMax varchar(10)
		-- Insert statements for procedure here

	--select @LotNoMax = MAX(LotNo)  from OPENDATASOURCE ('SQLNCLI', 'Data Source = 10.28.1.144;User ID=LSI;Password=LSI;' ).[DBLSISHT].[dbo].MIX_HIST
	select @LotNoMax = MAX(LotNo)  from DBxDW.TGOG.MIX_HIST


	SELECT top(1)
	LotNo
	,QTY
	,QTY/Packing_Standerd_QTY As Reel
	,([QTY])%([Packing_Standerd_QTY]) as Hasuu_Total
	,Type_Name As Package
	,ASSY_Model_Name
	,ROHM_Model_Name As Device
	,Rank
	,MNo
	,WFLotNo
	,Packing_Standerd_QTY As Standard_QTY
	,[APCSProDB].[method].[package_groups].[name] as package_group_name
	--,ROHM_Model_Name+SPACE(11) + '00' + trim (Packing_Standerd_QTY)+ LotNo+'001' As TFLDQ21
	--,SUBSTRING(LotNo, 1, 4) AS Lot1
	--,SUBSTRING(LotNo, 5, 6) AS Lot2
	,SUBSTRING(LotNo, 1, 4) + space(1) + SUBSTRING(LotNo, 5, 6) AS LotnoLabel
	--,'00'+trim (Packing_Standerd_QTY) + space(1)+SUBSTRING(LotNo, 1, 4) + space(1) + SUBSTRING(LotNo, 5, 6) As TFLDQ9
	,SUBSTRING(Cast(Packing_Standerd_QTY as varchar), 1, 1) + ',' + SUBSTRING(Cast(Packing_Standerd_QTY as varchar), 2, 3)
	--FROM DBxDW.TGOG.MIX_HIST 
	--from OPENDATASOURCE ('SQLNCLI', 'Data Source = 10.28.1.144;User ID=LSI;Password=LSI;' ).[DBLSISHT].[dbo].MIX_HIST as mixhist
	from DBxDW.TGOG.MIX_HIST as mixhist
	inner join APCSProDB.method.packages on mixhist.Type_Name = APCSProDB.method.packages.name
	inner join APCSProDB.method.package_groups on APCSProDB.method.packages.package_group_id =  APCSProDB.method.package_groups.id
	WHERE LotNo = @lotno


		--SELECT top 1
		-- APCSProDB.method.package_groups.name As packagegroup
		--  ,mixhist.[HASUU_LotNo] As Lotno
		--,(mixhist.[Qty])/(h_stock.[Packing_Standerd_QTY]) As Reel
		--,mixhist.QTY As Qty
		----,[DBx].[dbo].[Test_IS_H_STOCK].[HASU_Stock_QTY]
		--,(mixhist.[Qty])%(h_stock.[Packing_Standerd_QTY]) As HASU_Stock_QTY
		--,mixhist.Type_Name As Package
		--,mixhist.[ASSY_Model_Name] As Device
		--,case when h_stock.[Packing_Standerd_QTY] is null then '-' 
		--	  else h_stock.[Packing_Standerd_QTY] end As Standard_QTY
		--,mixhist.[Rank] As Rank 
		--,h_stock.[MNo] As Mno
		--,h_stock.[WFLotNo] As WFLotNo
		--,mixhist.ROHM_Model_Name As Rohm_Model_Name
		--,(mixhist.QTY)-(mixhist.[Qty])%(h_stock.[Packing_Standerd_QTY]) As total
		--,rao.id as order_id
		--,rao.order_no as order_no
		--from DBxDW.TGOG.MIX_HIST as mixhist
		--inner join DBxDW.TGOG.H_STOCK as h_stock on mixhist.Type_Name = h_stock.[Type_Name] 
		--and mixhist.[ASSY_Model_Name] = h_stock.[ASSY_Model_Name]
		--inner join [APCSProDB].[robin].[assy_orders] as rao on mixhist.Type_Name = rao.package_name 
		--and mixhist.ROHM_Model_Name = rao.device_name
		--inner join APCSProDB.method.packages on mixhist.Type_Name = APCSProDB.method.packages.name
	 --   inner join APCSProDB.method.package_groups on APCSProDB.method.packages.package_group_id =  APCSProDB.method.package_groups.id
		--where mixhist.Type_Name like @package and mixhist.[ASSY_Model_Name] like @device and mixhist.LotNo = @LotNoMax
		----where mixhist.Type_Name like 'SSOP-B20W' and mixhist.[ASSY_Model_Name] like 'BA6905FV-F(W3U)' and mixhist.LotNo = '2015D3001V'
		--and HASUU_LotNo Like '2%D%'
		--Order by [DBx].[dbo].[Test_IS_MIX_HIST].MIXD_DATE Desc
	
END
