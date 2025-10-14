-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_update_version_label_tp] 
	-- Add the parameters for the stored procedure here
	@lotno varchar(10) = ''
	,@Type_label int = 0
	,@reel_number char(3) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	--IF @reel_number = ''
	--BEGIN
	--		--UPDATE VERSION PRINT COUNT
	--		update APCSProDB.trans.label_issue_records 
	--		set version = version + 1  
	--		where lot_no = @lotno
	--		and type_of_label = @Type_label

	--		--UPDATE QRCODE DETAIL REEL
	--		update APCSProDB.trans.label_issue_records
	--		SET qrcode_detail = SUBSTRING(qrcode_detail,1,35) + Cast((VERSION) as char(1)) + '0' + no_reel
	--		where lot_no = @lotno 
	--		and type_of_label = @Type_label

	--		select lot_no,qrcode_detail,version from APCSProDB.trans.label_issue_records 
	--		where lot_no = @lotno
	--		and type_of_label = @Type_label
	--END
	--ELSE
	--BEGIN
	--	   --UPDATE VERSION PRINT COUNT
	--		update APCSProDB.trans.label_issue_records 
	--		set version = version + 1  
	--		where lot_no = @lotno
	--		and type_of_label = @Type_label
	--		and no_reel = @reel_number

	--		--UPDATE QRCODE DETAIL REEL
	--		update APCSProDB.trans.label_issue_records
	--		SET qrcode_detail = SUBSTRING(qrcode_detail,1,35) + Cast((VERSION) as char(1)) + '0' + no_reel
	--		where lot_no = @lotno 
	--		and type_of_label = @Type_label
	--		and no_reel = @reel_number
	--END

END
