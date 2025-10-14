-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [ctrlic].[sp_set_tec_insert_skt_user_license]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @userLicID TABLE
	(
		lic_id_lsi INT,
		userID INT,
		CertificationDate DATETIME,
		expire DATETIME,
		is_active INT
	)

	INSERT INTO @userLicID
	SELECT 
		source.lic_id_lsi,
		source.userID,
		source.CertificationDate,
		source.expire,
		source.is_active
	FROM (
		SELECT 
			lr.lic_id_lsi,
			users.id AS userID,
			ls.CertificationDate,
			DATEADD(month, 6, ls.CertificationDate) AS expire,
			CASE WHEN ls.RenewalStatus = 'License_renewed' THEN 1 ELSE 0 END AS is_active
		FROM APCSProDWH.[dbo].[SKT_MLicenseStaff_] ls
		INNER JOIN APCSProDWH.[dbo].SKT_MMainLicense ml ON ml.LicenseCode = ls.LicenseCode
		INNER JOIN APCSProDWH.[dbo].SKT_Rlic lr ON lr.LicenseId = ml.LisenceId
		INNER JOIN APCSProDB.man.users users ON users.emp_num = ls.StaffCode COLLATE SQL_Latin1_General_CP1_CI_AS
		WHERE lic_id_lsi != 88 
		AND ls.RenewalStatus != 'Disable'
		
		--case ชื่อ license เหมือนกันแต่คนละ licensecode ต่ออายุเฉพาะ license ที่สอบ
		AND ls.RenewalStatus != 'Expired'

		--GET ONLY D11 and D12 : PD LSI
		AND ( ml.LicenseCode like 'LSD11-%' OR  ml.LicenseCode like 'LSD12-%' )
		--AND ml.LicenseCode not like 'LSD10-%'

		AND DATEADD(month, 6, ls.CertificationDate) > GETDATE()

	) AS source
	LEFT JOIN APCSProDB.ctrlic.user_lic target
	ON source.lic_id_lsi = target.lic_id AND source.userID = target.user_id
	WHERE target.lic_id IS NULL AND target.user_id IS NULL


	--STEP 4 INSERT USER LICENSE
	MERGE INTO APCSProDB.ctrlic.user_lic AS USERLIC
	USING @userLicID AS TEC
	ON USERLIC.lic_id = TEC.lic_id_lsi
	AND USERLIC.user_id = TEC.userID
	WHEN NOT MATCHED BY TARGET
	THEN 
		INSERT (lic_id, user_id, start_date, stop_date, is_active)
		VALUES (TEC.lic_id_lsi, TEC.userID, TEC.CertificationDate, TEC.expire, TEC.is_active);


	--STEP 5 DATETE OLD LICENSE
	--DELETE FROM APCSProDB.ctrlic.user_lic
	--WHERE lic_id < 1000 and lic_id != 88
	--AND user_id in (SELECT userID FROM @userLicID GROUP BY userID)

END
