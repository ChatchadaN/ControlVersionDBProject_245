-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [ctrlic].[sp_set_tec_update_skt_user_license]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	BEGIN TRY
	BEGIN

		MERGE INTO [APCSProDB].[ctrlic].[user_lic] AS LSI
		USING
		(
			SELECT DISTINCT
				LSI.lic_id,
				LSI.user_id,
				LSI.start_date,
				LSI.stop_date,
				LSI.is_active,
				DATEADD(month, 6, TEC.CertificationDate) as TEC_expire,
				1 AS TEC_is_active
			FROM
				APCSProDB.ctrlic.user_lic AS LSI
			INNER JOIN
				APCSProDB.man.users AS users ON LSI.[user_id] = users.id
			INNER JOIN
				APCSProDB.ctrlic.license ON LSI.lic_id = license.lic_id
			INNER JOIN
				APCSProDWH.dbo.SKT_MLicenseStaff_ AS TEC ON users.emp_num = TEC.StaffCode
				AND license.lic_code = TEC.LicenseCode
			INNER JOIN
				APCSProDWH.dbo.SKT_MMainLicense ON TEC.LicenseCode = SKT_MMainLicense.LicenseCode

			WHERE
				LSI.lic_id > 1000
				AND DATEADD(month, 6, TEC.CertificationDate) > GETDATE()
				AND TEC.RenewalStatus != 'Disable'
				AND LSI.stop_date !=  DATEADD(month, 6, TEC.CertificationDate)
				--AND SKT_MMainLicense.Inuse = 1 
				--AND LSI.[user_id] != 64
		) AS TEC
		ON LSI.lic_id = TEC.lic_id AND LSI.[user_id] = TEC.[user_id]

		-- เงื่อนไขการอัพเดท เมื่อ stop_date หรือ is_active ไม่ตรงกับ TEC
		WHEN MATCHED AND
			  CAST(LSI.stop_date AS DATE) != CAST(TEC.TEC_expire AS DATE)
		THEN
			UPDATE SET
			LSI.stop_date = TEC.TEC_expire;
	END

	-----------------------------------------------------------------------------------------------
	--update license automative
	BEGIN
		UPDATE APCSProDB.ctrlic.user_lic
		SET stop_date = DATEADD(MONTH, 6, stop_date)
		WHERE user_lic.lic_id IN (88,31,34,37,131,158,229,237,240,241,249,257,271,274,348)
		AND stop_date <= DATEADD(MONTH, 2, GETDATE()) -- หาวันที่ที่จะหมดอายุใน 1 เดือน
	END
	END TRY
	BEGIN CATCH
		PRINT '---> Error <----' +  ERROR_MESSAGE() + '---> Error <----'; 
		ROLLBACK;
	END CATCH
END
