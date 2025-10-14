-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_set_savetoDBx_FT]
	-- Add the parameters for the stored procedure here
	@MCNo varchar(10), 
	@LotNo varchar(10), 
	@MCType varchar(10) = NULL, 

	@LotStartTime datetime, 
	@OPNo varchar(6) = NULL,
	@InputQty int = NULL,
	@TotalGood int = NULL,
	@TotalNG int = NULL,
	@LotStartVisualInspectNGQty smallint = NULL,
	@LotStartVisualInspectTotalQty smallint = NULL,
	@LCL real = NULL,
	@InitialYield real = NULL,
	
	@OPRate real = NULL,
	@MaximumRPM real = NULL,
	@AverageRPM	real = NULL,
	@MTBF real = NULL,
	@MTTR real = NULL,
	@AlarmTotal smallint = NULL,
	@RunTime real = NULL,
	@StopTime real = NULL,
	@AlarmTime real = NULL,	
	@TestTemperature varchar(4) = NULL,
	@HandlerCounterQty int = NULL,
	@TesterACounterQty int = NULL,
	@TesterBCounterQty int = NULL,

	@LotEndTime datetime = NULL,
	@EndOPNo varchar(6) = NULL,
	@LotEndVisualInspectNGQty smallint = NULL,
	@LotEndVisualInspectTotalQty smallint = NULL,
	@FirstEndYield real = NULL,
	@FinalYield real = NULL,
	@MekaNGRate float = NULL,
	@FirstAutoAsiCheck bit = NULL,
	@LotJudgement varchar(20) = NULL,
	@Remark varchar(50) = NULL,
	@GLCheck varchar(6) = NULL,

	@FirstGoodBin1Qty int = NULL,
	@FirstNGQty int = NULL,
	@FirstNGBin17 int = NULL,
	@FirstNGBin19 int = NULL,
	@FirstPassBin19 int = NULL,
	@FirstNGBin27 int = NULL,
	@FirstPassBin27 int = NULL,
	@FirstMeka1Qty int = NULL,
	@FirstMeka2Qty int = NULL,
	@FirstMeka3Qty int = NULL,
	@FirstUnknowQty int = NULL,

	@SecondGoodBin1Qty int = NULL,
	@SecondNGQty int = NULL,
	@SecondNGBin17 int = NULL,
	@SecondNGBin19 int = NULL,
	@SecondPassBin19 int = NULL,
	@SecondNGBin27 int = NULL,
	@SecondPassBin27 int = NULL,
	@SecondMeka4Qty int = NULL,
	@SecondUnknowQty int = NULL,

	@TotalGoodBin1Qty int = NULL,
	@TotalNGQty int = NULL,
	@TotalNGBin17 int = NULL,
	@TotalNGBin19 int = NULL,
	@TotalPassBin19 int = NULL,
	@TotalNGBin27 int = NULL,
	@TotalPassBin27 int = NULL,
	@TotalMeka1Qty int = NULL,
	@TotalMeka2Qty int = NULL,
	@TotalMeka3Qty int = NULL,
	@TotalMeka4Qty int = NULL,
	@TotalUnknowQty int = NULL,

	@ProgramName varchar(20) = NULL,
	@TestFlowName varchar(20) = NULL,
	@TesterType varchar(50) = NULL,
	@ChannelATesterNo varchar(30) = NULL,
	@ChannelBTesterNo varchar(30) = NULL,
	@BoxName varchar(50) = NULL,
	@ChannelATestBoxNo varchar(8) = NULL,
	@ChannelBTestBoxNo varchar(8) = NULL,
	@SocketChange bit = NULL,
	@SocketNumCh1 varchar(50) = NULL,
	@SocketNumCh2 varchar(50) = NULL,
	@SocketNumCh3 varchar(50) = NULL,
	@SocketNumCh4 varchar(50) = NULL,
	@SocketNumCh5 varchar(50) = NULL,
	@SocketNumCh6 varchar(50) = NULL,
	@SocketNumCh7 varchar(50) = NULL,
	@SocketNumCh8 varchar(50) = NULL,

	@TubeorTray int = 0,
	@GoodinTubeorTray int = 0,
	@HassuinTubeorTray int = 0
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	([record_at]
      , [record_class]
      , [login_name]
      , [hostname]
      , [appname]
      , [command_text])
	SELECT GETDATE()
		,'4'
		,ORIGINAL_LOGIN()
		,HOST_NAME()
		,APP_NAME()
		,'EXEC [dbo].[sp_set_savetoDBx_FT] @MCNo = '''+ @MCNo + ''', @LotNo = ''' + @LotNo + ''', @LotStartTime = ' + 
		CONVERT(varchar, @LotStartTime) + ', @LotEndTime = ' + CONVERT(varchar, @LotEndTime) + ''

	IF (SELECT COUNT(1) FROM DBx.dbo.FTData WHERE LotNo = @LotNo And LotStartTime = @LotStartTime) = 0
	BEGIN
		INSERT INTO DBx.dbo.FTData
		(MCNo, LotNo, MCType, 
		 LotStartTime, OPNo, InputQty, TotalGood, TotalNG,

		 OPRate, MaximumRPM, AverageRPM, MTBF, MTTR, AlarmTotal, RunTime, StopTime, AlarmTime,
		 TestTemperature, HandlerCounterQty, TesterACounterQty, TesterBCounterQty,

		 LotEndTime, EndOPNo, FirstGoodBin1Qty, FirstNGQty, Bin17, Bin19, FirstNGBin19PassQty,
		 FirstNGBin27Qty, FirstPassBin27Qty, FirstMeka1Qty, FirstMeka2Qty, FirstMeka3Qty, FirstUnknowQty,

		 SecondGoodBin1Qty, SecondNGQty, SecondBin17, SecondBin19, SecondNGBin19PassQty, 
		 SecondNGBin27Qty, SecondPassBin27Qty, SecondMeka4Qty, SecondUnknowQty,

		 TotalGoodBin1Qty, TotalNGQty, TotalBin17, TotalBin19, TotalNGBin19PassQty, TotalNGBin27Qty, 
		 TotalPassBin27Qty, TotalMeka1Qty, TotalMeka2Qty, TotalMeka3Qty, TotalMeka4Qty, TotalUnknowQty,

		 ProgramName, TestFlowName, 
		 TesterType, ChannelATesterNo, ChannelBTesterNo, 
		 BoxName, ChannelATestBoxNo, ChannelBTestBoxNo, 
		 LotStartVisualInspectNGQty, LotStartVisualInspectTotalQty, 
		 LotEndVisualInspectNGQty, LotEndVisualInspectTotalQty, 
		 LCL, InitialYield, FirstEndYield, FinalYield, MekaNGRate, FirstAutoAsiCheck,

		 SocketChange, LotJudgement, Remark, GLCheck, 
		 SocketNumCh1, SocketNumCh2, SocketNumCh3, SocketNumCh4,
		 SocketNumCh5, SocketNumCh6, SocketNumCh7, SocketNumCh8,
		 
		 TubeorTray, GoodinTubeorTray, HasuuinTubeorTray)

		SELECT 
		 @MCNo, @LotNo, @MCType, 
		 @LotStartTime, @OPNo, @InputQty, @TotalGood, @TotalNG,

		 @OPRate, @MaximumRPM, @AverageRPM, @MTBF, @MTTR, @AlarmTotal, @RunTime, @StopTime, @AlarmTime,
		 @TestTemperature, @HandlerCounterQty, @TesterACounterQty, @TesterBCounterQty,

		 @LotEndTime, @EndOPNo, @FirstGoodBin1Qty, @FirstNGQty, @FirstNGBin17, @FirstNGBin19, @FirstPassBin19,
		 @FirstNGBin27, @FirstPassBin27, @FirstMeka1Qty, @FirstMeka2Qty, @FirstMeka3Qty, @FirstUnknowQty,

		 @SecondGoodBin1Qty, @SecondNGQty, @SecondNGBin17, @SecondNGBin19, @SecondPassBin19,
		 @SecondNGBin27, @SecondPassBin27, @SecondMeka4Qty, @SecondUnknowQty,

		 @TotalGoodBin1Qty, @TotalNGQty, @TotalNGBin17, @TotalNGBin19, @TotalPassBin19, @TotalNGBin27,
		 @TotalPassBin27, @TotalMeka1Qty, @TotalMeka2Qty, @TotalMeka3Qty, @TotalMeka4Qty, @TotalUnknowQty,

		 @ProgramName, @TestFlowName,
		 @TesterType, @ChannelATesterNo, @ChannelBTesterNo,
		 @BoxName, @ChannelATestBoxNo, @ChannelBTestBoxNo,
		 @LotStartVisualInspectNGQty, @LotStartVisualInspectTotalQty,
		 @LotEndVisualInspectNGQty, @LotEndVisualInspectTotalQty,
		 @LCL, @InitialYield, @FirstEndYield, @FinalYield, @MekaNGRate, @FirstAutoAsiCheck,
		 @SocketChange, @LotJudgement, @Remark, @GLCheck,
		 @SocketNumCh1, @SocketNumCh2, @SocketNumCh3, @SocketNumCh4, 
		 @SocketNumCh5, @SocketNumCh6, @SocketNumCh7, @SocketNumCh8,

		 @TubeorTray, @GoodinTubeorTray, @HassuinTubeorTray
	END
	ELSE
	BEGIN
		UPDATE DBx.dbo.FTData
		SET MCNo				= @MCNo, 
		    LotNo				= @LotNo, 
			MCType				= @MCType, 
			LotStartTime		= @LotStartTime, 
			OPNo				= @OPNo, 
			InputQty			= @InputQty,
			TotalGood			= @TotalGood, 
			TotalNG				= @TotalNG,

			OPRate				= @OPRate, 
			MaximumRPM			= @MaximumRPM, 
			AverageRPM			= @AverageRPM, 
			MTBF				= @MTBF, 
			MTTR				= @MTTR, 
			AlarmTotal			= @AlarmTotal, 
			RunTime				= @RunTime, 
			StopTime			= @StopTime, 
			AlarmTime			= @AlarmTime,
			TestTemperature		= @TestTemperature, 
			HandlerCounterQty	= @HandlerCounterQty, 
			TesterACounterQty	= @TesterACounterQty, 
			TesterBCounterQty	= @TesterBCounterQty,

			LotEndTime			= @LotEndTime, 
			EndOPNo				= @EndOPNo, 
			FirstGoodBin1Qty	= @FirstGoodBin1Qty, 
			FirstNGQty			= @FirstNGQty, 
			Bin17				= @FirstNGBin17, 
			Bin19				= @FirstNGBin19, 
			FirstNGBin19PassQty	= @FirstPassBin19,
			FirstNGBin27Qty		= @FirstNGBin27, 
			FirstPassBin27Qty	= @FirstPassBin27, 
			FirstMeka1Qty		= @FirstMeka1Qty, 
			FirstMeka2Qty		= @FirstMeka2Qty, 
			FirstMeka3Qty		= @FirstMeka3Qty, 
			FirstUnknowQty		= @FirstUnknowQty,

			SecondGoodBin1Qty	= @SecondGoodBin1Qty, 
			SecondNGQty			= @SecondNGQty, 
			SecondBin17			= @SecondNGBin17, 
			SecondBin19			= @SecondNGBin19, 
			SecondNGBin19PassQty= @SecondPassBin19, 
			SecondNGBin27Qty	= @SecondNGBin27, 
			SecondPassBin27Qty	= @SecondPassBin27, 
			SecondMeka4Qty		= @SecondMeka4Qty, 
			SecondUnknowQty		= @SecondUnknowQty,

			TotalGoodBin1Qty	= @TotalGoodBin1Qty, 
			TotalNGQty			= @TotalNGQty, 
			TotalBin17			= @TotalNGBin17, 
			TotalBin19			= @TotalNGBin19, 
			TotalNGBin19PassQty	= @TotalPassBin19, 
			TotalNGBin27Qty		= @TotalNGBin27, 
			TotalPassBin27Qty	= @TotalPassBin27, 
			TotalMeka1Qty		= @TotalMeka1Qty, 
			TotalMeka2Qty		= @TotalMeka2Qty, 
			TotalMeka3Qty		= @TotalMeka3Qty, 
			TotalMeka4Qty		= @TotalMeka4Qty, 
			TotalUnknowQty		= @TotalUnknowQty,

			ProgramName			= @ProgramName, 
			TestFlowName		= @TestFlowName, 
			TesterType			= @TesterType, 
			ChannelATesterNo	= @ChannelATesterNo, 
			ChannelBTesterNo	= @ChannelBTesterNo, 
			BoxName				= @BoxName, 
			ChannelATestBoxNo	= @ChannelATestBoxNo, 
			ChannelBTestBoxNo	= @ChannelBTestBoxNo, 
			LotStartVisualInspectNGQty		= @LotStartVisualInspectNGQty, 
			LotStartVisualInspectTotalQty	= @LotStartVisualInspectTotalQty, 
			LotEndVisualInspectNGQty		= @LotEndVisualInspectNGQty, 
			LotEndVisualInspectTotalQty		= @LotEndVisualInspectTotalQty, 
			LCL					= @LCL, 
			InitialYield		= @InitialYield, 
			FirstEndYield		= @FirstEndYield, 
			FinalYield			= @FinalYield,
			MekaNGRate			= @MekaNGRate,
			FirstAutoAsiCheck	= @FirstAutoAsiCheck,

			SocketChange		= @SocketChange, 
			LotJudgement		= @LotJudgement, 
			Remark				= @Remark, 
			GLCheck				= @GLCheck, 
			SocketNumCh1		= @SocketNumCh1, 
			SocketNumCh2		= @SocketNumCh2,
			SocketNumCh3		= @SocketNumCh3, 
			SocketNumCh4		= @SocketNumCh4,
			SocketNumCh5		= @SocketNumCh5, 
			SocketNumCh6		= @SocketNumCh6, 
			SocketNumCh7		= @SocketNumCh7, 
			SocketNumCh8		= @SocketNumCh8,

			TubeorTray			= @TubeorTray,
			GoodinTubeorTray	= @GoodinTubeorTray,
			HasuuinTubeorTray	= @HassuinTubeorTray

		WHERE LotNo = @LotNo AND LotStartTime = @LotStartTime
	END
END
