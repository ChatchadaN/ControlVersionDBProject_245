-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_ois_eqiupment]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN
		select productions.id
		, IIF(productions.spec IS NULL,productions.[name],productions.spec) as productions
		, productions.[name]
		, category_id
		, categories.short_name as categories
		FROM APCSProDB.jig.productions
		INNER JOIN APCSProDB.jig.categories ON productions.category_id = categories.id 
	END
END
