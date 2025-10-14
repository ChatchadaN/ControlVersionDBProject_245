-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [if].[sp_set_data_interface_receive_chipbank]
	-- Add the parameters for the stored procedure here
	@type_table INT ---1: CHIPORDER, 2: CHIPSAGYO
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	-- Insert statements for procedure here
	IF (@type_table = 1) ---1: CHIPORDER
	BEGIN
		IF EXISTS(SELECT TOP 1 [ORDERNO] FROM [APCSProDB].[dbo].[CHIPORDER_TEMP])
		BEGIN
			MERGE [APCSProDB].[dbo].[CHIPORDER] AS [c]
			USING [APCSProDB].[dbo].[CHIPORDER_TEMP] AS [ctemp] ON ( 
				[c].[ORDERNO] = [ctemp].[ORDERNO] 
				AND [c].[WFLOTNO] = [ctemp].[WFLOTNO]
				AND [c].[SEQNO] = [ctemp].[SEQNO]
				AND [c].[WFNOFROM] = [ctemp].[WFNOFROM]
				AND [c].[WFNOTO] = [ctemp].[WFNOTO]
			)
			WHEN MATCHED AND [c].[WFCOUNT] != [ctemp].[WFCOUNT]
				OR [c].[CHIPCOUNT] != [ctemp].[CHIPCOUNT]
				OR [c].[TIDATE] != [ctemp].[TIDATE]
				OR [c].[ALOCDATE] != [ctemp].[ALOCDATE]
				OR [c].[CHIPSIZEX] != [ctemp].[CHIPSIZEX]
				OR [c].[CHIPSIZEY] != [ctemp].[CHIPSIZEY]
				THEN UPDATE SET [c].[WFCOUNT] = [ctemp].[WFCOUNT]
					, [c].[CHIPCOUNT] = [ctemp].[CHIPCOUNT]
					, [c].[TIDATE] = [ctemp].[TIDATE]
					, [c].[ALOCDATE] = [ctemp].[ALOCDATE]
					, [c].[CHIPSIZEX] = [ctemp].[CHIPSIZEX]
					, [c].[CHIPSIZEY] = [ctemp].[CHIPSIZEY]
					, [c].[TIMESTAMP] = GETDATE()
			WHEN NOT MATCHED BY TARGET 
				THEN INSERT ( [ORDERNO]
				  , [ROHMMODELNAME]
				  , [CHIPMODELNAME]
				  , [WFLOTNO]
				  , [SEQNO]
				  , [WFCOUNT]
				  , [CHIPCOUNT]
				  , [WFNOFROM]
				  , [WFNOTO]
				  , [RCVDIV]
				  , [TYPENAME]
				  , [ASSYNAME]
				  , [PROCESSCLASS]
				  , [USERCODE]
				  , [TIDATE]
				  , [ALOCDATE]
				  , [DUPLEXFLAG]
				  , [RECORDNO]
				  , [OUTCLASS]
				  , [OUTDIV]
				  , [BOXNO]
				  , [DC]
				  , [CUTCLASS]
				  , [WFCOUNT1]
				  , [CHIPCOUNT1]
				  , [WFCOUNT2]
				  , [CHIPCOUNT2]
				  , [WFCOUNT3]
				  , [CHIPCOUNT3]
				  , [WFCOUNT4]
				  , [CHIPCOUNT4]
				  , [CHIPSIZE]
				  , [CHIPSIZEX]
				  , [CHIPSIZEY]
				  , [TIMESTAMP]
				)
				VALUES ( [ctemp].[ORDERNO]
				  , [ctemp].[ROHMMODELNAME]
				  , [ctemp].[CHIPMODELNAME]
				  , [ctemp].[WFLOTNO]
				  , [ctemp].[SEQNO]
				  , [ctemp].[WFCOUNT]
				  , [ctemp].[CHIPCOUNT]
				  , [ctemp].[WFNOFROM]
				  , [ctemp].[WFNOTO]
				  , [ctemp].[RCVDIV]
				  , [ctemp].[TYPENAME]
				  , [ctemp].[ASSYNAME]
				  , [ctemp].[PROCESSCLASS]
				  , [ctemp].[USERCODE]
				  , [ctemp].[TIDATE]
				  , [ctemp].[ALOCDATE]
				  , [ctemp].[DUPLEXFLAG]
				  , [ctemp].[RECORDNO]
				  , [ctemp].[OUTCLASS]
				  , [ctemp].[OUTDIV]
				  , [ctemp].[BOXNO]
				  , [ctemp].[DC]
				  , [ctemp].[CUTCLASS]
				  , [ctemp].[WFCOUNT1]
				  , [ctemp].[CHIPCOUNT1]
				  , [ctemp].[WFCOUNT2]
				  , [ctemp].[CHIPCOUNT2]
				  , [ctemp].[WFCOUNT3]
				  , [ctemp].[CHIPCOUNT3]
				  , [ctemp].[WFCOUNT4]
				  , [ctemp].[CHIPCOUNT4]
				  , [ctemp].[CHIPSIZE]
				  , [ctemp].[CHIPSIZEX]
				  , [ctemp].[CHIPSIZEY]
				  , GETDATE()
				);
			RETURN;
		END
		ELSE
		BEGIN
			RETURN;
		END
	END
	ELSE IF (@type_table = 2) ---2: CHIPSAGYO
	BEGIN
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
END