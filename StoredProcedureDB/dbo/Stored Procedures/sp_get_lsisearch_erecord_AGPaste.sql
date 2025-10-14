-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_lsisearch_erecord_AGPaste]
	-- Add the parameters for the stored procedure here
	@Mc_No VARCHAR(50) = NULL
	, @AGPasteType VARCHAR(50) = NULL
	, @start_time DATETIME = ''
	, @end_time DATETIME = ''

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


    -- Insert statements for procedure here
	BEGIN		
		SELECT [MixMCNo]
			,[Date]
			,[AGPasteType]
			,[AGPasteLotNo]
			,[QRCode]
			,[RPMMixing]
			,[OPNoStart]
			,[StartTimeMix]
			,[FinishTimeMix]
			,[TotalTime]
			,[OPNoEnd]
			,[EndLot]
			,[InputMc]
			,[Remark]
		FROM [DBx].[MAT].[MixAGPaste]
		WHERE [Date] BETWEEN @start_time AND @end_time
		AND (@Mc_No IS NULL OR [MixMCNo] = @Mc_No)
		AND (@AGPasteType IS NULL OR [AGPasteType] = @AGPasteType)
		ORDER BY [Date],[MixMCNo]
	END
END