-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_test_sp_set_d_lot]
	-- Add the parameters for the stored procedure here
	--@hasuu_lotno char(10)
	@arraylotno char(150)
	--@type_name char(20)
	--@rohm_model_name char(50),
	--@qty int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @LotNochk varchar(10)
    -- Insert statements for procedure here
	select @LotNochk =  LotNo from DBxDW.TGOG.H_STOCK where LotNo in (@arraylotno)
	

	insert into DBx.dbo.test_TG_Set_D_Lot(Hasuu_Lotno,Lotno,TypeName,RohmModelName,QTY,CreateDate)
	VALUES (
		 (select  right(YEAR(GETDATE()),2)
					+ case when len(DATEPART(week, GETDATE())) = 1 then CONCAT('0',DATEPART(week, GETDATE())) 
					   else CAST(DATEPART(week, GETDATE()) As varchar ) end 
					+ CAST('D' AS varchar) 
					--+ CAST(DAY(GETDATE()) AS varchar)  
					+ CAST(DATEPART(dw,getdate()) AS varchar)
					+ CAST('001' AS varchar) 
					+ CAST('V' AS varchar))
	,@LotNochk
	,'test'
	,'test'
	,1
	,GETDATE())
END
