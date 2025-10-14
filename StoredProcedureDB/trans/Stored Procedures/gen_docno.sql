-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[gen_docno]
	-- Add the parameters for the stored procedure here
	@type varchar(3),
	@NewDocNo VARCHAR(17) OUTPUT
AS
BEGIN
	DECLARE @FormattedDate VARCHAR(8) = FORMAT(GETDATE(), 'yyyyMMdd');

	-- หาค่าลำดับหมายเลขเอกสารล่าสุดที่สร้างในวันเดียวกัน
	DECLARE @RunningNumber INT;
	SELECT @RunningNumber = [last_number] + 1
	FROM [APCSProDB].[trans].[doc_number]
	WHERE [doc_code] = @type
	AND use_date = FORMAT(GETDATE(), 'yyyy-MM-dd');

	IF (@RunningNumber IS NULL)
		BEGIN
			UPDATE [APCSProDB].[trans].doc_number SET use_date = GETDATE(), [last_number] = 1 WHERE [doc_code] = @type
			SET @RunningNumber = 1
		END
	ELSE 
		BEGIN
			UPDATE [APCSProDB].[trans].doc_number SET use_date = GETDATE(), [last_number] = @RunningNumber WHERE [doc_code] = @type
		END

	-- สร้างหมายเลขเอกสารใหม่
	SET @NewDocNo = @type + '-' +@FormattedDate + '-' + RIGHT('0000' + CAST(@RunningNumber AS VARCHAR(4)), 4);

END
