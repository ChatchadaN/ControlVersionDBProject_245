-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_get_insp_ng_mode]
	-- Add the parameters for the stored procedure here
	--<@Param1, sysname, @p1> <Datatype_For_Param1, , int> = <Default_Value_For_Param1, , 0>, 
	--<@Param2, sysname, @p2> <Datatype_For_Param2, , int> = <Default_Value_For_Param2, , 0>
	
	@process_name VARCHAR(30), --ShortName
	@mc_type VARCHAR(30) = '',
	@type int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF(@type = 0)
		BEGIN
		select -- ng_mode
			APCSProDB.trans.abnormal_detail.[name] as item_ng,--เปลี่ยนชื่อก้อน andon เป็น item ng
			APCSProDB.trans.abnormal_detail.[id] as id_item,
			models.[name] as mc_type_name,
			models.[name] as process_name, 
			machine_trc_settings.is_default as is_default,
			null as 'type',
			machine_trc_settings.is_item_before as is_item_before,
			'WB27' as code
			from APCSProDB.trans.machine_trc_settings 
			inner join APCSProDB.mc.models on models.id = machine_trc_settings.machine_model_id
			inner join APCSProDB.trans.abnormal_detail on abnormal_detail.id = machine_trc_settings.abnormal_detail_id
			where models.[name] = @mc_type and machine_trc_settings.is_disable = 0
			--SELECT * 
			--FROM DBx.INS.InspNgMode as inspNG
			--WHERE inspNG.process_name = @process_name AND inspNG.mc_type_name = @mc_type 
		END
	ELSE
		BEGIN
		select -- request_mode
			APCSProDB.trans.abnormal_detail.[name] as item_ng,
			models.[name] as mc_type_name,
			models.[name] as process_name,
			machine_trc_settings.is_default as is_default,
			null as 'type',
			machine_trc_settings.is_item_before as is_item_before,
			'WB27' as code
			from APCSProDB.trans.machine_trc_settings 
			inner join APCSProDB.mc.models on models.id = machine_trc_settings.machine_model_id
			inner join APCSProDB.trans.abnormal_detail on abnormal_detail.id = machine_trc_settings.abnormal_detail_id
			where models.[name] = @mc_type AND machine_trc_settings.is_item_before = 0 and machine_trc_settings.is_disable = 0
			--SELECT * 
			--FROM DBx.INS.InspNgMode as inspNG
			--WHERE inspNG.process_name = @process_name AND inspNG.mc_type_name = @mc_type AND inspNG.is_item_before = 0
		END

END
