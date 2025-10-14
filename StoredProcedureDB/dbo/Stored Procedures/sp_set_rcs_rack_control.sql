-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_rcs_rack_control]
	-- Add the parameters for the stored procedure here
	@OPId int
	, @RackName varchar(50)
	--, @PkgName char(20)
	--, @DevName char(20)
	, @PkgId int
	, @DevId int
	, @JobId varchar(255), @Flag int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here

	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	([record_at]
      , [record_class]
      , [login_name]
      , [hostname]
      , [appname]
      , [command_text])
	SELECT GETDATE()
		,'4'
		,ORIGINAL_LOGIN()
		,HOST_NAME()
		,APP_NAME()
		--,''
		,'EXEC [dbo].[sp_set_rcs_rack_control] @OPNoId = ''' + CONVERT (varchar (5), @OPId) + ''', @Rack = ''' + @RackName + ''', @JobId = ''' + @JobId + ''', @PkgId = ''' + CONVERT (varchar (5), @PkgId) + ''', @DiveId =''' + CONVERT (varchar (5), @DevId) + ''''

	--DECLARE @PkgId int, @DevId int, @Pri int -- Variable for Insert
	DECLARE @Pri int
	DECLARE @oldFlow varchar(255), @oldPkg int, @oldDev int, @oldPri int -- Variable for Delete

	--SELECT @PkgId = pkg.id
	--FROM APCSProDB.method.packages AS pkg
	--WHERE name like @PkgName

	--SELECT @DevId = dev.id
	--FROM APCSProDB.method.device_names AS dev
	--WHERE name like @DevName

	--SELECT @PkgId, @DevId

	If(@Flag = 1) -- Add newData
	BEGIN
		--If(@RackName IS NOT NULL AND @PkgId = 'NULL' AND @DeveId = 'NULL' AND @JobId = 'NULL') -- Delete all Row of this RackName
		--BEGIN
			--WHILE ((SELECT COUNT(*) FROM DBx.dbo.rcs_controls WHERE name = @RackName) > 0) -- Loop Delete and Set newPri
			--BEGIN
			--	SELECT TOP(1) @oldFlow = job_id, @oldPkg = package_id, @oldDev = device_id, @oldPri = priorities -- Select wanted to delete Data
			--	FROM DBx.dbo.rcs_controls
			--	WHERE name = @RackName
		
			--	DELETE DBx.dbo.rcs_controls
			--	WHERE name = @RackName AND job_id = @oldFlow AND package_id = @oldPkg AND device_id = @oldDev AND priorities = @oldPri
			
			--	UPDATE DBx.dbo.rcs_controls
			--	SET priorities = priorities - 1
			--	WHERE name != @RackName AND job_id = @oldFlow AND package_id = @oldPkg AND device_id = @oldDev AND priorities > @oldPri
			--END
		--END
		--ELSE
		BEGIN --Check priorities
			If((SELECT COUNT(*) --Count = 0 -> First Row
				FROM DBx.dbo.rcs_controls
				WHERE package_id = @PkgId AND device_id = @DevId AND job_id = @JobId) = 0) 
			BEGIN
				INSERT DBx.dbo.rcs_controls (name, job_id, package_id, device_id, priorities, updated_by) 
				VALUES (@RackName,
						@JobId,
						@PkgId,
						@DevId,
						'1',
						@OPId)
			END
			ELSE --Count > 0 -> Not First Row of this Data -> newPri = lastPri + 1
			BEGIN
				IF((SELECT COUNT(*) --Count > 0 -> Not Found in self-Rack
					FROM DBx.dbo.rcs_controls
					WHERE name = @RackName AND package_id = @PkgId AND device_id = @DevId AND job_id = @JobId) <= 0)
				BEGIN
					INSERT DBx.dbo.rcs_controls (name, job_id, package_id, device_id, priorities, updated_by)
					VALUES (@RackName,
							@JobId,
							@PkgId,
							@DevId,
							(SELECT TOP(1) priorities
							 FROM DBx.dbo.rcs_controls
							 WHERE package_id = @PkgId AND device_id = @DevId AND job_id = @JobId
							 ORDER BY priorities desc) + 1,
							@OPId)
				END				
			END
		END
	END
	ELSE -- Remove oldData that not in newData
	BEGIN
		SELECT TOP(1) @oldFlow = job_id, @oldPkg = package_id, @oldDev = device_id, @oldPri = priorities -- Select wanted to delete Data
		FROM DBx.dbo.rcs_controls
		WHERE name = @RackName AND job_id = @JobId AND package_id = @PkgId AND device_id = @DevId

		DELETE DBx.dbo.rcs_controls
		WHERE name = @RackName AND job_id = @oldFlow AND package_id = @oldPkg AND device_id = @oldDev

		WHILE((SELECT COUNT(*) FROM DBx.dbo.rcs_controls WHERE name != @RackName AND job_id = @JobId AND package_id = @PkgId AND device_id = @DevId AND priorities > @oldPri) > 0)
		BEGIN		
			UPDATE DBx.dbo.rcs_controls
			SET priorities = priorities - 1
			WHERE name != @RackName AND job_id = @oldFlow AND package_id = @oldPkg AND device_id = @oldDev AND priorities > @oldPri
		END
	END
END
