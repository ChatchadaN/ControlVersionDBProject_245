-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_scheduler_setTC]
	-- Add the parameters for the stored procedure here
	  @McNo  VARCHAR(20) 
	, @McId  INT
	, @Sequence  INT
	, @Device_change  VARCHAR(30) 
	, @Device_now  VARCHAR(30) 
	, @Flow_before VARCHAR(10) = NULL
	, @Flow_after VARCHAR(10) = NULL
AS
BEGIN

	IF((select COUNT (mc_id) from [DBx].[dbo].[scheduler_setup] where date_complete is null and mc_id = @McId) = 0)
	BEGIN
		INSERT INTO [DBx].[dbo].[scheduler_setup]
		([mc_no],[mc_id],[sequence],[device_change],[device_now],[date_change],flow_before,flow_after)
		 VALUES( @McNo, @McId, @Sequence, @Device_change, @Device_now , (select GETDATE()),@Flow_before,@Flow_after)
	 END
	 ELSE
	 BEGIN
		UPDATE [DBx].[dbo].[scheduler_setup]
          SET [sequence] = @Sequence 
		  , [device_change] = @Device_change 
		  , [device_now] = @Device_now 
		  , [date_change] = (select GETDATE()) 
		  , flow_before = @Flow_before
		  , flow_after= @Flow_after
        WHERE [mc_no] = @McNo and [mc_id] = @McId and [date_complete] is null
	 END
END
