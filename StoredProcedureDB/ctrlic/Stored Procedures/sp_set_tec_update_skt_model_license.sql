-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [ctrlic].[sp_set_tec_update_skt_model_license]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--STEP 3 INSERT MODEL LICENSE
	MERGE INTO APCSProDB.ctrlic.model_lic AS MDL
	USING (
		SELECT 
		[t1].model_ref_id
		, [t1].lic_id_lsi
		FROM (
			--SELECT DISTINCT
			--	_model_lic.model_ref_id,
			--	_lr.lic_id_lsi
			--FROM [APCSProDWH].[dbo].[SKT_MLicenseStaff_] AS _userLicense
			--INNER JOIN [APCSProDWH].[dbo].[SKT_MMainLicense] as _license ON _userLicense.LicenseCode = _license.LicenseCode
			--INNER JOIN APCSProDWH.dbo.SKT_RLic as _lr ON  _lr.LicenseId = _license.LisenceId
			--INNER JOIN APCSProDWH.dbo.SKT_Models_License AS _model_lic ON _lr.LicenseId = _model_lic.LicenseId
			--INNER JOIN APCSProDWH.dbo.SKT_Models ON _model_lic.model_ref_id = SKT_Models.id

			SELECT DISTINCT
				_model_lic.model_ref_id,
				_lr.lic_id_lsi
			FROM APCSProDWH.dbo.SKT_Models_License AS _model_lic
			INNER JOIN APCSProDWH.dbo.SKT_Models ON _model_lic.model_ref_id = SKT_Models.id
			INNER JOIN [APCSProDWH].[dbo].[SKT_MMainLicense] AS _license ON _model_lic.LicenseId = _license.LisenceId
			INNER JOIN APCSProDWH.dbo.SKT_RLic AS _lr ON _lr.LicenseId = _license.LisenceId

		) as [t1]
		LEFT JOIN  APCSProDB.ctrlic.model_lic ON [t1].lic_id_lsi = model_lic.lic_id 
		and [t1].model_ref_id = model_lic.model_ref_id
		WHERE model_lic.lic_id IS NULL and model_lic.model_ref_id IS NULL
	) AS TEC
	ON MDL.model_ref_id = TEC.model_ref_id
	AND MDL.lic_id = TEC.lic_id_lsi
	WHEN NOT MATCHED BY TARGET
	THEN 
		INSERT (model_ref_id, lic_id)
		VALUES (TEC.model_ref_id, TEC.lic_id_lsi);


END
