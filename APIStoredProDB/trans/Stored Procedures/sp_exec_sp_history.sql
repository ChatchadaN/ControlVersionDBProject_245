-- =============================================
-- Author:		NUCHA
-- Create date: 2022/06/29
-- Description:	<Description,,>
-- =============================================
CREATE  PROCEDURE [trans].[sp_exec_sp_history] 
	-- Add the parameters for the stored procedure here
	@lot_no AS VARCHAR(50),
	@op_no AS VARCHAR(6)= NULL,
	@app_name AS VARCHAR(255),
	@record_class  INT = 4,
	@json AS VARCHAR(MAX)

AS
BEGIN
	 
	SET NOCOUNT ON;
 
INSERT INTO [dbo].[exec_sp_history]
           ([record_at]
           ,[record_class]
           ,[login_name]
           ,[hostname]
           ,[appname]
           ,[command_text]
           ,[lot_no])
     VALUES
	 (
           GETDATE()
           ,@record_class
           ,@op_no
           ,HOST_NAME()
		   ,@app_name
          ,@json
		  ,@lot_no
	)
END
