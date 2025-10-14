-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_rcs_rack_size]
	-- Add the parameters for the stored procedure here
	@rackName varchar(15) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	IF @rackName = ''
	BEGIN
		SELECT @rackName = '%'
	END

	SELECT --name
		CASE WHEN MAX(wh_code) = 3 THEN CONCAT(name
												, ' ('
												, (SELECT REPLACE(name, '/', '') AS name
												   FROM APCSProDB.method.processes 
												   WHERE id = CAST(
																   (SUBSTRING ((PARSENAME(REPLACE([locations].[name], '-', '.'), 2))
																			  , 2
																			  , 2
																			  )
																   ) 
																   AS int
																  )
												  )
												,'-'
												, PARSENAME(REPLACE(name, '-', '.'), 3)
												, ')'
											   )
		ELSE name END AS name
		, COUNT (DISTINCT x) AS max_x
		, MAX (CONVERT (int, y)) AS max_y
		, MAX (CONVERT (int, z)) AS max_z
		, COUNT (x) AS count
		, SUBSTRING(PARSENAME(REPLACE([locations].[name], '-', '.'), 3), 1, 1) AS build
		, SUBSTRING(PARSENAME(REPLACE([locations].[name], '-', '.'), 3), 2, 1) AS floor
		--, CASE 
		--	WHEN ISNUMERIC(SUBSTRING(PARSENAME(REPLACE([locations].[name], '-', '.'), 3), 2, 1)) = 0 THEN 0
		--	ELSE SUBSTRING(PARSENAME(REPLACE([locations].[name], '-', '.'), 3), 2, 1) 
		--END AS floor

	FROM [APCSProDB].[trans].[locations]

	WHERE name like @rackName AND wh_code in (1,2,3)

	GROUP BY name
	ORDER BY name
END
