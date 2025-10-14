-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_PD4_Progress_Plan]
	-- Add the parameters for the stored procedure here
	@PackageName		VARCHAR(15)
	,@ProcessName		VARCHAR(15)
	,@PlanDate			DATE
	,@Plan1				INT
	,@Plan2				INT
	,@Plan4				INT
	,@Plan5				INT
	,@Comment			VARCHAR(200)
	,@MachineDay		SMALLMONEY
	,@MachineNight		SMALLMONEY
	,@LastUserID		VARCHAR(6)
	,@ProgressDelay		INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	
	IF NOT EXISTS 
	(
			SELECT 
					[DBx].[dbo].[FL_DailyReport_Plan].* 
			FROM 
					[DBx].[dbo].[FL_DailyReport_Plan] 
			WHERE 
					[PackageName] = @PackageName 
					AND [ProcessName] = @ProcessName
					AND [PlanDate] = @PlanDate
					AND [Plan1] = @Plan1 
					AND [Plan2] = @Plan2 
					AND [Plan4] = @Plan4 
					AND [Plan5] = @Plan5
					AND [Comment] = @Comment 
					AND [MachineDay] = @MachineDay 
					AND [MachineNight] = @MachineNight
	)
	
	BEGIN
			IF EXISTS 
			(
					SELECT 
							[DBx].[dbo].[FL_DailyReport_Plan].* 
					FROM 
							[DBx].[dbo].[FL_DailyReport_Plan] 
					WHERE 
							[PackageName] = @PackageName
							AND [ProcessName] = @ProcessName
							AND [PlanDate] = @PlanDate
			)
			BEGIN
					UPDATE 
							[DBx].[dbo].[FL_DailyReport_Plan] 
					SET 
							[Plan1] = @Plan1
							,[Plan2] = @Plan2
							,[Plan4] = @Plan4
							,[Plan5] = @Plan5
							,[LastUpdate] = GETDATE()
							,[Comment] = @Comment
							,[MachineDay] = @MachineDay
							,[MachineNight] = @MachineNight
							,[LastUserID] = @LastUserID
					WHERE 
							[PackageName] = @PackageName
							AND [ProcessName] = @ProcessName
							AND [PlanDate] = @PlanDate
			END
                    
			ELSE
			BEGIN
					INSERT INTO 
							[DBx].[dbo].[FL_DailyReport_Plan] 
							(
									[PackageName]
									,[ProcessName]
									,[PlanDate]
									,[Plan1]
									,[Plan2]
									,[Plan4]
									,[Plan5]
									,[LastUpdate]
									,[Comment]
									,[MachineDay]
									,[MachineNight]
									,[LastUserID]
									,[ProgressDelay]
							)
					VALUES 
							(
									@PackageName
									,@ProcessName
									,@PlanDate
									,@Plan1
									,@Plan2
									,@Plan4
									,@Plan5
									,GETDATE()
									,@Comment
									,@MachineDay
									,@MachineNight
									,@LastUserID
									,@ProgressDelay
							)
			END
	END

	BEGIN
			UPDATE 
					[DBx].[dbo].[FL_DailyReport_Plan] 
			SET 
					[ProgressDelay] = @ProgressDelay
			WHERE 
					[PackageName] = @PackageName 
					AND [ProcessName] = @ProcessName
					AND [PlanDate] = @PlanDate
	END

END
