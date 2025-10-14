
---- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_get_filter_001]
	-- Add the parameters for the stored procedure here
		@filter_no		INT
		--1 : time_unit , 2 : package_unit , 3 : matl_state , 4 : process_state , 5 : material location , 6: unit (oneworld) , 7 : po data 
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here

			IF (@filter_no = 1)	
			BEGIN 
				SELECT code AS id 
						, descriptions  AS [name]
						, ''		descriptions1
						, ''		descriptions2
				FROM APCSProDB.material.material_codes
				WHERE [group] =  'time_unit'
			END 

			IF (@filter_no = 2)	
			BEGIN 
				SELECT code AS id 
						, descriptions  AS [name]
						, ''		descriptions1
						, ''		descriptions2
				FROM APCSProDB.material.material_codes
				WHERE [group] =  'package_unit'
			END 

			IF (@filter_no = 3)	
			BEGIN
				SELECT code AS id 
						, descriptions  AS [name]
						, ''		descriptions1
						, ''		descriptions2
				FROM APCSProDB.material.material_codes
				WHERE [group] =  'matl_state'
			END 
			IF (@filter_no = 4)	
			BEGIN 	
				SELECT code AS id 
						, descriptions  AS [name]
						, ''		descriptions1
						, ''		descriptions2
				FROM APCSProDB.material.material_codes
				WHERE [group] =  'process_state'
			END 
			IF (@filter_no = 5)	
			BEGIN 	
				SELECT id  , [name]						
						, ''		descriptions1
						, ''		descriptions2
				FROM APCSProDB.material.locations
			END 
			IF (@filter_no = 6)	
			BEGIN 	
				SELECT DISTINCT [ropros_unit]	AS id 
						, [ropros_unitname]		AS [name]
						, ''		descriptions1
						, ''		descriptions2
				FROM APCSProDWH.[oneworld].[unit_convert]  
			END 
			IF (@filter_no = 7)	
			BEGIN 	
				SELECT  [id]			AS id 		
				     , [PoNo]			AS [name]
				     , [Specification]	AS descriptions1
				     , [SupplierName]	AS descriptions2 
				FROM APCSProDWH.[oneworld].[podata] 
				WHERE ([DeliverySectionCode] LIKE '21%') AND ([OpeDate] > DATEADD(YEAR , -1, GETDATE()))
				ORDER BY  [PoNo] DESC

			END 
		 
END
