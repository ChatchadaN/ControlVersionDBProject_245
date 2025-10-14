-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_scheduler_update_mcStatus_ft] 
	-- Add the parameters for the stored procedure here
	@MCNo varchar(30),
	@SetupStatus varchar(30),
	@LotNo varchar(10), 
	@SetupStartDate datetime,
	@SetupEndDate datetime,
	@SetupConfirmDate datetime,

	--@StatusMC VARCHAR(50),
	
	@PackageName varchar(20) = '', @DeviceName varchar(20) = '', @FTDevice varchar(20) = '', 
	@ProgramName varchar(30) = '', @TesterType varchar(30) = '', @JobId int = 0, @JobName varchar(30) = '', @TestFlow varchar(30) = '', @OISRank varchar(30) = '', @OISDevice varchar(20) = '',
	@QRCodesocket1 varchar(30) = '', @QRCodesocketChannel1 varchar(30) = '', 
	@QRCodesocket2 varchar(30) = '', @QRCodesocketChannel2 varchar(30) = '', 
	@QRCodesocket3 varchar(30) = '', @QRCodesocketChannel3 varchar(30) = '', 
	@QRCodesocket4 varchar(30) = '', @QRCodesocketChannel4 varchar(30) = '', 
	@TesterNoA varchar(30) = '', @TesterNoB varchar(30) = '', @TesterNoC varchar(30) = '', @TesterNoD varchar(30) = '',  
	@TesterNoE varchar(30) = '', @TesterNoF varchar(30) = '', @TesterNoG varchar(30) = '', @TesterNoH varchar(30) = '', 
	@TesterNoAQRcode varchar(30) = '', @TesterNoBQRcode varchar(30) = '', @TesterNoCQRcode varchar(30) = '', @TesterNoDQRcode varchar(30) = '',
	@TesterNoEQRcode varchar(30) = '', @TesterNoFQRcode varchar(30) = '', @TesterNoGQRcode varchar(30) = '', @TesterNoHQRcode varchar(30) = '', 
	@TestBoxA varchar(30) = '', @TestBoxB varchar(30) = '', @TestBoxC varchar(30) = '', @TestBoxD varchar(30) = '', 
	@TestBoxE varchar(30) = '', @TestBoxF varchar(30) = '', @TestBoxG varchar(30) = '', @TestBoxH varchar(30) = '', 
	@TestBoxAQRcode varchar(30) = '', @TestBoxBQRcode varchar(30) = '', @TestBoxCQRcode varchar(30) = '', @TestBoxDQRcode varchar(30) = '', 
	@TestBoxEQRcode varchar(30) = '', @TestBoxFQRcode varchar(30) = '', @TestBoxGQRcode varchar(30) = '', @TestBoxHQRcode varchar(30) = '', 
	@ChannelAFTB varchar(30) = '', 
	@ChannelBFTB varchar(30) = '', 
	@ChannelCFTB varchar(30) = '', 
	@ChannelDFTB varchar(30) = '',
	@ChannelEFTB varchar(30) = '', 
	@ChannelFFTB varchar(30) = '',
	@ChannelGFTB varchar(30) = '', 
	@ChannelHFTB varchar(30) = '',
	@AdaptorA varchar(30) = '', @AdaptorAQRcode varchar(30) = '', 
	@AdaptorB varchar(30) = '', @AdaptorBQRcode varchar(30) = '', 
	@DutcardA varchar(30) = '', @DutcardAQRcode varchar(30) = '', 
	@DutcardB varchar(30) = '', @DutcardBQRcode varchar(30) = '',
	@BridgecableA varchar(30) = '', @BridgecableAQRcode varchar(30) = '', 
	@BridgecableB varchar(30) = '', @BridgecableBQRcode varchar(30) = '', 
	@TypeChangePackage varchar(30) = '',
	@BoxTesterConnection varchar(10) = '', @OptionSetup varchar(10) = '', @OptionConnection varchar(10) = '', 
	@OptionName1 varchar(30) = '', @OptionName2 varchar(30) = '', @OptionName3 varchar(30) = '', @OptionName4 varchar(30) = '', @OptionName5 varchar(30) = '', 
	@OptionName6 varchar(30) = '', @OptionName7 varchar(30) = '', @OptionName8 varchar(30) = '', @OptionName9 varchar(30) = '', @OptionName10 varchar(30) = '', 
	@OptionType1 varchar(30) = '', @OptionType1QRcode varchar(30) = '', 
	@OptionType2 varchar(30) = '', @OptionType2QRcode varchar(30) = '', 
	@OptionType3 varchar(30) = '', @OptionType3QRcode varchar(30) = '', 
	@OptionType4 varchar(30) = '', @OptionType4QRcode varchar(30) = '', 
	@OptionType5 varchar(30) = '', @OptionType5QRcode varchar(30) = '', 
	@OptionType6 varchar(30) = '', @OptionType6QRcode varchar(30) = '', 
	@OptionType7 varchar(30) = '', @OptionType7QRcode varchar(30) = '', 
	@OptionType8 varchar(30) = '', @OptionType8QRcode varchar(30) = '', 
	@OptionType9 varchar(30) = '', @OptionType9QRcode varchar(30) = '', 
	@OptionType10 varchar(30) = '', @OptionType10QRcode varchar(30) = '', 
	@OptionSetting1 varchar(30) = '', @OptionSetting2 varchar(30) = '', @OptionSetting3 varchar(30) = '', @OptionSetting4 varchar(30) = '', @OptionSetting5 varchar(30) = '', 
	@OptionSetting6 varchar(30) = '', @OptionSetting7 varchar(30) = '', @OptionSetting8 varchar(30) = '', @OptionSetting9 varchar(30) = '', @OptionSetting10 varchar(30) = '', 
	@QfpVacuumPad varchar(10) = '', @QfpSocketSetup varchar(10) = '', @QfpSocketDecision varchar(10) = '', 
	@QfpDecisionLeadPress varchar(10) = '', @QfpTray varchar(10) = '', 
	@SopStopper varchar(10) = '', @SopSocketDecision varchar(10) = '', @SopDecisionLeadPress varchar(10) = '', 
	@ManualCheckTest int = 0, @ManualCheckTE varchar(10) = '',@ManualCheckRequestTE int = 0, @ManualCheckRequestTEConfirm varchar(10) = '', 
	@PkgGood varchar(10) = '', @PkgNG varchar(10) = '', @PkgGoodJudgement varchar(10) = '', @PkgNGJudgement varchar(10) = '', @PkgNishikiCamara varchar(10) = '',
	@PkgNishikiCamaraJudgement varchar(10) = '', @PkqBantLead varchar(10) = '', @PkqKakeHige varchar(10) = '', @BgaSmallBall varchar(10) = '', @BgaBentTape varchar(10) = '', @Bge5S varchar(10) = '', 
	@ConfirmedCheckSheetOp varchar(15) = '', @ConfirmedCheckSheetSection varchar(15) = '', @ConfirmedCheckSheetGL varchar(15) = '', 
	@ConfirmedShonoSection varchar(15) = '', @ConfirmedShonoGL varchar(15) = '', @ConfirmedShonoOp varchar(15) = '', @StatusShonoOP varchar(5) = 0, @SocketChange int = 0

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @mc_id INT
	SELECT @mc_id = id FROM APCSProDB.mc.machines
	WHERE name = @MCNo

	DECLARE @next_lot_id INT
	SELECT @next_lot_id = next_lot_id FROM APCSProDB.trans.machine_states
	WHERE machine_id = @mc_id

	IF @SetupStatus = 'POWEROFF' --POWER OFF
	BEGIN
		UPDATE DBx.dbo.FTSetupReport 
		SET SetupStatus = @SetupStatus,
			SetupConfirmDate = @SetupConfirmDate
		WHERE MCNo = @MCNo

		UPDATE APCSProDB.trans.machine_states
		SET next_lot_id = NULL
		WHERE machine_id = @mc_id

	END
	ELSE IF @SetupStatus = 'CANCELED' --POWER ON ส่ง 'CANCELED' CLAER DATA Chacksheet
	BEGIN
		UPDATE [DBx].[dbo].[FTSetupReport]
		SET [LotNo]				= @LotNo,
			[PackageName]		= @PackageName,
			[DeviceName]		= @DeviceName,
			[FTDevice]			= @FTDevice,
			[ProgramName]		= @ProgramName,
			[TesterType]		= @TesterType,
			[JobId]				= @JobId,
			[JobName]			= @JobName,
			[TestFlow]			= @TestFlow,
			[OISRank]			= @OISRank,
			[OISDevice]			= @OISDevice,
			[QRCodesocket1]		= @QRCodesocket1,
			[QRCodesocket2]		= @QRCodesocket2,
			[QRCodesocket3]		= @QRCodesocket3,
			[QRCodesocket4]		= @QRCodesocket4,
			[QRCodesocketChannel1]  = @QRCodesocketChannel1,
			[QRCodesocketChannel2]  = @QRCodesocketChannel2,
			[QRCodesocketChannel3]  = @QRCodesocketChannel3,
			[QRCodesocketChannel4]  = @QRCodesocketChannel4,
			[TesterNoA]			= @TesterNoA,
			[TesterNoB]			= @TesterNoB,
			[TesterNoC]			= @TesterNoC,
			[TesterNoD]			= @TesterNoD,
			[TesterNoE]			= @TesterNoE,
			[TesterNoF]			= @TesterNoF,
			[TesterNoG]			= @TesterNoG,
			[TesterNoH]			= @TesterNoH,
			[TesterNoAQRcode]	= @TesterNoAQRcode,
			[TesterNoBQRcode]	= @TesterNoBQRcode,
			[TesterNoCQRcode]	= @TesterNoCQRcode,
			[TesterNoDQRcode]	= @TesterNoDQRcode,
			[TesterNoEQRcode]	= @TesterNoEQRcode,
			[TesterNoFQRcode]	= @TesterNoFQRcode,
			[TesterNoGQRcode]	= @TesterNoGQRcode,
			[TesterNoHQRcode]	= @TesterNoHQRcode,		
			[TestBoxA]			= @TestBoxA,
			[TestBoxB]			= @TestBoxB,
			[TestBoxC]			= @TestBoxC,
			[TestBoxD]			= @TestBoxD,
			[TestBoxE]			= @TestBoxE,
			[TestBoxF]			= @TestBoxF,
			[TestBoxG]			= @TestBoxG,
			[TestBoxH]			= @TestBoxH,
			[TestBoxAQRcode]	= @TestBoxAQRcode,
			[TestBoxBQRcode]	= @TestBoxBQRcode,
			[TestBoxCQRcode]	= @TestBoxCQRcode,
			[TestBoxDQRcode]	= @TestBoxDQRcode,
			[TestBoxEQRcode]	= @TestBoxEQRcode,
			[TestBoxFQRcode]	= @TestBoxFQRcode,
			[TestBoxGQRcode]	= @TestBoxGQRcode,
			[TestBoxHQRcode]	= @TestBoxHQRcode,
			[ChannelAFTB]		= @ChannelAFTB,
			[ChannelBFTB]		= @ChannelBFTB,
			[ChannelCFTB]		= @ChannelCFTB,
			[ChannelDFTB]		= @ChannelDFTB,
			[ChannelEFTB]		= @ChannelEFTB,
			[ChannelFFTB]		= @ChannelFFTB,
			[ChannelGFTB]		= @ChannelGFTB,
			[ChannelHFTB]		= @ChannelHFTB,
			[AdaptorA]			= @AdaptorA,
			[AdaptorB]			= @AdaptorB,
			[AdaptorAQRcode]	= @AdaptorAQRcode,
			[AdaptorBQRcode]	= @AdaptorBQRcode,
			[DutcardA]			= @DutcardA,
			[DutcardB]			= @DutcardB,
			[DutcardAQRcode]	= @DutcardAQRcode,
			[DutcardBQRcode]	= @DutcardBQRcode,
			[BridgecableA]		= @BridgecableA,
			[BridgecableB]		= @BridgecableB,
			[BridgecableAQRcode]	= @BridgecableAQRcode,
			[BridgecableBQRcode]	= @BridgecableBQRcode,
			[TypeChangePackage] = @TypeChangePackage,
			[SetupStartDate]	= @SetupStartDate,
			[SetupEndDate]		= @SetupEndDate,
			[BoxTesterConnection]	= @BoxTesterConnection,
			[OptionSetup]		= @OptionSetup,
			[OptionConnection]	= @OptionConnection,
			[OptionName1]		= @OptionName1,
			[OptionName2]		= @OptionName2,
			[OptionName3]		= @OptionName3,
			[OptionName4]		= @OptionName4,
			[OptionName5]		= @OptionName5,
			[OptionName6]		= @OptionName6,
			[OptionName7]		= @OptionName7,
			[OptionName8]		= @OptionName8,
			[OptionName9]		= @OptionName9,
			[OptionName10]		= @OptionName10,
			[OptionType1]		= @OptionType1,
			[OptionType2]		= @OptionType2,
			[OptionType3]		= @OptionType3,
			[OptionType4]		= @OptionType4,
			[OptionType5]		= @OptionType5,
			[OptionType6]		= @OptionType6,
			[OptionType7]		= @OptionType7,
			[OptionType8]		= @OptionType8,
			[OptionType9]		= @OptionType9,
			[OptionType10]		= @OptionType10,
			[OptionType1QRcode] = @OptionType1QRcode,
			[OptionType2QRcode] = @OptionType2QRcode,
			[OptionType3QRcode] = @OptionType3QRcode,
			[OptionType4QRcode] = @OptionType4QRcode,
			[OptionType5QRcode] = @OptionType5QRcode,
			[OptionType6QRcode] = @OptionType6QRcode,
			[OptionType7QRcode] = @OptionType7QRcode,
			[OptionType8QRcode] = @OptionType8QRcode,
			[OptionType9QRcode] = @OptionType9QRcode,
			[OptionType10QRcode] = @OptionType10QRcode,
			[OptionSetting1]	= @OptionSetting1,
			[OptionSetting2]	= @OptionSetting2,
			[OptionSetting3]	= @OptionSetting3,
			[OptionSetting4]	= @OptionSetting4,
			[OptionSetting5]	= @OptionSetting5,
			[OptionSetting6]	= @OptionSetting6,
			[OptionSetting7]	= @OptionSetting7,
			[OptionSetting8]	= @OptionSetting8,
			[OptionSetting9]	= @OptionSetting9,
			[OptionSetting10]	= @OptionSetting10,
			[QfpVacuumPad]		= @QfpVacuumPad,
			[QfpSocketSetup]	= @QfpSocketSetup,
			[QfpSocketDecision] = @QfpSocketDecision,
			[QfpDecisionLeadPress]	= @QfpDecisionLeadPress,
			[QfpTray]			= @QfpTray,
			[SopStopper]		= @SopStopper,
			[SopSocketDecision] = @SopSocketDecision,
			[SopDecisionLeadPress]	= @SopDecisionLeadPress,
			[ManualCheckTest]	= @ManualCheckTest,
			[ManualCheckTE]		= @ManualCheckTE,
			[ManualCheckRequestTE]	= @ManualCheckRequestTE,
			[ManualCheckRequestTEConfirm]	= @ManualCheckRequestTEConfirm,
			[PkgGood]			= @PkgGood,
			[PkgNG]				= @PkgNG,
			[PkgGoodJudgement]	= @PkgGoodJudgement,
			[PkgNGJudgement]	= @PkgNGJudgement,
			[PkgNishikiCamara]	= @PkgNishikiCamara,
			[PkgNishikiCamaraJudgement]		= @PkgNishikiCamaraJudgement,
			[PkqBantLead]		= @PkqBantLead,
			[PkqKakeHige]		= @PkqKakeHige,
			[BgaSmallBall]		= @BgaSmallBall,
			[BgaBentTape]		= @BgaBentTape,
			[Bge5S]				= @Bge5S,
			[SetupStatus]		= @SetupStatus,
			[ConfirmedCheckSheetOp]			= @ConfirmedCheckSheetOp,
			[ConfirmedCheckSheetSection]	= @ConfirmedCheckSheetSection,
			[ConfirmedCheckSheetGL]			= @ConfirmedCheckSheetGL,
			[ConfirmedShonoSection]			= @ConfirmedShonoSection,
			[ConfirmedShonoGL]	= @ConfirmedShonoGL,
			[ConfirmedShonoOp]	= @ConfirmedShonoOp,
			[StatusShonoOP]		= @StatusShonoOP,
			[SocketChange]		= @SocketChange,
			[SetupConfirmDate]	= @SetupConfirmDate
		WHERE [MCNo] = @MCNo
	END

		INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	(
		[record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no]
	)
	SELECT GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [dbo].[sp_set_scheduler_update_mcStatus_ft] @MCNo = '''+ ISNULL(CAST(@MCNo AS varchar),'NULL') 
		+''', @SetupStatus = '+ ISNULL(CAST(@SetupStatus AS varchar),'NULL') 
		+''', @LotNo = '+ ISNULL(CAST(@LotNo AS varchar),'NULL') 
		+''', @SetupStartDate = '+ ISNULL(CAST(@SetupStartDate AS varchar),'NULL') 
		+''', @SetupEndDate = '+ ISNULL(CAST(@SetupEndDate AS varchar),'NULL') 
		+''', @SetupConfirmDate = '+ ISNULL(CAST(@SetupConfirmDate AS varchar),'NULL')
		+''', @next_lot_id = '+ ISNULL(CAST(@next_lot_id AS varchar),'NULL') + ''	
		, ISNULL(CAST(@LotNo AS varchar),'NULL');

END
