-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_get_lot_extend_info]
	@lot_no NVARCHAR(20) = NULL,
	@process VARCHAR(5)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @sql NVARCHAR(MAX);
	DECLARE @columns VARCHAR(MAX);

	SELECT @columns = STRING_AGG([column_name],',') 
	FROM (
		 SELECT [column_name]
		  FROM [APCSProDB_lsi_110].[cellcon_menu].[lot_transactions_menu] WHERE (type = 'ALL' OR type = 'DB') AND is_created = 1
		 UNION ALL
		 SELECT [column_name]
		  FROM [APCSProDB_lsi_110].[cellcon_menu].[lot_extend_menu] WHERE type = 'DB' AND is_created = 1
	) as tb;


	SET @sql = 'SELECT ' + @columns + ' FROM [APCSProDWR].[trans].[lot_transactions] mst ' +
			   'LEFT JOIN [APCSProDWR].[trans].[lot_extended] ext on mst.id = ext.lot_transactions_id ' +
			   'WHERE 1 = 1 ' +
			   'AND process = ''' + @process + '''';
			   IF (ISNULL(@lot_no,'') <> '') 
			   BEGIN 
					SET @sql += 'AND lot_no = ''' + @lot_no + '''';
			   END

	EXEC sp_executesql @sql;

END
