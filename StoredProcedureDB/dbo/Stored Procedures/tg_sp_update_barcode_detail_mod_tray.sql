-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_update_barcode_detail_mod_tray] 
	-- Add the parameters for the stored procedure here
	 @Lotno varchar(10)
	,@Barcode_1_Mod_Data varchar(20) = ''
	,@Barcode_2_Mod_Data varchar(20) = ''
	,@Tray_number int = 0
	,@Type_of_Label int = 0
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here

	BEGIN TRY 

		--UPDATE APCSProDB.trans.label_issue_records
		--SET barcode_1_mod = @Barcode_1_Mod_Data
		--,barcode_2_mod = Cast(SUBSTRING(@Lotno, 1, 4) as char(4)) + ' ' + Cast(SUBSTRING(@Lotno, 5, 6) as char(6))
		--WHERE lot_no = @Lotno 
		--and type_of_label = 2

		UPDATE APCSProDB.trans.label_issue_records
		SET barcode_1_mod = @Barcode_1_Mod_Data
		,barcode_2_mod = @Barcode_2_Mod_Data
		WHERE lot_no = @Lotno 
		and type_of_label = @Type_of_Label and no_reel = @Tray_number

		SELECT 'TRUE' AS Status ,'UPDATE DATA BARCODE MOD IS TRAY SUCCESS !!' AS Error_Message_ENG,N'update ข้อมูล สำเร็จ' AS Error_Message_THA 
		RETURN
	END TRY
	BEGIN CATCH
		SELECT 'FALSE' AS Status ,'UPDATE DATA BARCODE MOD IS TRAY ERROR !!' AS Error_Message_ENG,N'ไม่สามารถ update ข้อมูลได้' AS Error_Message_THA ,N' กรุณาติดต่อ System' AS Handling
		RETURN
	END CATCH

	
	
END
