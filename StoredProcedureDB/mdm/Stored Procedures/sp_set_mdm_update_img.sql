-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_set_mdm_update_img]
	-- Add the parameters for the stored procedure here
 
AS
BEGIN
	
	SET NOCOUNT ON;
 
SELECT id, picture_data  ,emp_num , len(picture_data) 
FROM APCSProDB.man.users
WHERE picture_data IS NOT NULL    AND id < 2000 
AND LEN(picture_data) > 100000
				
END