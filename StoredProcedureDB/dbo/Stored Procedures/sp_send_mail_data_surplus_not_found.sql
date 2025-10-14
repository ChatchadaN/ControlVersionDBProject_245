-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_send_mail_data_surplus_not_found]
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @mail_profile NVARCHAR(100) = 'LSIMailNotify'
		, @mail_subject NVARCHAR(max) = ''
		, @mail_to NVARCHAR(MAX) = ''
		, @mail_cc NVARCHAR(MAX) = ''
		, @mail_body_format NVARCHAR(100) = 'HTML'
		, @mail_body NVARCHAR(MAX) = ''
		, @mail_importance NVARCHAR(20) = 'HIGH'
		, @date_select NVARCHAR(30)
		, @file_name NVARCHAR(100)
		, @query_string NVARCHAR(500)
		, @tab CHAR(1) = CHAR(9)

	SET @date_select = CONVERT(VARCHAR(20), GETDATE(), 113);
	
	---- Set mail to
	--SET @mail_to = 'chirasit.pal@mnf2.rohmthai.com;vanatjaya.pan@mnf2.rohmthai.com;Nucha.Pra@mnf2.rohmthai.com;';
	SET @mail_to = 'kittitat.pan@mnf2.rohmthai.com;';
	---- Set mail cc
	SET @mail_cc = 'kittitat.pan@mnf2.rohmthai.com;';
 
	---- Set subject mail
	SET @mail_subject = N'#data_surplus_not_found ' + @date_select;
	SET @file_name = N'LotSurplus(IS found)(PRO not found).CSV';

	SET @mail_body = N'Would you mind checking, please?';

	---- Send mail
	IF EXISTS(
		SELECT H_STOCK_IF.LotNo
			, H_STOCK_IF.ROHM_Model_Name
			, H_STOCK_IF.ASSY_Model_Name
			, H_STOCK_IF.R_Fukuoka_Model_Name
			, H_STOCK_IF.Timestamp_Date
		FROM APCSProDWH.dbo.H_STOCK_IF 
		LEFT JOIN APCSProDB.trans.lots ON H_STOCK_IF.LotNo = lots.lot_no
		WHERE lots.lot_no IS NULL
	)
	BEGIN
		SET	@query_string = N'
			SELECT H_STOCK_IF.LotNo
				, H_STOCK_IF.ROHM_Model_Name
				, H_STOCK_IF.ASSY_Model_Name
				, H_STOCK_IF.R_Fukuoka_Model_Name
				, H_STOCK_IF.Timestamp_Date
			FROM APCSProDWH.dbo.H_STOCK_IF 
			LEFT JOIN APCSProDB.trans.lots ON H_STOCK_IF.LotNo = lots.lot_no
			WHERE lots.lot_no IS NULL';

		EXEC msdb.dbo.sp_send_dbmail
			@profile_name = @mail_profile, 
			@recipients = @mail_to, 
			@copy_recipients = @mail_cc,
			@subject = @mail_subject, 
			@body = @mail_body, 
			@body_format = @mail_body_format,
			@importance = @mail_importance,
			@query = @query_string ,
			@attach_query_result_as_file = 1,
			@query_attachment_filename = @file_name,
			@query_result_separator = @tab,
			@query_result_no_padding = 1;	
	END
END