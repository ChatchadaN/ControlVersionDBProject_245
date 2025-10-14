-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [jig].[sp_get_frame_data] 
	-- Add the parameters for the stored procedure here
	@id int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	SET @id = CASE WHEN  @id = 0 THEN NULL ELSE @id  END  
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
  SELECT [id] 
  ,[frametype] 
  ,[common_frametype] 
  FROM [APCSProDB].[jig].[common_frametypes]
  WHERE [id]  =  @id  OR  @id  IS NULL 
END
