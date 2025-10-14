-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_check_auto_andon_of_ocr] 
	-- Add the parameters for the stored procedure here
	@LotNo VARCHAR(10) 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	IF EXISTS (
		SELECT [lots].[lot_no]
			, [ProblemsTransaction].[Status]
			, [lot_hold_controls].[is_held]
			, [andon_controls].[is_solved]
			, [lots].[wip_state]
		FROM [DBx].[dbo].[ProblemsTransaction]
		INNER JOIN [APCSProDB].[trans].[lots] ON [lots].[lot_no] = [ProblemsTransaction].[LotNo]
		INNER JOIN [APCSProDB].[trans].[andon_controls] ON [andon_controls].[id] = [ProblemsTransaction].[TransactionID]
		INNER JOIN [APCSProDB].[trans].[abnormal_detail] ON [abnormal_detail].[id] = [andon_controls].[comment_id_at_finding]
		INNER JOIN [APCSProDB].[trans].[abnormal_mode] ON [abnormal_mode].[id] = [abnormal_detail].[abnormal_mode_id]
		INNER JOIN [APCSProDB].[trans].[lot_hold_controls] ON [lots].[id] = [lot_hold_controls].[lot_id]
			AND [lot_hold_controls].[system_name] = 'andon'
		WHERE [lots].[lot_no] = @LotNo
			AND [ProblemsTransaction].[Status] = 0
			AND [lot_hold_controls].[is_held] = 1
			AND [andon_controls].[is_solved] IS NULL
			AND [abnormal_detail].[name] = 'OCR NG'
	)
	BEGIN
		----# andon success
		SELECT 'TRUE' AS [result];
	END
	ELSE
	BEGIN
		----# not andon
		SELECT 'FALSE' AS [result];
	END
END
