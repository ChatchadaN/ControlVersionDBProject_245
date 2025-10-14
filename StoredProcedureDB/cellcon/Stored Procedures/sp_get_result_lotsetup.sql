-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_get_result_lotsetup]
	-- Add the parameters for the stored procedure here
	@lotno varchar(10),@mcno varchar(20),@opno varchar(12),@carrierno varchar(11)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	([record_at]
      , [record_class]
      , [login_name]
      , [hostname]
      , [appname]
      , [command_text])
	SELECT GETDATE()
		,'4'
		,ORIGINAL_LOGIN()
		,HOST_NAME()
		,APP_NAME()
		,'EXEC [cellcon].[sp_get_result_lotsetup] @lot_no =''' + @lotno + '''' + ' @mc_no =''' + @mcno + '''' + ' @opno =' + @opno + '''' + ' @carrierno =' + @carrierno + ''''
		--JOIN PARAMITER
	DECLARE @permitted_machine_id INT,@device_slip_id INT,@act_device_name_id INT, @job_id INT,@machine_id INT;

	--RETURN
	DECLARE @is_pass INT,@lang VARCHAR(10),@code INT,@message NVARCHAR(100),@cause NVARCHAR(100),@handling NVARCHAR(100)
	,@information_code NVARCHAR(100),@importance NVARCHAR(100),@comment NVARCHAR(100) , @app_name VARCHAR(50)


	--SET Default paramiter
	SET @is_pass = 1;
	SET @lang = '';
	SET @code = 0;
	SET @message = '';
	SET @cause = '';
	SET @handling = ''
	SET @information_code = '';
	SET @importance = '';
	SET @comment = '';
	SET @app_name = '';
	--SET @machine_id = 244;--757;


	--CHECK PARAMITER
	DECLARE @is_released INT,@wip_state INT,@process_state INT,@quality_state INT,@is_special_flow INT
	,@packages_enabled INT,@machine_qc_state INT,@online_state INT,@automotive INT,@lot_automotive INT
	,@carrier_current VARCHAR(11),@permitted_id INT
 
    -- Insert statements for procedure here
	SELECT @permitted_machine_id = permitted_machine_id ,@device_slip_id = df.device_slip_id,
	@process_state = lo.process_state,@act_device_name_id = lo.act_device_name_id,
	@job_id = df.job_id,@is_special_flow = isnull(LO.is_special_flow,0),@wip_state = lo.wip_state
	,@quality_state = lo.quality_state,@carrier_current = lo.carrier_no
	 FROM APCSProDB.trans.lots AS lo
	 INNER JOIN APCSProDB.method.device_flows AS DF WITH (NOLOCK) ON DF.device_slip_id = LO.device_slip_id AND DF.step_no = LO.step_no
	WHERE lo.lot_no = @lotno

	if (@wip_state > 20) 
	BEGIN
		SELECT @is_pass = 0 ,@code = 124 --WipStateIsNotInput
		GOTO SELECT_MESSAGE;
	END
	ELSE IF NOT(@process_state = 0 OR @process_state = 100)
	BEGIN
		SELECT @is_pass = 0 ,@code = 100 --CanNotSetup
		GOTO SELECT_MESSAGE;
	END
	ELSE IF (@quality_state = 1)
	BEGIN
		SELECT @is_pass = 0 ,@code = 118 --LotQC_Abnormal
		GOTO SELECT_MESSAGE;
	END
	ELSE IF (@quality_state = 2)
	BEGIN
		SELECT @is_pass = 0 ,@code = 119 --LotQC_Stop
		GOTO SELECT_MESSAGE;
	END
	ELSE IF (@quality_state = 3)
	BEGIN
		SELECT @is_pass = 0 ,@code = 120 --LotQC_Hold
		GOTO SELECT_MESSAGE;
	END
	ELSE IF (@quality_state = 4)
	BEGIN
		SELECT @is_pass = 0 ,@code = 121 --LotQC_SPFlow
		GOTO SELECT_MESSAGE;
	END
	ELSE IF (@quality_state = 5)
	BEGIN
		SELECT @is_pass = 0 ,@code = 131 --LotQC_LimitTimeOver_5
		GOTO SELECT_MESSAGE;
	END
	ELSE IF (@quality_state = 6)
	BEGIN
		SELECT @is_pass = 0 ,@code = 132 --LotQC_LowYield_6
		GOTO SELECT_MESSAGE;
	END
	ELSE IF (@quality_state = 7)
	BEGIN
		SELECT @is_pass = 0 ,@code = 133 --LotQC_ICBurn_7
		GOTO SELECT_MESSAGE;
	END
	ELSE IF (@quality_state > 7)
	BEGIN
		SELECT @is_pass = 0 ,@code = 105 --LotQCNG
		GOTO SELECT_MESSAGE;
	END

	if (@is_special_flow = 0)
	BEGIN
		if(@carrierno <> @carrier_current AND @carrierno <> '-')
		BEGIN
			SELECT @is_pass = 0,@code = 1809 --VerificationNGOnStart
			GOTO SELECT_MESSAGE;
		END

		IF (@permitted_machine_id IS NULL)
		BEGIN
			SELECT @machine_id = id FROM [APCSProDB].mc.machines WHERE [name] = @mcno
		
			SELECT @is_released = device_slip.is_released,@packages_enabled = packages.is_enabled,
			@machine_qc_state = machine_states.qc_state,@online_state = machine_states.online_state,
			@automotive = CASE WHEN (machines.is_automotive != 1 AND device_name.is_automotive = 1) THEN 0 ELSE 1 END
			FROM (SELECT @permitted_machine_id AS permitted_machine_id,@device_slip_id AS device_slip_id,@act_device_name_id as act_device_name_id,@job_id as job_id) AS lotinfo
			INNER JOIN APCSProDB.method.device_slips AS device_slip ON device_slip.device_slip_id = lotinfo.device_slip_id
			INNER JOIN APCSProDB.method.device_names AS device_name ON device_name.id = lotinfo.act_device_name_id
			INNER JOIN APCSProDB.method.packages AS packages ON packages.id = device_name.package_id
			INNER JOIN APCSProDB.method.jobs AS jobs ON jobs.id = lotinfo.job_id
			INNER JOIN APCSProDB.mc.group_models AS group_models ON group_models.machine_group_id = jobs.machine_group_id
			INNER JOIN APCSProDB.mc.models AS models ON models.id = group_models.machine_model_id
			INNER JOIN APCSProDB.mc.machines AS machines ON machines.machine_model_id = models.id
			INNER JOIN APCSProDB.trans.machine_states AS machine_states WITH (NOLOCK) ON machine_states.machine_id = machines.id
			where machines.id = @machine_id
			
			IF (@@ROWCOUNT = 0)
			BEGIN
				SELECT @is_pass = 0 ,@code = 112--112 --LotDoNotWip
			END
			ELSE IF (@is_released != 1)
			BEGIN
			   SELECT @is_pass = 0 ,@code = 126 --SlipIsNotReleased
			END
			ELSE IF (@packages_enabled != 1)
			BEGIN
			   SELECT @is_pass = 0 ,@code = 106 --PackageNotEnable
			END
			ELSE IF (@machine_qc_state = 1)
			BEGIN
			   SELECT @is_pass = 0 ,@code = 122 --MachineQCAbnormalStop
			END
			ELSE IF (@machine_qc_state = 2)
			BEGIN
			   SELECT @is_pass = 0 ,@code = 123 --MachineQCReserveStop
			END
			ELSE IF (@machine_qc_state > 2)
			BEGIN
			   SELECT @is_pass = 0 ,@code = 107 --MachineQCNG
			END
			ELSE IF (@online_state != 1)
			BEGIN
			   SELECT @is_pass = 0 ,@code = 108 --MachineOnlineStateIsWorng
			END
			ELSE IF (@automotive != 1)
			BEGIN
			   SELECT @is_pass = 0 ,@code = 109 --NotAutoMotive
			END
			
		END
		ELSE
		BEGIN
			SELECT @permitted_id = permit_mc.permitted_machine_id 
			FROM APCSProDB.mc.permitted_machine_machines as permit_mc 
			WHERE  permit_mc.machine_id = @machine_id
			IF (@permitted_machine_id != @permitted_id)
			BEGIN
				SELECT @is_pass = 0,@code = 111 --NotPermittedMachine
			END
		END

	END		
	ELSE
	BEGIN
		SELECT @is_pass = 0,@message = 'is_special_flow not define',@cause = 'is_special_flow not define',@code = 0--SELECT '@is_special_flow'
	END
	
	SELECT_MESSAGE: 
	--Get error message
	if (@is_pass = 0)
	BEGIN
		
		SELECT @lang = [default_language] FROM [APCSProDB].[man].[users]

		SELECT @app_name = [app_name],@message = [message],@cause = cause, @handling = handling,
		 @information_code = information_code,@importance = importance,@comment = comment 
		FROM [APCSProDB].[mdm].[errors]
		WHERE code = @code and lang = @lang and [app_name] = 'iLibrary'

		IF (@@ROWCOUNT = 0) --Default lang
		BEGIN
			SELECT @app_name = [app_name],@message = [message],@cause = cause, @handling = handling,
			@information_code = information_code,@importance = importance,@comment = comment 
			FROM [APCSProDB].[mdm].[errors]
			WHERE code = @code and lang = 'Eng' and [app_name] = 'iLibrary'
		END
	END
	
	--return result
	SET @comment  = 'LotNo[' + @lotno + '],InputCarrierNo[' + @carrierno + '],CurrentCarrierNo[' + @carrier_current +  ']'
	SELECT @is_pass as is_pass,@code as code,@app_name as [app_name],@message as [message] ,@cause as cause,@handling as handling
	,@information_code as information_code,@importance as importance,@comment as comment

END

