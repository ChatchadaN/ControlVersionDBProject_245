
--Temporarily enable xp_cmdshell


CREATE PROCEDURE [dbo].[tg_sp_update_jedec_package_master] 
	-- Add the parameters for the stored procedure here
	
AS
BEGIN

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
		,'EXEC [dbo].[tg_sp_update_jedec_package_master]'


	
DELETE FROM [DBxDW].[TGOG].[JEDEC_PACKAGE_MASTER];

INSERT INTO [TGOG].[JEDEC_PACKAGE_MASTER]
           ([ID_NO]
           ,[PACKAGE_NAME]
           ,[DEVICE_NAME]
           ,[START_DATE]
           ,[SPEC]
           ,[FLOOR_LIFE]
           ,[PPBT]
           ,[FLAG]
           ,[ADD_DATE])
    
           (SELECT  [IS_JEDEC_PACKAGE_MASTER].[ID_NO]
      ,[IS_JEDEC_PACKAGE_MASTER].[PACKAGE_NAME]
      ,[IS_JEDEC_PACKAGE_MASTER].[DEVICE_NAME]
      ,[IS_JEDEC_PACKAGE_MASTER].[START_DATE]
      ,[IS_JEDEC_PACKAGE_MASTER].[SPEC]
      ,[IS_JEDEC_PACKAGE_MASTER].[FLOOR_LIFE]
      ,[IS_JEDEC_PACKAGE_MASTER].[PPBT]
      ,[IS_JEDEC_PACKAGE_MASTER].[FLAG]
      ,[IS_JEDEC_PACKAGE_MASTER].[ADD_DATE]
  FROM [APCSProDB].[method].[packages] 
  inner join [DBxDW].[TGOG].[IS_JEDEC_PACKAGE_MASTER]
  on [APCSProDB].[method].[packages].[short_name] =  [DBxDW].[TGOG].[IS_JEDEC_PACKAGE_MASTER].PACKAGE_NAME);

END


