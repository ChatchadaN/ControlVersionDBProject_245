-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [ctrlic].[sp_set_tec_delete_skt_user_license_expired]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- CASE : license TEC status 'Expired' => Delete User license in user_lic 
	DECLARE @userLicID TABLE
	(
		lic_id_lsi INT,
		userID INT,
		emp_num VARCHAR(50),
		RenewalStatus varchar(30)
	)

	INSERT INTO @userLicID
	SELECT 
		source.lic_id_lsi,
		source.userID,
		source.emp_num,
		source.RenewalStatus
	FROM (
		SELECT distinct
			lr.lic_id_lsi,
			users.[id] AS userID,
			users.emp_num,
			ls.RenewalStatus 
		FROM APCSProDWH.[dbo].[SKT_MLicenseStaff_] ls
		INNER JOIN APCSProDWH.[dbo].SKT_MMainLicense ml ON ml.LicenseCode = ls.LicenseCode
		INNER JOIN APCSProDWH.[dbo].SKT_Rlic lr ON lr.LicenseId = ml.LisenceId
		INNER JOIN APCSProDB.man.users users ON users.emp_num = ls.StaffCode COLLATE SQL_Latin1_General_CP1_CI_AS
		WHERE ls.RenewalStatus = 'Expired'
		AND lr.lic_id_lsi != 88
	) AS source
	LEFT JOIN APCSProDB.ctrlic.user_lic target
	ON source.lic_id_lsi = target.lic_id AND source.userID = target.[user_id]
	--WHERE stop_date < GETDATE()


	DELETE ul
	FROM APCSProDB.ctrlic.user_lic AS ul
	INNER JOIN @userLicID expired ON ul.lic_id = expired.lic_id_lsi
	AND ul.[user_id] = expired.userID

END
