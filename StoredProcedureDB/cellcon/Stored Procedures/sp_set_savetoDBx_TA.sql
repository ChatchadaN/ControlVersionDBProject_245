-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_set_savetoDBx_TA]
	-- Add the parameters for the stored procedure here
	@MCNo varchar(10), 
	@MCType varchar(10), 
	@LotNo varchar(10), 

	@SurfaceBefore varchar(2) = NULL, 
	@SurfaceAfter varchar(2) = NULL, 
	@TapeType varchar(10) = NULL, 
	@TapeLot varchar(14) = NULL, 
	@TapeExpire datetime,

	@InputQty int, 
	@NGQty int,
	@OPNo varchar(6),

	@LotStartTime datetime, 
	@FirstInspBefore varchar(1) = NULL, 
	@FirstInspAfter varchar(1) = NULL, 
	@FirstInspPn smallint = NULL,

	@LotEndTime datetime = NULL,
	@CutterTime smallint = NULL, 
	@FailParts varchar(5) = NULL, 
	@MechaScrap int = NULL, 
	@DefectMode varchar(1) = NULL,
	@Remark varchar(50) = NULL,
	@FinalInspPn smallint = NULL, 
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
		,'EXEC [dbo].[sp_set_savetoDBx_TA] @MCNo = '''+ @MCNo + ''', @LotNo = ''' + @LotNo + ''', @LotStartTime = ' + 
		CONVERT(varchar, @LotStartTime) + ', @LotEndTime = ' + CONVERT(varchar, @LotEndTime) + ''

	IF (SELECT COUNT(1) FROM DBx.dbo.MTapeData WHERE LotNo = @LotNo And LotStartTime = @LotStartTime) = 0
	BEGIN
		INSERT INTO DBx.dbo.MTapeData
		(MCNo, MCType, LotNo, 
		 SurfaceBe, SurfaceAf, TapeType, TapeLot, TapeExpired, 
		 InputQty, NGQty, OpNo, 
		 LotStartTime, FirstInspBe, FirstInspAf, FirstInspPn, 
		 LotEndTime, CutterTime, FailParts, MechaScrap, DefectMode, 
		 Remark, FinalInspPn, FinalJudge, EndOPNo)
		SELECT 
		 @MCNo, @MCType, @LotNo, 
		 @SurfaceBefore, @SurfaceAfter, @TapeType, @TapeLot, @TapeExpire, 
		 @InputQty, @NGQty, @OPNo, 
		 @LotStartTime, @FirstInspBefore, @FirstInspAfter, @FirstInspPn,
		 @LotEndTime, @CutterTime, @FailParts, @MechaScrap, @DefectMode, 
		 @Remark, @FinalInspPn, @FinalJudgement, @EndOPNo
	END
	ELSE
	BEGIN
		UPDATE DBx.dbo.MTapeData
		SET MCNo		= @MCNo,
			MCType		= @MCType,
			LotNo		= @LotNo,

			SurfaceBe	= @SurfaceBefore,
			SurfaceAf	= @SurfaceAfter,
			TapeType	= @TapeType,
			TapeLot		= @TapeLot,
			TapeExpired = @TapeExpire,

			InputQty	= @InputQty,
			NGQty		= @NGQty,
			OpNo		= @OPNo,

			LotStartTime= @LotStartTime,
			FirstInspBe = @FirstInspBefore,
			FirstInspAf = @FirstInspAfter,
			FirstInspPn = @FirstInspPn,

			LotEndTime	= @LotEndTime,
			CutterTime	= @CutterTime,
			FailParts	= @FailParts,
			MechaScrap	= @MechaScrap,
			DefectMode	= @DefectMode,
			Remark		= @Remark,
			FinalInspPn = @FinalInspPn,
			FinalJudge	= @FinalJudgement,
			EndOPNo		= @EndOPNo

		WHERE LotNo = @LotNo AND LotStartTime = @LotStartTime
	END
END
