

CREATE PROCEDURE [man].[sp_get_filter_man_001]
(	 
		  @filter		INT  
		, @id			INT =0
)
						
AS
BEGIN
	 
	 SET NOCOUNT ON;	
     

IF (@filter =  1)
BEGIN
SELECT [groups].[id]
		      ,[name]
			  ,isnull([short_name],'')  AS [short_name]
		      ,factory_id
			  FROM [DWH].[man].[groups]
			where  factory_id = @id and is_active = 1
 END
 ELSE


IF (@filter =  2)
			SELECT headquarters.[id]
		      ,[headquarters].[name]
		      ,isnull([headquarters].[short_name],'')  AS [short_name]
		      ,[hq_code]
		      ,[group_id]
			  FROM [DWH].[man].[headquarters]
			  inner join [DWH].[man].[groups] on group_id = groups.id
			where  group_id	= @id and [headquarters].is_active = 1

ELSE 
IF (@filter =  3)
BEGIN 
			SELECT	  [divisions].id 
					, [divisions].[name]
					, isnull([divisions].short_name,'') AS [short_name]
					, headquarter_id 
			FROM [DWH].[man].[divisions] 
			INNER JOIN  [DWH].[man].[headquarters] on divisions.headquarter_id  =  [headquarters].id
			WHERE headquarter_id = @id and [divisions].is_active = 1
			

END 
ELSE 
IF (@filter =  4)
BEGIN 
			SELECT	  [departments].id 
					, [departments].[name]
					, isnull([departments].short_name,'') AS [short_name]
					, division_id 
			FROM [DWH].[man].[departments]
			INNER JOIN  [DWH].[man].[divisions] on [departments].division_id =  [divisions].id
			WHERE division_id = @id and [departments].is_active = 1

END 
IF (@filter =  5)
BEGIN 

			SELECT    [sections].id 
					, [sections].[name]
					, isnull([sections].short_name,'') AS [short_name]
					, department_id 
			FROM [DWH].[man].[sections]
			INNER JOIN  [DWH].[man].[departments] on  department_id =  [departments].id
			WHERE department_id	= @id and [sections].is_active = 1

END  

END  


