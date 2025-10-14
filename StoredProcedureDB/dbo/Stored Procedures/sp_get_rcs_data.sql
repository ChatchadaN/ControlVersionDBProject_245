-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_rcs_data]
	-- Add the parameters for the stored procedure here
	@lotNo varchar(10) = '%',
	@rackName varchar(15) = '%'
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	--Search by Lot
	IF(@lotNo != '%')
	BEGIN
		DECLARE @lot_id int
		SELECT @lot_id = id FROM APCSProDB.trans.lots where lot_no = @lotNo

		SELECT TRIM(@lotNo)		AS LotNo
			 , loca.id			AS Location_id
		     , loca.name		AS RackName
		     , CONCAT(loca.x, RIGHT(100+(loca.y), 2)) AS Address
			 , loca.wh_code		AS WHCode
			 , curr.status		AS Status
			 , curr.updated_by	AS Updated_By
			 --, curr.updated_at
		FROM  DBx.dbo.rcs_current_locations		AS curr
		INNER JOIN APCSProDB.trans.locations	AS loca ON curr.location_id = loca.id
		WHERE curr.status != 3 AND curr.lot_id = @lot_id
	END
	--Search by Rack
	ELSE
	BEGIN
		-- Insert statements for procedure here
		DECLARE @hs_job_name varchar(2) = 'TG', @Now datetime = (SELECT GETDATE())
		
		DECLARE @Black		varchar(7) = '#000000',
				@BDDefault	varchar(7) = '#E2E3E3', @BGDefault	varchar(7) = '#FFFFFF',
				@BDOrange	varchar(7) = '#FF872B', @BGOrange	varchar(7) = '#FFCF7F',
				@BGOrange12  varchar(7) = '#FFCC33', @BGOrange24  varchar(7) = '#FF0033'

		DECLARE @Font1 varchar(5) = '0.6vw', 
				@Font2 varchar(5) = '0.7vw', 
				@Font3 varchar(5) = '0.8vw', 
				@Font4 varchar(5) = '1vw', 
				@Font5 varchar(5) = '1.1vw'

		DECLARE @x int, @y int, @z int
		--DECLARE @table Table(rackname varchar(50), x int, y int, z int, cou int, build varchar(1), floor int)
		DECLARE @table Table(rackname varchar(50), x int, y int, z int, cou int, build varchar(1), floor varchar(1))  --modify : 2023/09/25 time : 08.23
		INSERT INTO @table EXEC StoredProcedureDB.dbo.sp_get_rcs_rack_size @rackName = @rackName
		SELECT @x = x, @y = y, @z = z FROM @table

		SELECT TRIM(lots.lot_no) AS LotNo --Believe surpluses.serial_no = lots.lot_no cuz of same lot_id
		     , CASE WHEN loca.wh_code = 2	THEN @hs_job_name
					WHEN lots.is_special_flow = 0 AND mas_tmp.short_name IS NULL	 THEN mas_jobs.short_name
					WHEN lots.is_special_flow = 0 AND mas_tmp.short_name IS NOT NULL THEN mas_tmp.short_name
					WHEN lots.is_special_flow = 1 AND spe_tmp.short_name IS NULL	 THEN spe_jobs.short_name
					ELSE spe_tmp.short_name END AS JobName
			 , TRIM(pkg.name)	AS PkgName
			 , TRIM(dev.name)	AS DevName
			 , loca.name		AS RackName
			 , (SELECT CONCAT(loca.x, RIGHT(100+(loca.y), 2))) AS Address
			 , (SELECT RIGHT(100+(loca.z), 2)) AS Depth
			 , CASE WHEN LEFT(loca.x,1) = 'A' THEN (@y * @z *  0) + ((CONVERT(int, loca.y) - 1) * @z) + CONVERT(int, loca.z)
				    WHEN LEFT(loca.x,1) = 'B' THEN (@y * @z *  1) + ((CONVERT(int, loca.y) - 1) * @z) + CONVERT(int, loca.z)
					WHEN LEFT(loca.x,1) = 'C' THEN (@y * @z *  2) + ((CONVERT(int, loca.y) - 1) * @z) + CONVERT(int, loca.z)
					WHEN LEFT(loca.x,1) = 'D' THEN (@y * @z *  3) + ((CONVERT(int, loca.y) - 1) * @z) + CONVERT(int, loca.z)
					WHEN LEFT(loca.x,1) = 'E' THEN (@y * @z *  4) + ((CONVERT(int, loca.y) - 1) * @z) + CONVERT(int, loca.z)
					WHEN LEFT(loca.x,1) = 'F' THEN (@y * @z *  5) + ((CONVERT(int, loca.y) - 1) * @z) + CONVERT(int, loca.z)
					WHEN LEFT(loca.x,1) = 'G' THEN (@y * @z *  6) + ((CONVERT(int, loca.y) - 1) * @z) + CONVERT(int, loca.z)
					WHEN LEFT(loca.x,1) = 'H' THEN (@y * @z *  7) + ((CONVERT(int, loca.y) - 1) * @z) + CONVERT(int, loca.z)
					WHEN LEFT(loca.x,1) = 'I' THEN (@y * @z *  8) + ((CONVERT(int, loca.y) - 1) * @z) + CONVERT(int, loca.z)
					WHEN LEFT(loca.x,1) = 'J' THEN (@y * @z *  9) + ((CONVERT(int, loca.y) - 1) * @z) + CONVERT(int, loca.z)
					WHEN LEFT(loca.x,1) = 'K' THEN (@y * @z * 10) + ((CONVERT(int, loca.y) - 1) * @z) + CONVERT(int, loca.z)
					ELSE (@y * @z * 11) + ((CONVERT(int, loca.y) - 1) * @z) + CONVERT(int, loca.z)
			   END	AS Sequence
			 , curr.status	AS Status
			 , (SELECT CONCAT((DATEDIFF(HOUR, curr.updated_at, @Now))/24, 'D ', 
			                  (DATEDIFF(HOUR, curr.updated_at, @Now))%24, 'H ', 
							  (DATEDIFF(MINUTE, curr.updated_at, @Now))%60, 'M ')) AS UpdateTime
			, CASE WHEN (DATEDIFF(HOUR, curr.updated_at, GETDATE()) >= 12 and DATEDIFF(MINUTE, curr.updated_at, GETDATE()) <= 24) THEN 1
				   WHEN DATEDIFF(HOUR, curr.updated_at, GETDATE()) >= 24 THEN 2
			  ELSE 0 END	AS CHKHR
			, CASE WHEN @x <= 6 AND LEN(pkg.name) <= 18 THEN @Font5
			   		WHEN @x <= 6 AND LEN(pkg.name) >  18 THEN @Font4
			   		WHEN @x >  6 AND LEN(pkg.name) <= 16 THEN @Font3
			   		WHEN @x >  6 AND LEN(pkg.name) <  16 AND LEN(pkg.name) >= 18 THEN @Font2
			   		ELSE @Font1 
			   END	AS SizePkg
			 , CASE WHEN @x <= 6 AND LEN(dev.name) <= 18 THEN @Font5
			  	    WHEN @x <= 6 AND LEN(dev.name) >  18 THEN @Font4
			  	    WHEN @x >  6 AND LEN(dev.name) <= 16 THEN @Font3
			  	    WHEN @x >  6 AND LEN(dev.name) <  16 AND LEN(dev.name) >= 18 THEN @Font2
			  	    ELSE @Font1 
			   END	AS SizeDev
			 , CASE WHEN loca.wh_code = 2			THEN @Black
			 		WHEN lots.is_special_flow = 0 AND mas_tmp.job_id IS NOT NULL THEN mas_tmp.font_color
			 		WHEN lots.is_special_flow = 1 AND spe_tmp.job_id IS NOT NULL THEN spe_tmp.font_color
			 		ELSE @Black
			   END	AS FontColor
			 , CASE WHEN loca.wh_code = 2			THEN @BDOrange
			 		WHEN lots.is_special_flow = 0 AND mas_tmp.job_id IS NOT NULL THEN mas_tmp.bd_color
			 		WHEN lots.is_special_flow = 1 AND spe_tmp.job_id IS NOT NULL THEN spe_tmp.bd_color
			 		ELSE @BDDefault
			   END	AS BDColor
			 , CASE WHEN loca.wh_code = 2			THEN @BGOrange
			 		WHEN lots.is_special_flow = 0 AND mas_tmp.job_id IS NOT NULL THEN mas_tmp.bg_color
			 		WHEN lots.is_special_flow = 1 AND spe_tmp.job_id IS NOT NULL THEN spe_tmp.bg_color
			 		ELSE @BGDefault
			   END	AS BGColor
			 , CASE WHEN (DATEDIFF(HOUR, curr.updated_at, GETDATE()) >= 12 and DATEDIFF(HOUR, curr.updated_at, GETDATE()) < 24) THEN @BGOrange12
					WHEN DATEDIFF(HOUR, curr.updated_at, GETDATE()) >= 24 THEN @BGOrange24
					ELSE @BGDefault
			   END	AS BGColor1

		FROM      DBx.dbo.rcs_current_locations		AS curr
		LEFT JOIN APCSProDB.trans.locations			AS loca		ON curr.location_id = loca.id
		LEFT JOIN APCSProDB.trans.lots				AS lots		ON curr.lot_id = lots.id
		LEFT JOIN APCSProDB.method.packages			AS pkg		ON lots.act_package_id = pkg.id
		LEFT JOIN APCSProDB.method.device_names		AS dev		ON lots.act_device_name_id = dev.id
		LEFT JOIN APCSProDB.method.jobs				AS mas_jobs	ON lots.is_special_flow = 0 AND lots.act_job_id = mas_jobs.id
		LEFT JOIN DBx.dbo.rcs_settings				AS mas_tmp	ON lots.is_special_flow = 0 AND mas_jobs.id = mas_tmp.job_id
		LEFT JOIN APCSProDB.trans.special_flows		AS spe		ON lots.is_special_flow = 1 AND lots.special_flow_id = spe.id
		LEFT JOIN APCSProDB.trans.lot_special_flows	AS lot_spe	ON lots.is_special_flow = 1 AND spe.id = lot_spe.special_flow_id AND spe.step_no = lot_spe.step_no
		LEFT JOIN APCSProDB.method.jobs				AS spe_jobs	ON lots.is_special_flow = 1 AND lot_spe.job_id = spe_jobs.id
		LEFT JOIN DBx.dbo.rcs_settings				AS spe_tmp	ON lots.is_special_flow = 1 AND spe_jobs.id = spe_tmp.job_id

		WHERE curr.status != 3 AND loca.name = @rackName
		ORDER BY loca.address
	END
END
