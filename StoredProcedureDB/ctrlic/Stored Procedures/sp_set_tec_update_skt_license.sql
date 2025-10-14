-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [ctrlic].[sp_set_tec_update_skt_license]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

		--STEP 1 INSERT LICENSE
		MERGE INTO [APCSProDB].[ctrlic].[license] AS LSI
		USING [APCSProDWH].[dbo].[SKT_MMainLicense] AS TEC
		ON LSI.lic_id = TEC.LisenceId + 1000
		--UPDATE LSI Data
		WHEN MATCHED AND 
			(LSI.lic_code != TEC.LicenseCode OR
			 LSI.lic_name != TEC.LisenceName OR
			 LSI.lic_status != TEC.Inuse)
			 AND
			(TEC.LicenseCode Like 'LSD11-%' OR	
			TEC.LicenseCode Like 'LSD12-%')
		THEN
			UPDATE SET
				LSI.lic_code = TEC.LicenseCode,
				LSI.lic_name = TEC.LisenceName,
				LSI.lic_status = TEC.Inuse

		--INSERT TEC New Data
		WHEN NOT MATCHED BY TARGET 
		THEN
			INSERT (
			[lic_id]
			  ,[lic_type]
			  ,[lic_objective]
			  ,[lic_code]
			  ,[lic_name]
			  ,[lic_expire]
			  ,[lic_status]
			  ,[add_date]
			  ,[add_user]
			  ,[edit_date]
			  ,[edit_user]
			)
			VALUES (
			TEC.[LisenceId] + 1000
			, '11003'
			, 'TEC SKILL TEST'
			, TEC.LicenseCode
			, TEC.LisenceName
			, 180
			, TEC.Inuse 
			, GETDATE()
			, 1
			, NULL
			, NULL
			);

		--STEP 2 UPDATE SKT_RLic
		MERGE INTO APCSProDWH.dbo.SKT_RLic AS RLIC
		USING (
			SELECT TEC.LisenceId, TEC.LisenceId + 1000 AS lic_id_lsi
			FROM [APCSProDWH].[dbo].[SKT_MMainLicense] TEC
			LEFT JOIN APCSProDWH.dbo.SKT_RLic RLIC2
			ON TEC.LisenceId = RLIC2.LicenseId
			WHERE RLIC2.LicenseId IS NULL
		) AS SRC
		ON RLIC.LicenseId = SRC.LisenceId
		WHEN NOT MATCHED BY TARGET
		THEN
			INSERT (LicenseId, lic_id_lsi)
			VALUES (SRC.LisenceId, SRC.lic_id_lsi);

END
