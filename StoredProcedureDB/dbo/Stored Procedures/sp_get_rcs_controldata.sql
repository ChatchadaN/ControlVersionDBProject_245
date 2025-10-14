-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_rcs_controldata]
	-- Add the parameters for the stored procedure here
	--@LotNo varchar(20), @OPNoId int
	@RackName varchar(20)
AS
BEGIN	
	DECLARE @JobName varchar(MAX)

	SELECT rcs.name		AS RackName
	     , pkg.name		AS PackageName
		 , pkg.id		AS PackageId
		 , dev.name		AS DeviceName
		 , dev.id		AS DeviceId
		 --, STRING_AGG(dev.id, ',') AS DeviceId
		 , rcs.job_id	AS JobId
		 , (SELECT (SELECT (SELECT job.name + ','
		 	  			    FROM APCSProDB.method.jobs AS job 
		 				    WHERE job.id = Id.value)  
		 		    FROM (SELECT TRIM (value) AS value
		    FROM string_split(rcs.job_id, ',')) AS Id FOR XML PATH (''))) AS JobName
	FROM DBx.dbo.rcs_controls AS rcs
	JOIN APCSProDB.method.packages AS pkg ON rcs.package_id = pkg.id
	JOIN APCSProDB.method.device_names AS dev ON rcs.device_id = dev.id
	WHERE rcs.name = @RackName
	--GROUP BY rcs.name, pkg.name, pkg.id, dev.name, rcs.job_id
	ORDER BY rcs.name desc, pkg.name desc, dev.name desc, rcs.job_id desc
END