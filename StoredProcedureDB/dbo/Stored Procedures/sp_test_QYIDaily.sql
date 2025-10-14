-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_test_QYIDaily]
	-- Add the parameters for the stored procedure here
	@DateIn DATETIME
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	DECLARE @i INT
	DECLARE @iRow INT
	DECLARE @iDate datetime
	DECLARE @iID INT
	DECLARE @iRowNumber INT
	DECLARE @Device VARCHAR(100)
	DECLARE @DeviceName VARCHAR(100)
	DECLARE @LCL decimal(18, 2)
	DECLARE @UpdateTime datetime


	DECLARE @x datetime = convert(datetime,convert(varchar(10), @DateIn-1, 120)+ ' 08:00:00')
	DECLARE @y datetime = convert(datetime,convert(varchar(10), @DateIn, 120)+ ' 07:59:59')
	DECLARE @z1 datetime = convert(datetime,convert(varchar(10), @DateIn, 120)+ ' 08:00:00')
	DECLARE @z2 datetime = convert(datetime,convert(varchar(10), @DateIn+1, 120)+ ' 07:59:59')


	-- Set Variable
	SET @i = 1
	SET @iRow = 7

	--SET 
	SELECT @iDate = CONVERT(varchar(8), TimeIn,105) 
FROM [DBx].[QYI].[QYICase],[DBx].[QYI].[QYILowYield],[DBx].[dbo].[MyUser]
WHERE  QYICase.No= QYILowYield.No And QYICase.UserIDIn=MyUser.ID
And (QYICase.Mode ='LCL'  Or QYICase.Mode ='Yield < 80 %') and DATEPART(ww,TimeIn) = DATEPART(ww,@DateIn)
GRoup By CONVERT(varchar(8), TimeIn,105)

    -- Insert statements for procedure here
	

END
