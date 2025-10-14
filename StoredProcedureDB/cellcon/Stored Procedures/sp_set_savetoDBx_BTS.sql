-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_set_savetoDBx_BTS]
	-- Add the parameters for the stored procedure here
	@dt BTSData readonly
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	MERGE DBx.dbo.BTSData AS T
	USING @dt AS S
	ON T.LotNo = S.LotNo AND T.StartTime = S.StartTime

	WHEN MATCHED THEN
	
		UPDATE SET 
			MCNo				= S.MCNo,
			LotNo				= S.LotNo,
								  
			StartUser			= S.StartUser,
			StartTime			= S.StartTime,
			EndUser				= S.EndUser,
			EndTime				= S.EndTime,
						  
			Input				= S.Input,
			InputAdjust			= S.InputAdjust,
			Good				= S.Good,
			GoodAdjust			= S.GoodAdjust,
			NG					= S.NG,
			NGAdjust			= S.NGAdjust,
			PretestNG			= S.PretestNG,
			PretestNGAdjust		= S.PretestNGAdjust,
			BurnInNG			= S.BurnInNG,
			BurnInNGAdjust		= S.BurnInNGAdjust,
			Remark				= S.Remark

	WHEN NOT MATCHED THEN
		
		INSERT (MCNo, 
				LotNo, 
				StartUser, 
				StartTime, 
				EndUser, 
				EndTime, 
				Input, 
				InputAdjust, 
				Good, 
				GoodAdjust, 
				NG, 
				NGAdjust, 
				PretestNG, 
				PretestNGAdjust, 
				BurnInNG, 
				BurnInNGAdjust, 
				Remark)
		VALUES (S.MCNo, 
			    S.LotNo, 
				S.StartUser, 
				S.StartTime, 
				S.EndUser, 
				S.EndTime, 
				S.Input, 
				S.InputAdjust, 
				S.Good, 
				S.GoodAdjust, 
				S.NG, 
				S.NGAdjust, 
				S.PretestNG, 
				S.PretestNGAdjust, 
				S.BurnInNG, 
				S.BurnInNGAdjust, 
				Remark)
		
	OUTPUT $action AS [Action], INSERTED.*;

END
