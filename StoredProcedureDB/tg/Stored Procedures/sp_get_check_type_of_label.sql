-- =============================================
-- =============================================
CREATE PROCEDURE [tg].[sp_get_check_type_of_label]
	-- Add the parameters for the stored procedure here
	  @lot_no varchar(10)
	, @qrcode_detail varchar(90)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--declare @lot_no varchar(10) = '2220D5945V'
	--declare @qrcode_detail char(90) = 'BM67290FV-CE2      0020002220D5945V001                                                    '
	DECLARE @pc_instructionCode int = null
	DECLARE @qr_reel INT
	SET @qr_reel = SUBSTRING(@qrcode_detail,37,2);

	SELECT @pc_instructionCode = pc_instruction_code FROM APCSProDB.trans.lots where lot_no = @lot_no

	IF @pc_instructionCode = 13  --Add condition check pc-request work for support disable reel hasuu shipment (date modify : 2024/05/31 time : 08.37 by Aomsin)
	BEGIN
		IF EXISTS(
		SELECT [lot_no]
			, [type_of_label]
			, [no_reel]
		FROM APCSProDB.trans.label_issue_records 
		WHERE [lot_no] = @lot_no
			AND [type_of_label] IN (2,20) 
			AND [no_reel] = @qr_reel
		)
		BEGIN
			SELECT [lot_no]
				, [type_of_label]
				, [no_reel]
			FROM APCSProDB.trans.label_issue_records 
			WHERE [lot_no] = @lot_no
				AND [type_of_label] IN (2,20) 
				AND [no_reel] = @qr_reel;
		END
		ELSE
		BEGIN
			SELECT @lot_no AS [lot_no]
				, '' AS [type_of_label]
				, '' AS [no_reel];
		END
	END
	ELSE
	BEGIN
		IF EXISTS(
		SELECT [lot_no]
			, [type_of_label]
			, [no_reel]
		FROM APCSProDB.trans.label_issue_records 
		WHERE [lot_no] = @lot_no
			AND [type_of_label] IN (1,2,3) 
			AND [no_reel] = @qr_reel
		)
		BEGIN
			SELECT [lot_no]
				, [type_of_label]
				, [no_reel]
			FROM APCSProDB.trans.label_issue_records 
			WHERE [lot_no] = @lot_no
				AND [type_of_label] IN (1,2,3) 
				AND [no_reel] = @qr_reel;
		END
		ELSE
		BEGIN
			SELECT @lot_no AS [lot_no]
				, '' AS [type_of_label]
				, '' AS [no_reel];
		END
	END
END
