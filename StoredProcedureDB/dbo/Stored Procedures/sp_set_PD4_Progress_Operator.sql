-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_PD4_Progress_Operator]
	-- Add the parameters for the stored procedure here
	@PlanDate			DATE
    ,@ProcessName		VARCHAR(15)
    ,@Floor				VARCHAR(2)
    ,@Shift				CHAR(1)
    ,@GroupShift		CHAR(1)
    ,@PlanOP			INT
    ,@Actual			INT
    ,@OverTime			INT
    ,@Leave				INT
    ,@Absence			INT
    ,@Holiday			INT
    ,@LastUserID		VARCHAR(6)
    ,@Comment			VARCHAR(100)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF NOT EXISTS 
	(		SELECT 
					[DBx].[dbo].[FL_DailyReport_Operator].* 
	
			FROM 
					[DBx].[dbo].[FL_DailyReport_Operator] 
					
			WHERE 
					[PlanDate] = @PlanDate AND 
					[ProcessName] = @ProcessName AND 
					[Floor] = @Floor AND
					[Shift] = @Shift AND 
					[GroupShift] = @GroupShift AND 
					[PlanOP] = @PlanOP AND
					[Actual] = @Actual AND 
					[OverTime] = @OverTime AND 
					[Leave] = @Leave AND 
					[Absence] = @Absence AND
					[Holiday] = @Holiday AND
					[Comment] = @Comment
	)
	
	BEGIN
			IF NOT EXISTS 
			(
					SELECT 
							[DBx].[dbo].[FL_DailyReport_Operator].* 
					FROM 
							[DBx].[dbo].[FL_DailyReport_Operator] 
					WHERE 
							[PlanDate] = @PlanDate AND [ProcessName] = @ProcessName AND [Floor] = @Floor AND [Shift] = @Shift
			)
			BEGIN 
					INSERT INTO 
							[DBx].[dbo].[FL_DailyReport_Operator] 
							(
									[PlanDate],[ProcessName],[Floor],[Shift],[GroupShift],[PlanOP],[Actual],[OverTime],[Leave],[Absence],[Holiday],[LastUserID],[LastUpdate],[Comment]
							)
					VALUES 
							(
									@PlanDate,@ProcessName,@Floor,@Shift,@GroupShift,@PlanOP,@Actual,@OverTime,@Leave,@Absence,@Holiday,@LastUserID,GETDATE(),@Comment
							)
			END

			ELSE
			BEGIN
					UPDATE 
							[DBx].[dbo].[FL_DailyReport_Operator] 
					SET 
							[GroupShift] = @GroupShift,[PlanOP] = @PlanOP,[Actual] = @Actual,[OverTime] = @OverTime,[Leave] = @Leave,[Absence] = @Absence,[Holiday] = @Holiday,[LastUserID] = @LastUserID,[LastUpdate] = GETDATE(),[Comment] = @Comment
					WHERE 
							[PlanDate] = @PlanDate AND [ProcessName] = @ProcessName AND [Floor] = @Floor AND [Shift] = @Shift
			END
	END 
END
