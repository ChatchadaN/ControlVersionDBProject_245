-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [man].[sp_get_license_005]
	-- Add the parameters for the stored procedure here
	@emp_code varchar(6)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @app_name  NVARCHAR(100) = 'CommonCellController'

	SELECT    
		CASE WHEN expire_date <= GETDATE() THEN 'FALSE' ELSE 'TRUE' END	AS Is_Pass  
		, CASE WHEN expire_date <= GETDATE()  THEN 3009 
			WHEN DATEADD(DAY,-20,expire_date) <= GETDATE() THEN 3010 ELSE 200 END AS code 
		, @emp_code +','+ CONVERT(VARCHAR(100) , CASE WHEN  expire_date <= GETDATE() THEN expire_date ELSE DATEADD(DAY,-20,expire_date) END ) AS parameter
		, @app_name	AS [app_name]	
		, emp_id	AS emp_id
		, emp_code
		, full_name_th
		, full_name_eng
		, [default_language]	 
		, [MainLicenseId] AS lisence_id
		, LicenseCode AS license_code
		, [License] AS lisence_name
		, CONVERT(VARCHAR(100) , expire_date) AS expire_date
		, is_active
		, CONVERT(VARCHAR(100) , DATEADD(DAY,-20,expire_date)) AS  wanning_date
		, case when DATEADD(DAY,-20,expire_date) <= GETDATE() THEN 1 ELSE 0 END AS is_wanning
		, case when  expire_date < GETDATE() THEN 1 ELSE 0 END AS is_expire
	FROM (
		SELECT  employees.id AS emp_id
			, emp_code
			, full_name_th
			, full_name_eng
			, [default_language]
			, [MainLicenseId] 
			, [License]	
			, LicenseCode
			, DATEADD(month,6,CertificationDate) AS  expire_date
			, inuse	AS is_active
		FROM [10.29.1.116].[TEC_Skill_TestDemo].[dbo].[vw_LastMStaffLicense_model_All]
		INNER JOIN DWH.man.employees 
			ON [vw_LastMStaffLicense_model_All].StaffCode  COLLATE Latin1_General_CI_AS = employees.emp_code COLLATE Latin1_General_CI_AS
		WHERE [employees].emp_code = @emp_code
		GROUP BY employees.id
			, emp_code
			, full_name_th
			, full_name_eng
			, [default_language]
			, [License]
			, CertificationDate
			, [MainLicenseId]
			, LicenseCode
			, inuse
	) AS License_Data
	WHERE is_active = 1
	ORDER BY expire_date , is_wanning

END
