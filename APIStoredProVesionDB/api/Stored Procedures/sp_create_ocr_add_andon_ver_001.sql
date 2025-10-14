-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_create_ocr_add_andon_ver_001]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@lot_no varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @process_id INT;
	DECLARE @machine_id INT;

	SELECT @process_id = [lots].[act_process_id]
	, @machine_id = [lots].[machine_id]
	FROM [APCSProDB].[trans].[lots]
	WHERE [lots].[lot_no] = @lot_no

	UPDATE [APCSProDB].[trans].[lots]
	SET [quality_state] = 1
	WHERE [lot_no] = @lot_no
	AND [quality_state] = 10

	EXEC [APIStoredProDB].[api].[sp_create_andon_add_record]
		@username = @username
		,	@lot_no = @lot_no
		,	@process_id = @process_id
		,	@machine_id = @machine_id
		,	@comment_id = 622
		,	@line_no = 'OCR Auto Andon'
		,	@equipment_no = 'OCR Auto Andon'
END
