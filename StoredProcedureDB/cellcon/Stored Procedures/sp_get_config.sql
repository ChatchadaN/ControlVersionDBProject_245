-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_get_config]
	-- Add the parameters for the stored procedure here
	@app_name AS VARCHAR(50)
	,@process AS VARCHAR(50)
	,@function_name AS VARCHAR(50)
	,@mc_no AS VARCHAR(20)
	,@factory_code AS VARCHAR(20)
	--@factory = 1 RIST ,2 REPI
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
		--	declare @cellcon_config_function as table (
		--[app_name] varchar(50),
		--process varchar(50),
		--function_name varchar(50),
		--is_use BIT, --no use = 0,use =1
		--factory_code varchar(20), --rist = 64646,rohm = 2,repi = 62300,rohm yuku = 4 
		--[value] varchar(max)
		--)

		--insert into @cellcon_config_function 
		--values 
		--('CellController','All','MoveLogToServer',1,'64646','\\nas\CellconLog\Common\'),
		--('CellController','All','MoveLogToServer',1,'62300','\\172.26.220.59\Cellcon Logs\'),

		--('CellController','All','iReport',1,'64646',''),
		--('CellController','All','iReport',0,'62300',''),

		--('CellController','All','WaferMap',1,'62300','\\10.20.10.251\WaferMapping\'),
		--('CellController','All','AfterAOI',1,'62300','\\10.20.10.251\AfterAOI\'),

		--('CellController','All','WaferMap',1,'64646','\\mspace\NewCenterPoint\WaferMapping\'),
		--('CellController','All','AfterAOI',1,'64646','\\mspace\NewCenterPoint\AfterAOI\'),

		--('CellController','All','Config',1,'64646','\\172.16.0.115\CellController\Config\'),
		--('CellController','All','Config',1,'62300','\\172.26.220.59\APCS Pro\Cellcon Config\'),

		--('CellController','All','DummyBox',1,'64646','RIST'),
		--('CellController','All','DummyBox',0,'62300','REPI'),

		--('CellController','All','getIpApi',0,'64646','http://rohmapi'),
		--('CellController','All','getIpApi',1,'62300','http://10.20.10.252'),
		--('CellController','All','getIpApiOcr',1,'64646','http://10.28.33.131'), 
		--('CellController','All','getIpApiOcr',0,'62300','http://10.20.10.252'),

		--('CellController','MP','INPUT_RESIN',1,'64646','RIST'),
		--('CellController','MP','INPUT_RESIN',1,'62300','REPI'),
		--('CellController','MP','SPC',1,'64646','RIST'),
		--('CellController','MP','SPC',0,'62300','REPI'),
		--('CellController','MP','Kanagata',1,'64646','RIST'),
		--('CellController','MP','Kanagata',0,'62300','REPI'),
		--('CellController','MP','INPUT_RESIN_LABEL',0,'64646','TEMP'),
		--('CellController','MP','INPUT_RESIN_LABEL',1,'62300','TEMP'),
		--('CellController','MP','SPFlowAfterJob',1,'64646','40,269,313'),
		--('CellController','MP','SPFlowAfterJob',0,'62300',''),
		--('CellController','MP','SPFlowNotAddJob',1,'64646','97,142'),
		--('CellController','MP','SPFlowNotAddJob',0,'62300',''),
		--('CellController','MP','FlowPatterns',1,'64646','71'),
		--('CellController','MP','FlowPatterns',0,'62300',''),

		--('CellController','TC','SETUP',1,'64646','RIST'),
		--('CellController','TC','SETUP',1,'62300','REPI'),
	

		--('CellController','WB','PullShear',1,'64646','RIST'),
		--('CellController','WB','PullShear',0,'62300','REPI'),
	 --   ('CellController','WB','PPC',1,'64646','RIST'),
		--('CellController','WB','PPC',0,'62300','REPI'),
	 --   ('CellController','WB','CheckTypeHSE',1,'64646','HSSOP-C16'),
		--('CellController','WB','CheckTypeHSE',0,'62300','REPI'),

		--('CellController','FT','HandlerTesterQtyAbnormalCheck',1,'64646','RIST'),
		--('CellController','FT','HandlerTesterQtyAbnormalCheck',0,'62300','REPI'),
		
	 --   ('CellController','TP','getStdTube',1,'64646','RIST'),
		--('CellController','TP','getStdTube',1,'62300','REPI'),
		--('CellController','TP','TPRework',1,'64646','RIST'),
		--('CellController','TP','TPRework',0,'62300','REPI'),
		--('CellController','TP','CheckFontNg',1,'64646','RIST'),
		--('CellController','TP','CheckFontNg',0,'62300','REPI'),
		--('CellController','TP','getMachineARC',1,'64646','RIST'),
		--('CellController','TP','getMachineARC',0,'62300','REPI'),
		--('CellController','TP','SetSubMaterial_EMBOSS',1,'64646','RIST'),
		--('CellController','TP','SetSubMaterial_EMBOSS',0,'62300','REPI'),
		--('CellController','TP','SetSubMaterial_COVERTAPE',1,'64646','RIST'),
		--('CellController','TP','SetSubMaterial_COVERTAPE',0,'62300','REPI'),
		--('CellController','TP','SetSubMaterial_REELTYPE',1,'64646','RIST'),
		--('CellController','TP','SetSubMaterial_REELTYPE',0,'62300','REPI'),
		--('CellController','TP','autoTg',1,'64646','RIST'),
		--('CellController','TP','autoTg',0,'62300','REPI'),
		--('CellController','TP','autoTgMix',1,'64646','RIST'),
		--('CellController','TP','autoTgMix',0,'62300','REPI'),
		--('CellController','TP','checkVersionLabel',1,'64646','RIST'),
		--('CellController','TP','checkVersionLabel',0,'62300','REPI'),
		--('CellController','TP','checkWip_State',1,'64646','RIST'),
		--('CellController','TP','checkWip_State',0,'62300','REPI'),
		--('CellController','TP','cancel_mix_lot',1,'64646','RIST'),
		--('CellController','TP','cancel_mix_lot',0,'62300','REPI'),
		--('CellController','TP','printLabelReelEnd',1,'64646','RIST'),
		--('CellController','TP','printLabelReelEnd',0,'62300','REPI'),
		--('CellController','TP','safetyFactor',1,'64646','RIST'),
		--('CellController','TP','safetyFactor',0,'62300','REPI'),
		--('CellController','TP','checkDataMarkingVerify',1,'64646','RIST'),
		--('CellController','TP','checkDataMarkingVerify',0,'62300','REPI'),
		--('CellController','TP','getConfigMachine',1,'64646','RIST'),
		--('CellController','TP','getConfigMachine',0,'62300','REPI'),
		--('CellController','TP','getDataQtyTranLot',1,'64646','RIST'),
		--('CellController','TP','getDataQtyTranLot',0,'62300','REPI'),
		--('CellController','TP','updateQtyHasuu',1,'64646','RIST'),
		--('CellController','TP','updateQtyHasuu',0,'62300','REPI'),
		--('CellController','TP','getHasuuBefore',1,'64646','RIST'),
		--('CellController','TP','getHasuuBefore',0,'62300','REPI'),
		--('CellController','TP','nextLotStateChoice',1,'64646','RIST'),
		--('CellController','TP','nextLotStateChoice',0,'62300','REPI'),
		--('CellController','TP','checkContinualLot',1,'64646','RIST'),
		--('CellController','TP','checkContinualLot',0,'62300','REPI'),
		--('CellController','TP','updateVersionReprint',1,'64646','RIST'),
		--('CellController','TP','updateVersionReprint',0,'62300','REPI'),
		--('CellController','TP','imageMarkShow',1,'64646','RIST'),
		--('CellController','TP','imageMarkShow',0,'62300','REPI'),
		--('CellController','TP','allowFirstInsp',1,'64646','RIST'),
		--('CellController','TP','allowFirstInsp',0,'62300','REPI'),
		--('CellController','TP','btnReloadOCR',1,'64646','RIST'),
		--('CellController','TP','btnReloadOCR',0,'62300','REPI'),
		--('CellController','TP','imageMarkShow',1,'64646','RIST'),
		--('CellController','TP','imageMarkShow',0,'62300','REPI'),
		--('CellController','TP','Manual_TP_Nin',0,'64646','RIST'),
		--('CellController','TP','Manual_TP_Nin',1,'62300','REPI'),



	
		----('LPM','TP','Manual_TP_Nin',0,'64646','RIST'),
		----('LPM','TP','Manual_TP_Nin',1,'62300','REPI'),

		--('CellController','OGI','checkLotMagic',1,'64646','RIST'),
		--('CellController','OGI','checkLotMagic',0,'62300','REPI'),
		--('CellController','OGI','getQcStopLot',1,'64646','RIST'),
		--('CellController','OGI','getQcStopLot',0,'62300','REPI'),
		--('CellController','OGI','OCR_ManualCheckMark',1,'64646','RIST'),
		--('CellController','OGI','OCR_ManualCheckMark',0,'62300','REPI'),
		--('CellController','OGI','OnMachineLotStartCompleted_LabelAction',1,'64646','RIST'),
		--('CellController','OGI','OnMachineLotStartCompleted_LabelAction',0,'62300','REPI'),
		--('CellController','OGI','setDataTgIsServer',1,'64646','RIST'),
		--('CellController','OGI','setDataTgIsServer',0,'62300','REPI'),		
		--('CellController','OGI','api_UnlinkCard',1,'64646','RIST'),
		--('CellController','OGI','api_UnlinkCard',0,'62300','REPI'),
		--('CellController','OGI','sp_cancel_data_history_label',1,'64646','RIST'),
		--('CellController','OGI','sp_cancel_data_history_label',0,'62300','REPI'),
		--('CellController','OGI','sp_set_wip_state_memberlot',1,'64646','RIST'),
		--('CellController','OGI','sp_set_wip_state_memberlot',0,'62300','REPI'),		
		
		--('CellController','FL','FL_TP_Ninshiki',0,'64646','RIST'),
		--('CellController','FL','FL_TP_Ninshiki',1,'62300','REPI'),
	

		--('CellController','PL','PL_QR_EMULATOR',1,'64646','RIST'),
		--('CellController','PL','PL_QR_EMULATOR',1,'62300','REPI'),
	
		--('CellController','PL','IsDummy',1,'64646','RIST'),
		--('CellController','PL','IsDummy',0,'62300','REPI'),

		--('CellController','PL','DummyFrame',1,'64646','RIST'),
		--('CellController','PL','DummyFrame',0,'62300','REPI'),

		----('CellController','Material','Post_CheckMaterialInfo',1,'64646','000000,p@$$w0rd,http://rohmapi/api/Material/GetMaterialStatus'),
		----('CellController','Material','Post_CheckMaterialInfo',1,'62300','000000,REPIMDM,http://10.20.10.252/rohmapi/api/Material/GetMaterialStatus'),
		----('CellController','Material','Post_EndMaterialInfo',1,'64646','000000,p@$$w0rd,http://rohmapi/api/Material/SetMaterialEndLot'),
		----('CellController','Material','Post_EndMaterialInfo',1,'62300','000000,REPIMDM,http://10.20.10.252/rohmapi/api/Material/SetMaterialEndLot'),

		--('CellController','Material','Post_CheckMaterialInfo',1,'64646','000000,P@$$w0rd,http://rohmapi/api/Material/GetMaterialStatus'),
		--('CellController','Material','Post_CheckMaterialInfo',1,'62300','000000,REPIMDM,http://10.20.10.252/rohmapi/api/Material/GetMaterialStatus'),

		--('CellController','Material','Post_EndMaterialInfo',1,'64646','000000,P@$$w0rd,http://rohmapi/api/Material/SetMaterialEndLot'),
		--('CellController','Material','Post_EndMaterialInfo',1,'62300','000000,REPIMDM,http://10.20.10.252/rohmapi/api/Material/SetMaterialEndLot'), 
   
		--('CellController','Material','Post_SetupMaterialInfo',1,'64646','000000,P@$$w0rd,http://rohmapi/api/Material/SetMaterialSetup'),
		--('CellController','Material','Post_SetupMaterialInfo',1,'62300','000000,REPIMDM,http://10.20.10.252/rohmapi/api/Material/SetMaterialSetup'), 

		--('CellController','Material','Post_GetTypeMaterialInfo',1,'64646','000000,P@$$w0rd,http://rohmapi/api/Material/GetMaterialType'),
  --      ('CellController','Material','Post_GetTypeMaterialInfo',1,'62300','000000,REPIMDM,http://10.20.10.252/rohmapi/api/Material/GetMaterialType'),

  --      ('CellController','Material','Post_OutOffMachineMaterialInfo',1,'64646','000000,P@$$w0rd,http://rohmapi/api/Material/SetMaterialOutoffmachine'),
  --      ('CellController','Material','Post_OutOffMachineMaterialInfo',1,'62300','000000,REPIMDM,http://10.20.10.252/rohmapi/api/Material/SetMaterialOutoffmachine'),

		--('CellController','All','SaveRecordDBx',1,'64646','RIST'),
		--('CellController','All','SaveRecordDBx',0,'62300','REPI'),

		--('LPM','TP','NinBaudRate',1,'64646','38400'), --Todo autoOcr = 38400
		--('LPM','TP','NinBaudRate',1,'62300','9600'),
		--('LPM','TP','LB_CommandTP',0,'64646','RIST'),
		--('LPM','TP','LB_CommandTP',0,'62300','REPI'),
		--('LPM','TP','TodoNinshiki3D',1,'64646','TP-TP-19,TP-TP-09,TP-TP-XX,TP-TP-99'),
		--('LPM','TP','TodoNinshiki3D',0,'62300','REPI'),
		--('LPM','TP','AC_AlarmCommand',0,'64646','RIST'),
		--('LPM','TP','AC_AlarmCommand',1,'62300','REPI'),


		--('LPM','PL','PL_QR_EMULATOR',1,'64646','RIST'),
		--('LPM','PL','PL_QR_EMULATOR',1,'62300','REPI'),
		--('LPM','FL','FL_TP_Ninshiki',0,'64646','RIST'),
		--('LPM','FL','FL_TP_Ninshiki',1,'62300','REPI'),

		--('LPM','TC','SETUP',1,'64646','RIST'),
		--('LPM','TC','SETUP',1,'62300','REPI'),

		--('LPM','FL','FL_Manual_Ninshiki',0,'64646','RIST'),
		--('LPM','FL','FL_Manual_Ninshiki',1,'62300','REPI'),
		--('LPM','FL','LB_Command',0,'64646','RIST'),
		--('LPM','FL','LB_Command',0,'62300','REPI'),

		--('LPM','All','Config',1,'64646','\\172.16.0.115\CellController\Config\'),
		--('LPM','All','Config',1,'62300','\\172.26.220.59\APCS Pro\Cellcon Config\')
	
		--if (@factory_code = 'All')
		--	begin	
		--		select * from @cellcon_config_function
		--		where [app_name] = @app_name
		--	end 
		--else if (@factory_code = 'default')
		--	begin
		--		SELECT @factory_code = factories.factory_code 
		--				FROM  APCSProDB.mc.machines
		--				INNER JOIN APCSProDB.man.headquarters
		--				ON machines.headquarter_id =  headquarters.id 
		--				INNER JOIN APCSProDB.man.factories
		--				ON factories.id  = headquarters.factory_id
		--				WHERE machines.name =  @mc_no
		--					select * from @cellcon_config_function
		--				where [app_name] = @app_name and factory_code = @factory_code
		--	end
		--else 
		--	begin
		--		SELECT @factory_code = factories.factory_code 
		--			FROM  APCSProDB.mc.machines
		--			INNER JOIN APCSProDB.man.headquarters
		--			ON machines.headquarter_id =  headquarters.id 
		--			INNER JOIN APCSProDB.man.factories
		--			ON factories.id  = headquarters.factory_id
		--			WHERE machines.name =  @mc_no
		--		select * from @cellcon_config_function WHERE [app_name] = @app_name AND function_name = @function_name AND factory_code = @factory_code
		--	end


		---------------------------------Get Cellcon Config Table----------------------------------------
		
	IF (@factory_code = 'All')
		BEGIN	
			SELECT [id]
			  ,[app_name]
			  ,[comment] AS process
			  ,[function_name]
			  ,[is_use]
			  ,[factory_code]
			  ,[value]
			  ,[created_at]
			  ,[created_by]
			  ,[updated_at]
			  ,[updated_by]
			FROM [APCSProDB].[cellcon].[config_functions]
			--WHERE [app_name] = @app_name
			WHERE UPPER([app_name]) =  UPPER(@app_name)			
			--AND is_use = 1
		END 
	ELSE IF (@factory_code = 'default')
		BEGIN
			SELECT @factory_code = factories.factory_code 
			FROM  APCSProDB.mc.machines
			INNER JOIN APCSProDB.man.headquarters
			ON machines.headquarter_id =  headquarters.id 
			INNER JOIN APCSProDB.man.factories
			ON factories.id  = headquarters.factory_id
			WHERE machines.name =  @mc_no

			SELECT [id]
			  ,[app_name]
			  ,[comment] AS process
			  ,[function_name]
			  ,[is_use]
			  ,[factory_code]
			  ,[value]
			  ,[created_at]
			  ,[created_by]
			  ,[updated_at]
			  ,[updated_by]
			FROM [APCSProDB].[cellcon].[config_functions]
			--WHERE [app_name] = @app_name 
			WHERE UPPER([app_name]) =  UPPER(@app_name)
			and factory_code = @factory_code 
			--AND is_use = 1
		END
	ELSE 
		BEGIN
			SELECT @factory_code = factories.factory_code 
				FROM  APCSProDB.mc.machines
				INNER JOIN APCSProDB.man.headquarters
				ON machines.headquarter_id =  headquarters.id 
				INNER JOIN APCSProDB.man.factories
				ON factories.id  = headquarters.factory_id
				WHERE machines.name =  @mc_no

			SELECT [id]
			  ,[app_name]
			  ,[comment] AS process
			  ,[function_name]
			  ,[is_use]
			  ,[factory_code]
			  ,[value]
			  ,[created_at]
			  ,[created_by]
			  ,[updated_at]
			  ,[updated_by]		
			FROM [APCSProDB].[cellcon].[config_functions] 
			--WHERE [app_name] = @app_name 
			WHERE UPPER([app_name]) =  UPPER(@app_name)
			AND function_name = @function_name AND factory_code = @factory_code 
			--AND is_use = 1	
		END

END
