-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [man].[sp_get_license_user_machine_004]
	-- Add the parameters for the stored procedure here
	  @emp_code			VARCHAR(10)
	, @machine_model	VARCHAR(50)
	, @machine_name		VARCHAR(50)
	, @is_automotive	BIT				= 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @app_name NVARCHAR(100) = 'CommonCellController'
	-- Insert statements for procedure here
	INSERT INTO [APIStoredProDB].[dbo].[exec_sp_history]
		( [record_at]
		, [record_clASs]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text] )
	SELECT GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [mc].[sp_get_license_user_machine_004] @emp_code = ''' + @emp_code 
			+ ''', @machine_model = ''' + @machine_model 
			+ ''', @machine_name = ''' + @machine_name + ''''
	

	IF(@is_automotive =  0)
	BEGIN 

			IF NOT EXISTS ( SELECT 'xx' FROM [10.29.1.116].[TEC_Skill_Test].[dbo].[vw_LastMStaffLicense_model_All] 
							WHERE Staffcode =  @emp_code 
							AND model_name  = @machine_model
							AND LisenceName  != 'AUTOMOTIVE')
			BEGIN 
								SELECT    '3002'			AS code
										, @emp_code			AS parameter
										, @app_name			AS [app_name]	
										, 'FALSE'			AS Is_Pass

								RETURN
			END 
			ELSE
			BEGIN
					
				SELECT      CASE WHEN  DATEADD(MONTH, 6, CertificationDate) <= GETDATE()  THEN 128  ELSE 200 END AS code
							, @emp_code +','+ CONVERT(VARCHAR(100) , DATEADD(MONTH, 6, CertificationDate)) AS parameter
							, @app_name				AS [app_name]
							, CASE WHEN   DATEADD(MONTH, 6, CertificationDate) <= GETDATE() THEN 'TRUE' ELSE 'TRUE' END   AS Is_Pass  
							, Staffcode	AS emp_code
							, @machine_name			AS machine_name 
							, model_name		AS model
							, LisenceName		AS lisence_name
							, CONVERT(VARCHAR(100) ,DATEADD(MONTH, 6, CertificationDate)) AS expire_date
							, CASE WHEN DATEADD(MONTH, 6, CertificationDate) < GETDATE() THEN 1 ELSE 0 END AS is_expire  
							FROM [10.29.1.116].[TEC_Skill_Test].[dbo].[vw_LastMStaffLicense_model_All] 
							WHERE Staffcode =  @emp_code 
							AND model_name  = @machine_model
							AND LisenceName  != 'AUTOMOTIVE'
							AND  inuse = 1
							GROUP BY  LisenceName
							,model_name
							,Staffcode
							,CertificationDate
							ORDER BY CertificationDate 


					RETURN
			END
	END
	ELSE
	BEGIN
		
			IF EXISTS(SELECT 'xxx'  FROM [10.29.1.116].[TEC_Skill_Test].[dbo].[vw_LastMStaffLicense_model_All]
						WHERE LisenceName = 'AUTOMOTIVE' 
						AND Staffcode =  @emp_code 
							)
			BEGIN

						IF NOT EXISTS ( SELECT 'xx' FROM [10.29.1.116].[TEC_Skill_Test].[dbo].[vw_LastMStaffLicense_model_All] 
										WHERE Staffcode =  @emp_code 
										AND model_name  = @machine_model)
						BEGIN 
											SELECT    '3002'			AS code
													, @emp_code			AS parameter
													, @app_name			AS [app_name]	
													, 'FALSE'			AS Is_Pass

											RETURN
						END 
						ELSE
						BEGIN 

								SELECT      CASE WHEN  DATEADD(MONTH, 6, CertificationDate) <= GETDATE()  THEN 128  ELSE 200 END AS code
							, @emp_code +','+ CONVERT(VARCHAR(100) , DATEADD(MONTH, 6, CertificationDate)) AS parameter
							, @app_name				AS [app_name]
							, CASE WHEN   DATEADD(MONTH, 6, CertificationDate) <= GETDATE() THEN 'TRUE' ELSE 'TRUE' END   AS Is_Pass  
							, Staffcode	AS emp_code
							, @machine_name			AS machine_name 
							, model_name		AS model
							, LisenceName		AS lisence_name
							, CONVERT(VARCHAR(100) ,DATEADD(MONTH, 6, CertificationDate)) AS expire_date
							, CASE WHEN DATEADD(MONTH, 6, CertificationDate) < GETDATE() THEN 1 ELSE 0 END AS is_expire  
							FROM [10.29.1.116].[TEC_Skill_Test].[dbo].[vw_LastMStaffLicense_model_All] 
							WHERE Staffcode =  @emp_code 
							AND model_name  = @machine_model 
							AND  inuse = 1
							GROUP BY  LisenceName
							,model_name
							,Staffcode
							,CertificationDate
							ORDER BY CertificationDate 

								RETURN

						END 

			END
			ELSE
			BEGIN

				SELECT    '3006'		code
						, @emp_code			AS parameter
						, @app_name			AS [app_name]
						, 'FALSE'				AS Is_Pass
						RETURN
 
			END
	END
 
 




END
