-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_material]
	-- Add the parameters for the stored procedure here
	
	@Details Nvarchar(MAX) =  ''
	 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


		SELECT DISTINCT details FROM    APCSProDB.material.productions 
		WHERE details  IN   ('EMBOSS TAPE', 'COVER TAPE')
		 

		SELECT id, name FROM    APCSProDB.material.productions 
		WHERE  details LIKE '%EMBOSS TAPE%'
		ORDER BY name

     
		SELECT  id, name
		FROM  (SELECT CAST(LEFT(name,CAST(CHARINDEX(' ',name)AS float)-1 )AS float )  AS OR_name,id,  details ,name 
		FROM APCSProDB.material.productions) AS ordername
		WHERE details  =  'COVER TAPE'  
 






END