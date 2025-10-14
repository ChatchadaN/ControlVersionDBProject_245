-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [if].[sp_set_chipsagyo_new_ver]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- Insert statements for procedure here

	IF EXISTS(SELECT TOP 1 [WFLOTNO] FROM [APCSProDB].[dbo].[CHIPSAGYO_TEMP])
	BEGIN
		INSERT INTO [APCSProDB].[dbo].[CHIPSAGYO]
			( [CHIPMODELNAME]
			, [WFLOTNO]
			, [SEQNO]
			, [WFCOUNT]
			, [CHIPCOUNT]
			, [RCVDIV]
			, [PICKDATE]
			, [UPDATEDATE]
			, [TIMESTAMP] )
		SELECT 
			[CHIPMODELNAME]
			, [WFLOTNO]
			, [SEQNO]
			, [WFCOUNT]
			, [CHIPCOUNT]
			, [RCVDIV]
			, [PICKDATE]
			, [UPDATEDATE]
			, [TIMESTAMP]
		FROM [APCSProDB].[dbo].[CHIPSAGYO_TEMP];
		RETURN;
	END
	ELSE
	BEGIN
		RETURN;
	END
END
