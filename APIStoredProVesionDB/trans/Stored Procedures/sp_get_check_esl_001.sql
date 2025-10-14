-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_check_esl_001]
	-- Add the parameters for the stored procedure here
	 @e_slip_id		NVARCHAR(MAX)	= NULL
	,@app_name		NVARCHAR(MAX)	= NULL
	,@op_no			NVARCHAR(MAX)	= NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;	

    -- Insert statements for procedure here
	DECLARE @pettern_esl INT;
	SET @pettern_esl = PATINDEX('[A-Z][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]', UPPER(@e_slip_id));

	IF (@pettern_esl IS NULL)
	BEGIN
		SELECT 'FALSE' AS [Is_Pass]
			, 'Please send parameter @e_slip_id !!' AS [Error_Message_ENG]
			, N'กรุณาส่งค่า @e_slip_id !!' AS [Error_Message_THA]
			, N'ติดต่อ System' AS [Handling];
		RETURN;
	END
	ELSE IF (@pettern_esl = 0)
	BEGIN
		SELECT 'FALSE' AS [Is_Pass]
			, 'Format ESL invalid !!' AS [Error_Message_ENG]
			, N'ESL รูปแบบไม่ถูกต้อง !!' AS [Error_Message_THA]
			, N'กรุณาเช็ค ESL Card' AS [Handling];
		RETURN;
	END

	IF EXISTS(SELECT [e_slip_id] FROM [APCSProDB].[trans].[lots] WHERE [e_slip_id] = @e_slip_id)
	BEGIN
		SELECT 'FALSE' AS [Is_Pass]
			, 'This ESL number is already in user !!' AS [Error_Message_ENG]
			, N'ESL number นี้ถูกใช้งานแล้ว !!' AS [Error_Message_THA]
			, N'กรุณาเช็ค ESL Card' AS [Handling];
		RETURN;
	END
	ELSE
	BEGIN
		SELECT 'TRUE' AS [Is_Pass]
			, '' AS [Error_Message_ENG]
			, N'' AS [Error_Message_THA]
			, N'' AS [Handling];
		RETURN;
	END
END