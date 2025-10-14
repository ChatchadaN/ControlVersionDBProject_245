-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_pl_alarm_table]
	-- Add the parameters for the stored procedure here
	@mctype varchar(20),@alarm_no varchar(20) = '0'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	--SELECT     ID, MachineType, AlarmNo,AlarmType,AlarmMessage
	--FROM    dbx.dbo.PLAlarmTable
	--where (MachineType = @mctype)
	--order by id asc
	if (@alarm_no != '0')
	begin 
		SELECT     ID, MachineType, AlarmNo,AlarmType,AlarmMessage
		FROM    dbx.dbo.PLAlarmTable
		where (MachineType = @mctype) AND AlarmNo = @alarm_no
		order by id asc
	end 
	else 
	begin
		SELECT     ID, MachineType, AlarmNo,AlarmType,AlarmMessage
		FROM    dbx.dbo.PLAlarmTable
		where (MachineType = @mctype)
		order by id asc
	end

	
END
