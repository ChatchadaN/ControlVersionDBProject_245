-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_scheduler_accumulate_tmp]
	-- Add the parameters for the stored procedure here
	--<@Param1, sysname, @p1> <Datatype_For_Param1, , int> = <Default_Value_For_Param1, , 0>, 
	--<@Param2, sysname, @p2> <Datatype_For_Param2, , int> = <Default_Value_For_Param2, , 0>
	@DeviceName as VARCHAR(50),
	@DeviceFTName as VARCHAR(50),
	@Value as FLOAT,
	@Month as VARCHAR(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	

	IF((select COUNT(DeviceName)
		from DBx.dbo.scheduler_accumulate_tmp
		where DeviceName = @DeviceName and [Month] = @Month) = 0)
	BEGIN
		INSERT INTO DBx.dbo.scheduler_accumulate_tmp (DeviceName,DeviceFTName,AccumulateValue,[Month])
		VALUES (@DeviceName, @DeviceFTName, @Value, @Month);
	END
	ELSE IF((select COUNT(DeviceName)
		from DBx.dbo.scheduler_accumulate_tmp
		where DeviceName = @DeviceName and [Month] = @Month) = 1)
	BEGIN
		UPDATE DBx.dbo.scheduler_accumulate_tmp  SET AccumulateValue = @Value
        WHERE DeviceName = @DeviceName and [Month] = @Month
	END
END
