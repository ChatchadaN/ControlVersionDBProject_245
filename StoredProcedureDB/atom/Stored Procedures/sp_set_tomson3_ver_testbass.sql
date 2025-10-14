-- =============================================
CREATE PROCEDURE [atom].[sp_set_tomson3_ver_testbass] 
	-- Add the parameters for the stored procedure here
	@status INT = 0, ----#0:insert, 1:update, 2:delete
	@LotIdTable lot_tomson3 READONLY,
	@tomson3_after CHAR(4) = '   ', 
	@user_id INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	SELECT GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [atom].[sp_set_tomson3_ver_testbass] @status = ' + ISNULL( CAST( @status AS VARCHAR ), '' ) 
			+ ', @LotIdTable = ''' + (SELECT CAST(ISNULL( STUFF( ( SELECT CONCAT(', ', lot_id) FROM @LotIdTable FOR XML PATH ('')), 1, 2, '' ), 'NULL' ) AS VARCHAR(MAX) ) ) + '''' 
			+ ', @tomson3_after = ''' + ISNULL( CAST( @tomson3_after AS VARCHAR ), '' )  + ''''
			+ ', @user_id = ' + ISNULL( CAST( @user_id AS VARCHAR ), '' )
		, 'T-20230819' ;

	
END
