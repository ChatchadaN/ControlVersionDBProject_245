-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_check_device_is_tray]
	-- Add the parameters for the stored procedure here
	@lotno varchar(10) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @device_Name char(20) = ''
	DECLARE @Rank nvarchar(5) = ''
	DECLARE @TP_Rank nvarchar(5) = ''
	DECLARE @Universal_tp_rank varchar(5) = ''
    -- Insert statements for procedure here

	select 
		 @device_Name = dv.name
		 ,@TP_Rank = dv.tp_rank
		,@Rank = dv.rank
		,@Universal_tp_rank = dv.universal_tp_rank
		from APCSProDB.trans.lots as lot
		inner join APCSProDB.method.device_names as dv on lot.act_device_name_id = dv.id
		where lot_no = @lotno

		--select @device_Name as device
		--select @Rank as rank_value
		--select @TP_Rank as tp_rank
		--select @Universal_tp_rank as universal

	IF @lotno <> ''
	BEGIN
		IF (@TP_Rank = '' or @TP_Rank is null) and @Universal_tp_rank is null
		BEGIN
			select '1' as status_device --is_tray
		END
		ELSE
		BEGIN
			select '0' as status_device --is_not_tray
		END
	END
	ELSE
	BEGIN
		SELECT 'FALSE' AS Status ,'SELECT DATA ERROR !!' AS Error_Message_ENG,N'ไม่พบข้อมูล lotno นี้' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
		RETURN
	END

END
