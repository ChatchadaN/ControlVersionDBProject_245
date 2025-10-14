-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_get_MC_Alarm_message] 
	-- Add the parameters for the stored procedure here
	--<@Param1, sysname, @p1> <Datatype_For_Param1, , int> = <Default_Value_For_Param1, , 0>, 
	--<@Param2, sysname, @p2> <Datatype_For_Param2, , int> = <Default_Value_For_Param2, , 0>
	@mcmodel VARCHAR(30) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	SELECT  Mcmodels.name as mctype , alarms.alarm_code,texts.alarm_text ,alarms.alarm_level,alarms.id as model_alarm_id
	FROM APCSProDB.mc.model_alarms as alarms
	INNER JOIN APCSProDB.mc.models as Mcmodels on alarms.machine_model_id = Mcmodels.id
	INNER JOIN APCSProDB.mc.alarm_texts as texts on alarms.alarm_text_id = texts.alarm_text_id 
	WHERE Mcmodels.name = @mcmodel and alarms.is_disabled = 0
END
