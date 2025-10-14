-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[bm_get_status]
	-- Add the parameters for the stored procedure here
	 @mc varchar(20) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT ID,StatusID,Requestor,Inchanger,TimeRequest,TimeStart As ActionTime,TimeFinish As ClearTime,LotNo
	 ,CASE WHEN Problem Is NULL AND CategoryID = 16    THEN  'Pull / Shear'
	  WHEN Problem IS NOT NULL THEN  Problem
	  END AS Problem

	FROM [DBx].[dbo].[BMMaintenance] INNER JOIN [DBx].[dbo].[BMPM6Detail] ON [BMMaintenance].[ID] = [BMPM6Detail].[BM_ID]
	WHERE MachineID=@mc and StatusID not in(3,5,10) and  LotNo  not in ('')
END
