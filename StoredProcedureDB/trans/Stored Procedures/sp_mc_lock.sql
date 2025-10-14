-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_mc_lock]
	/* Input Parameters */
	@lock_condition varchar(10)
	,@mc_id int
	--,@lock_id int
	,@system_name varchar(30)
	,@control_num_param_1 int
	,@control_char_param_1 varchar(30)
	,@locked_by_id int
	,@released_by_id int

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @SQLQuery AS NVARCHAR(4000)
	DECLARE @ParamDefinition AS NVARCHAR(2000)
	,@qc_state int
	,@record_class tinyint
	,@stop_control_id int
	,@is_locked tinyint
	,@locked_at datetime
	,@released_at datetime
	,@CHKCNT int

	SET @locked_at = getdate()
	SET @released_at = @locked_at

	BEGIN TRY
		IF @lock_condition IS NULL OR (@lock_condition <> 'HAPPENED' AND @lock_condition <> 'RECOVERY')
		BEGIN
			SELECT 'FALSE' AS Is_Pass ,'Lock condition ERROR !! ' AS Error_Message_ENG,N'เงื่อนไขการล็อคไม่ถูกต้อง !!' AS Error_Message_THA, N' กรุณาติดต่อ System' AS Handling
				RETURN
		END

		IF @lock_condition IS NOT NULL AND @lock_condition = 'HAPPENED'
		BEGIN		
			SET @qc_state = 1
			SET @is_locked = 1
			SET @record_class = 1		

			-- Insert statements for procedure here
			UPDATE [APCSProDB].[trans].[machine_states] SET [APCSProDB].[trans].[machine_states].[qc_state] = @qc_state WHERE [APCSProDB].[trans].[machine_states].[machine_id] = @mc_id 
			--AND [APCSProDB].[trans].[machine_states].[qc_state] = 0

			SELECT @stop_control_id = id FROM [APCSProDB].[trans].[machine_lock_controls] WHERE [machine_id] = @mc_id AND [system_name] = @system_name
		
		

			IF @stop_control_id IS NOT NULL
			BEGIN
				UPDATE [APCSProDB].[trans].[machine_lock_controls] SET [is_locked] = @is_locked, [locked_at] = @locked_at, [released_at] = NULL, [released_by] = NULL WHERE [id] = @stop_control_id
			END
			ELSE
			BEGIN
				INSERT INTO [APCSProDB].[trans].[machine_lock_controls] ([machine_id],[system_name],[control_num_param_1],[control_chr_param_1],[is_locked],[locked_at],[locked_by])
				VALUES (@mc_id,@system_name,@control_num_param_1,@control_char_param_1,@is_locked,@locked_at,@locked_by_id)

				SELECT @stop_control_id = [id] FROM [APCSProDB].[trans].[machine_lock_controls] WHERE [machine_id] = @mc_id AND [system_name] = @system_name
			END
		
			IF @stop_control_id IS NULL
			BEGIN
				SELECT 'FALSE' AS Is_Pass ,'Machine_lock_controls id is null !! ' AS Error_Message_ENG,N'ไม่พบ id ใน machine_lock_controls !!' AS Error_Message_THA, N' กรุณาติดต่อ System' AS Handling
					RETURN
			END

			INSERT INTO [APCSProDB].[trans].[machine_lock_control_records] ([record_class],[stop_control_id],[machine_id],[system_name],[control_num_param_1],[control_char_param_1],[is_locked],[locked_at],[locked_by])
			VALUES (@record_class,@stop_control_id,@mc_id,@system_name,@control_num_param_1,@control_char_param_1,@is_locked,@locked_at,@locked_by_id)

			SELECT 'TRUE' AS Is_Pass ,'Lock machine success !! ' AS Error_Message_ENG,N'Lock machine เรียบร้อย !!' AS Error_Message_THA
			RETURN
		END



		IF @lock_condition IS NOT NULL AND @lock_condition = 'RECOVERY'
		BEGIN
			SET @qc_state = 0
			SET @is_locked = 0
			SET @record_class = 2
			SET @CHKCNT = -1
		
			-- Insert statements for procedure here
			SELECT @stop_control_id = [id], @locked_at = [locked_at], @locked_by_id = [locked_by] FROM [APCSProDB].[trans].[machine_lock_controls] WHERE [machine_id] = @mc_id AND [system_name] = @system_name

			IF @stop_control_id IS NOT NULL
			BEGIN
				SELECT @CHKCNT = (COUNT ([APCSProDB].[trans].[machine_lock_control_records].[record_class])) FROM [APCSProDB].[trans].[machine_lock_control_records] WHERE machine_id = @mc_id AND stop_control_id = @stop_control_id AND locked_at = @locked_at AND record_class = 2

				INSERT INTO [APCSProDB].[trans].[machine_lock_control_records] ([record_class],[stop_control_id],[machine_id],[system_name],[control_num_param_1],[control_char_param_1],[is_locked],[locked_at],[locked_by],[released_at],[released_by])
				VALUES (@record_class,@stop_control_id,@mc_id,@system_name,@control_num_param_1,@control_char_param_1,@is_locked,@locked_at,@locked_by_id,@released_at,@released_by_id)
								
				IF @CHKCNT = 0
				BEGIN
					UPDATE [APCSProDB].[trans].[machine_lock_controls] SET [is_locked] = @is_locked, [released_at] = @released_at, [released_by] = @released_by_id WHERE [machine_id] = @mc_id AND [id] = @stop_control_id

					IF  (SELECT COUNT([id]) FROM [APCSProDB].[trans].[machine_lock_controls] WHERE [machine_id] = @mc_id AND [is_locked] = 1) = 0
					BEGIN
						UPDATE [APCSProDB].[trans].[machine_states] SET [qc_state] = @qc_state WHERE [machine_id] = @mc_id
					END
					
					SELECT 'TRUE' AS Is_Pass ,'Release machine success !! ' AS Error_Message_ENG,N'Release machine เรียบร้อย !!' AS Error_Message_THA
					RETURN
				END
				ELSE
				BEGIN
					SELECT 'TRUE' AS Is_Pass ,'Release event success !! ' AS Error_Message_ENG,N'Release เรียบร้อย !!' AS Error_Message_THA
					RETURN
				END
			END
			ELSE
			BEGIN
				SELECT 'FALSE' AS Is_Pass ,'Machine_lock_controls release id is null !! ' AS Error_Message_ENG,N'ไม่พบ release id ใน machine_lock_controls !!' AS Error_Message_THA, N' กรุณาติดต่อ System' AS Handling
				RETURN
			END
		END
	END TRY
	BEGIN CATCH
		SELECT 'FALSE' AS Is_Pass ,'Store procedure catch error !! ' AS Error_Message_ENG,N'เกิดข้อผิดพลาดระหว่างดำเนินการ !!' AS Error_Message_THA, N' กรุณาติดต่อ System' AS Handling
		RETURN
	END CATCH

--IF @@ERROR <> 0
--	GOTO ErrorHandler

--SET NOCOUNT OFF

--RETURN (0)

--ErrorHandler:

--RETURN (@@ERROR)

END
