-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_set_savetoDBx_BIR]
	-- Add the parameters for the stored procedure here
	@MCNo varchar(30), 
	@LotNo varchar(20),
	@StartUser varchar(6)	= NULL, 
	@StartTime datetime		= NULL, 
	@EndUser varchar(6)		= NULL, 
	@EndTime datetime		= NULL, 
	@Input int				= NULL, 
	@InputAdjust int		= NULL, 
	@Good int				= NULL, 
	@GoodAdjust int			= NULL, 
	@RemovingGood int		= NULL, 
	@RemovingGoodAdjust int = NULL, 
	@NG int					= NULL,
	@NGAdjust int			= NULL,
	@InsertingNGTotal int	= NULL, 
	@PretestNGTotal int		= NULL,
	@BurningNGTotal int		= NULL,
	@RemovingNGTotal int	= NULL,
	@TotalNGQty int			= NULL
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
		,'EXEC [dbo].[sp_set_savetoDBx_BIR] @MCNo = '''+ @MCNo + ''', @LotNo = ''' + @LotNo + ''

	IF (SELECT COUNT(1) FROM DBx.dbo.BIRData WHERE LotNo = @LotNo And StartTime = @StartTime) = 0
	BEGIN
		INSERT INTO DBx.dbo.BIRData
		(MCNo,			LotNo,
		 StartUser,		StartTime,
		 EndUser,		EndTime,
		 Input,			InputAdjust, 
		 InsertingGood, InsertingGoodAdjust, 
		 RemovingGood,	RemovingGoodAdjust,
		 InsertingNG,	InsertingNGAdjust,
		 InsertingNGTotal,
		 PretestNGTotal,
		 BurningNGTotal,
		 RemovingNGTotal,
		 TotalNGQty)
		SELECT 
		 @MCNo,			@LotNo,
		 @StartUser,	@StartTime,
		 @EndUser,		@EndTime,
		 @Input,		@InputAdjust,
		 @Good,			@GoodAdjust,
		 @RemovingGood,	@RemovingGoodAdjust,
		 @NG,			@NGAdjust,
		 @InsertingNGTotal,
		 @PretestNGTotal,
		 @BurningNGTotal,
		 @RemovingNGTotal,
		 @TotalNGQty
	END
	ELSE
	BEGIN
		UPDATE DBx.dbo.BIRData
		SET MCNo				= @MCNo,
			LotNo				= @LotNo,

			StartUser			= @StartUser,
			StartTime			= @StartTime,
			EndUser				= @EndUser,
			EndTime				= @EndTime,
			
			Input				= @Input,
			InputAdjust			= @InputAdjust,
			InsertingGood		= @Good,
			InsertingGoodAdjust	= @GoodAdjust,
			RemovingGood		= @RemovingGood,
			RemovingGoodAdjust	= @RemovingGoodAdjust,
			InsertingNG			= @NG,
			InsertingNGAdjust	= @NGAdjust,
			InsertingNGTotal	= @InsertingNGTotal,
			PretestNGTotal		= @PretestNGTotal,
			BurningNGTotal		= @BurningNGTotal,
			RemovingNGTotal		= @RemovingNGTotal,
			TotalNGQty			= @TotalNGQty

		WHERE LotNo = @LotNo And StartTime = @StartTime
	END
END
