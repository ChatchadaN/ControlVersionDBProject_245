------------------------------ Creater Rule ------------------------------
-- Project Name				: MDN 
-- Procedure Name 	 		: [mdm].[sp_get_DeviceSlipsAll]
-- Filename					: mdm.sp_get_DeviceSlipsAll.sql
-- Database Referd			: StoredProcedureDB
-- Tables Refered			: method.device_slips
-- Specific Logic           : 
-- Purpose					: Get Meta Data
-- Comments					: 
-------------------------------------------------------------------------

CREATE PROCEDURE [mdm].[sp_get_filter_man]
(	 
		  @filter		INT  
		, @name			NVARCHAR(100)		
		, @short_name	NVARCHAR(20)
		, @id			INT  
)
						
AS
BEGIN
	 
	 SET NOCOUNT ON;	
     
 
IF (@filter =  1)
BEGIN 

		 SELECT		 [sections].id 
				   , [name]
				   , short_name
				   , department_id   AS _id
		 FROM [APCSProDB].[man].[sections] 
		 where [name]		= @name
		 and short_name		= @short_name
		 and department_id	= @id
  
END 
ELSE 
IF (@filter =  2)
BEGIN 
			SELECT	  [departments].id 
					, [name]
					, short_name
					, division_id AS _id
			FROM [APCSProDB].[man].[departments] 
			WHERE [name]	= @name
			AND short_name	= @short_name
			AND division_id = @id

END 
IF (@filter =  3)
BEGIN 

			SELECT    [divisions].id 
					, [name]
					, short_name
					, headquarter_id  AS _id
			FROM [APCSProDB].[man].[divisions] 
			WHERE [name]		= @name
			AND short_name		= @short_name
			AND headquarter_id	= @id

END  

IF (@filter =  4)
	BEGIN 

			SELECT    [id]
					,[name]
					 ,ISNULL(descriptions,'')  AS short_name
					, 0  AS _id
			FROM [APCSProDB].[man].[permissions] 
			WHERE [name]		= @name
			AND descriptions	= @short_name
			

	END
END
