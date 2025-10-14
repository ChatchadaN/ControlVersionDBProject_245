-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_process_code] 
	-- Add the parameters for the stored procedure here
	@lotno varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @Process_Code nvarchar(5);
	DECLARE @Tomson3 nvarchar(5);
	DECLARE @Tomson3_D_lot nvarchar(5);
	DECLARE @lotno_type char(1);    -- Insert statements for procedure here

	select @lotno_type =  SUBSTRING(@lotno,5,1)

	IF @lotno != ''
	BEGIN
		--select @Process_Code = PROCESS_POST_CODE 
		--,@Tomson3 = TOMSON_INDICATION
		--from APCSDB.dbo.LCQW_UNION_WORK_DENPYO_PRINT where LOT_NO_2 = @lotno

		--select @Tomson3_D_lot = pdcd from APCSProDB.trans.surpluses where serial_no = @lotno

		--select case when @lotno_type = 'D' then @Tomson3_D_lot else @Process_Code end as PDCD
		--,@Tomson3 as Tomson_3

		--Edit Query Get Data ProductCode and Tomson3 2023/01/18 time : 09.38
		SELECT pdcd as PDCD
		,qc_instruction as Tomson_3
		FROM APCSProDB.trans.surpluses 
		WHERE serial_no = @lotno

	END
	ELSE
	BEGIN
		SELECT 'FALSE' AS Status ,'SELECT DATA ERROR !!' AS Error_Message_ENG,N'ไม่พบข้อมูลของ lotno นี้ !!' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
		RETURN
	END

END
