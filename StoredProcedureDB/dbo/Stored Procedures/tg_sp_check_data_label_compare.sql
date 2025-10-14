-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_check_data_label_compare]
	-- Add the parameters for the stored procedure here
	@qrcode char(38) 
	,@barcode_mod_1 char(20)
	,@barcode_mod_2 char(19)
	,@type_label int = 0
	,@reel_no char(1)
	,@lot_no varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @qrcode_value char(38)
	DECLARE @barcode_mod_1_value char(20)
	DECLARE @barcode_mod_2_value char(20)
    -- Insert statements for procedure here
	
	select 
	 @qrcode_value = RTRIM(qrcode_detail)
	,@barcode_mod_1_value = RTRIM(barcode_1_mod)
	,@barcode_mod_2_value = RTRIM(barcode_2_mod) 
	from APCSProDB.trans.label_issue_records 
	where type_of_label = @type_label and no_reel = @reel_no and lot_no = @lot_no

	

	IF @qrcode = @qrcode_value and @barcode_mod_1 = @barcode_mod_1_value and @barcode_mod_2 = @barcode_mod_2_value
	BEGIN
		SELECT 'TRUE' AS Status ,'Data Compare Success !!' AS Error_Message_ENG,N'ผ่าน !!' AS Error_Message_THA
		RETURN
	END
	ELSE
	BEGIN
		SELECT 'FALSE' AS Status ,'Data Compare Error !!' AS Error_Message_ENG,N'ไม่ผ่าน' AS Error_Message_THA ,N'Scan Label ใหม่ !!' AS Handling
		RETURN
	END

END
