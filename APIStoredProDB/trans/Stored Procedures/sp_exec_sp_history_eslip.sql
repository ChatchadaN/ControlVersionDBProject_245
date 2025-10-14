-- =============================================
-- Author:		NUCHA
-- Create date: 2022/06/29
-- Description:	<Description,,>
-- =============================================
CREATE  PROCEDURE [trans].[sp_exec_sp_history_eslip]
	@record_class	AS VARCHAR(50),
	@login_name		AS VARCHAR(6)= NULL,
	@appname		AS VARCHAR(255),
	@clientname		VARCHAR(255),
	@lot_no			AS VARCHAR(10),
	@e_slip_id		AS VARCHAR(255),
	@medthod_type	VARCHAR(255),
	@function_name  VARCHAR(255),
	@link_name		VARCHAR(255),
	@command_text	VARCHAR(MAX)

AS
BEGIN
	 
	SET NOCOUNT ON;
 
	INSERT INTO [dbo].[exec_sp_history_eslip]
	(		 [record_at]
           , [record_class]
           , [login_name]
           , [hostname]
		   , clientname
           , [appname]
		   , lot_no
		   , e_slip_id
		   , medthod_type
		   , function_name
		   , link_name
           , [command_text] 
	)
    VALUES
	(		
            GETDATE()
          , @record_class
          , @login_name
          , HOST_NAME()
		  , @clientname
          , @appname
		  , @lot_no
		  , @e_slip_id
		  , @medthod_type
		  , @function_name
		  , @link_name
		  , @command_text
	)
END
