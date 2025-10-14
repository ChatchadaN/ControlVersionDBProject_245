-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_set_savetoDBx_TR]
	-- Add the parameters for the stored procedure here
	@MCNo varchar(10), 
	@MCType varchar(10), 
	@LotNo varchar(10), 

	@TapeType varchar(10) = NULL, 
	@TapeLot varchar(8) = NULL, 

	@InputQty int,
	@GoodQty int,
	@NGQty int,
	@OPNo varchar(6),

	@LotStartTime datetime, 
	@FirstInspBefore varchar(1) = NULL, 
	@FirstInspAfter varchar(1) = NULL, 
	@FirstInspPn smallint = NULL,

	@LotEndTime datetime = NULL,
	@MechaScrap int = NULL, 
	@DefectMode varchar(1) = NULL,
	@Remark varchar(50) = NULL,
	@CarrierOut varchar(20) = NULL,
	@FinalJudgement varchar(1) = NULL,
	@EndOPNo varchar(6) = NULL
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
		,'EXEC [dbo].[sp_set_savetoDBx_TR] @MCNo = '''+ @MCNo + ''', @LotNo = ''' + @LotNo + ''', @LotStartTime = ' + 
		CONVERT(varchar, @LotStartTime) + ', @LotEndTime = ' + CONVERT(varchar, @LotEndTime) + ''

	IF (SELECT COUNT(1) FROM DBx.dbo.MPTapeRemovingData WHERE LotNo = @LotNo And LotStartTime = @LotStartTime) = 0
	BEGIN
		INSERT INTO DBx.dbo.MPTapeRemovingData
		(MCNo, MCType, LotNo, 
		 TapeType, TapeLotNo, 
		 InputQuality, GoodQuality, NGQuality, OpNo, 
		 LotStartTime, FirstInspBe, FirstInspAf, FirstInspPn, 
		 LotEndTime, MechaScrap, DefectMode, 
		 Remark, ChangeCarrier, LotJudge, EndOPNo)
		SELECT 
		 @MCNo, @MCType, @LotNo, 
		 @TapeType, @TapeLot,
		 @InputQty, @GoodQty, @NGQty, @OPNo, 
		 @LotStartTime, @FirstInspBefore, @FirstInspAfter, @FirstInspPn,
		 @LotEndTime, @MechaScrap, @DefectMode, 
		 @Remark, @CarrierOut, @FinalJudgement, @EndOPNo
	END
	ELSE
	BEGIN
		UPDATE DBx.dbo.MPTapeRemovingData
		SET MCNo		  = @MCNo,
			MCType		  = @MCType,
			LotNo		  = @LotNo,
						  
			TapeType	  = @TapeType,
			TapeLotNo	  = @TapeLot,
						  
			InputQuality  = @InputQty,
			GoodQuality	  = @GoodQty,
			NGQuality	  =	@NGQty,
			OpNo		  = @OPNo,
						  
			LotStartTime  = @LotStartTime,
			FirstInspBe   = @FirstInspBefore,
			FirstInspAf   = @FirstInspAfter,
			FirstInspPn   = @FirstInspPn,
						  
			LotEndTime	  = @LotEndTime,
			MechaScrap	  = @MechaScrap,
			DefectMode	  = @DefectMode,
			Remark		  = @Remark,
			ChangeCarrier = @CarrierOut,
			LotJudge	  = @FinalJudgement,
			EndOPNo		  = @EndOPNo

		WHERE LotNo = @LotNo AND LotStartTime = @LotStartTime
	END
END
