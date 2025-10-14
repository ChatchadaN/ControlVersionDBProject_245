-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_search_data] 
	-- Add the parameters for the stored procedure here
	@lotno varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT 
	[APCSProDB].[method].[package_groups].[name] as package_group_name
	,LotNo
	,QTY
	,QTY/Packing_Standerd_QTY As Reel
	,([QTY])%([Packing_Standerd_QTY]) as Hasuu_Total
	,Type_Name
	,ASSY_Model_Name
	,ROHM_Model_Name
	,Rank
	,MNo
	,WFLotNo
	,Packing_Standerd_QTY
	,ROHM_Model_Name+SPACE(11) + '00' + trim (cast(Packing_Standerd_QTY as varchar)) + LotNo + '001' As TFLDQ21
	--,SUBSTRING(LotNo, 1, 4) AS Lot1
	--,SUBSTRING(LotNo, 5, 6) AS Lot2
	,SUBSTRING(LotNo, 1, 4) + space(1) + SUBSTRING(LotNo, 5, 6) AS LotnoLabel
	,'00'+ trim (cast(Packing_Standerd_QTY as varchar)) + space(1)+SUBSTRING(LotNo, 1, 4) + space(1) + SUBSTRING(LotNo, 5, 6) As TFLDQ9
	,SUBSTRING(cast(Packing_Standerd_QTY as varchar), 1, 1) + ',' + SUBSTRING(cast(Packing_Standerd_QTY as varchar), 2, 3)
	FROM DBxDW.TGOG.MIX_HIST as mixhist
	--from OPENDATASOURCE ('SQLNCLI', 'Data Source = 10.28.1.144;User ID=LSI;Password=LSI;' ).[DBLSISHT].[dbo].[MIX_HIST] as mixhist
	inner join APCSProDB.method.packages on mixhist.Type_Name = APCSProDB.method.packages.name
	inner join APCSProDB.method.package_groups on APCSProDB.method.packages.package_group_id =  APCSProDB.method.package_groups.id
	WHERE LotNo like @lotno
	--where LotNo = '2014D1005V' and HASUU_LotNo = '2014D1005V'

END
