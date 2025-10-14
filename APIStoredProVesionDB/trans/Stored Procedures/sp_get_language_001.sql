
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_language_001] 
	-- Add the parameters for the stored procedure here
	  @app_name			AS VARCHAR(100)
	, @languageCode		AS INT
	, @op_no			AS VARCHAR(6)
	, @language			AS VARCHAR(5) =  '' 
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE  @factory_code NVARCHAR(100)

	IF (@language IS NULL OR @language = '')
	BEGIN 

				SELECT  @factory_code = factories.[default_language]
										FROM APCSProDB.man.users
										INNER JOIN APCSProDB.man.user_organizations 
										ON users.id = user_organizations.[user_id]
										INNER JOIN APCSProDB.man.organizations 
										ON user_organizations.organization_id = organizations.id
										INNER JOIN APCSProDB.man.headquarters 
										ON organizations.headquarter_id = headquarters.id
										INNER JOIN APCSProDB.man.factories 
										ON headquarters.factory_id = factories.id
										WHERE users.emp_num = @op_no


  
					 SELECT   ISNULL(lang,'')					AS lang
							, ISNULL([message],'')				AS [message]
							, ISNULL(cause,'')					AS cause
							, ISNULL(handling,'')				AS handling
							, ISNULL(information_code,'')		AS information_code
							, ISNULL(importance,'')				AS importance
							, ISNULL(comment ,'')				AS comment
							, ISNULL([app_name] ,'')			AS [app_name]
			 				, importance						AS code_message
							, ISNULL(item_labels.label_eng,'')	AS status_message
					FROM APCSProDB.mdm.errors
					LEFT JOIN APCSProDB.trans.item_labels
					ON errors.importance  =  item_labels.val
					AND  item_labels.name = 'mdm.errors' 
					WHERE [app_name]	= @app_name
					AND code			= @languageCode
					AND lang			= @factory_code
	END
	ELSE
	BEGIN


					SELECT    ISNULL(lang,'')					AS lang
							, ISNULL([message],'')				AS [message]
							, ISNULL(cause,'')					AS cause
							, ISNULL(handling,'')				AS handling
							, ISNULL(information_code,'')		AS information_code
							, ISNULL(importance,'')				AS importance
							, ISNULL(comment ,'')				AS comment
							, ISNULL([app_name] ,'')			AS [app_name]
			 				, importance						AS code_message
							, ISNULL(item_labels.label_eng,'')	AS status_message
					FROM APCSProDB.mdm.errors
					LEFT JOIN APCSProDB.trans.item_labels
					ON errors.importance  =  item_labels.val
					AND  item_labels.[name] = 'mdm.errors' 
					WHERE [app_name]	= @app_name
					AND code			= @languageCode
					AND lang			= @language

	END 
 END
