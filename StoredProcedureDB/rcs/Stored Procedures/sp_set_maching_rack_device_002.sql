-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [rcs].[sp_set_maching_rack_device_002]
	-- Add the parameters for the stored procedure here
	@rack_control_id INT 
	,@device_id INT
	,@create_by INT

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @priority_old int
		, @priority_new int
		, @rack_name varchar(50)
		, @process varchar(10)
	
	SELECT @rack_name = [name] FROM APCSProDB.rcs.rack_controls
	WHERE rack_controls.id = @rack_control_id

	SET @process = (SELECT SUBSTRING (@rack_name, 
	CHARINDEX('-', @rack_name) + 1, CHARINDEX('-', @rack_name ,CHARINDEX('-', @rack_name) + 1) - CHARINDEX('-', @rack_name) - 1))

	IF EXISTS (SELECT 1 FROM APCSProDB.rcs.rack_devices WHERE rack_control_id = @rack_control_id AND device_id = @device_id)
	BEGIN
		SELECT 'FALSE' AS Is_Pass,'ERROR: Rack_device Already Exists!!' AS Error_Message_ENG,N'ERROR: ข้อมูล Rack และ device มีอยู่แล้ว !!' AS Error_Message_THA
		RETURN;
	END
    -- Insert statements for procedure here
	BEGIN TRANSACTION
	BEGIN TRY
		--check ว่า device นี้เคยมีมาก่อนมั้ย ถ้ามี Max(prio) + 1 ไม่มี set device = 1
		IF EXISTS(SELECT 1 FROM APCSProDB.rcs.rack_devices
			INNER JOIN APCSProDB.rcs.rack_controls ON rack_devices.rack_control_id = rack_controls.id
			WHERE rack_controls.name LIKE '%' + @process + '%'
			AND device_id = @device_id)
		BEGIN
		print 'old device'
			SET @priority_old =
			(SELECT MAX(rack_devices.[priority])
			FROM APCSProDB.rcs.rack_devices
			WHERE device_id = @device_id)

			SET @priority_new = @priority_old + 1

			INSERT INTO APCSProDB.rcs.rack_devices
			VALUES(
				@rack_control_id
				, @device_id
				, GETDATE()
				, @create_by
				, NULL
				, NULL
				, @priority_new
			)

			--SELECT * FROM APCSProDB.rcs.rack_devices
		END
		--ไม่มี set device = 1
		ELSE
		BEGIN
			print 'new device'
			SET @priority_new = 1

			INSERT INTO APCSProDB.rcs.rack_devices
			VALUES(
				@rack_control_id
				, @device_id
				, GETDATE()
				, @create_by
				, NULL
				, NULL
				, @priority_new
			)

			--SELECT * FROM APCSProDB.rcs.rack_devices
		END

		SELECT 'TRUE' AS Is_Pass ,'Register Successfully !!' AS Error_Message_ENG,N'การลงทะเบียนสำเร็จ !!' AS Error_Message_THA		
		COMMIT;

	END TRY
	BEGIN CATCH
		ROLLBACK;
		SELECT 'FALSE' AS Is_Pass ,'Register fail. !!' AS Error_Message_ENG,N'การลงทะเบียนผิดพลาด !!' AS Error_Message_THA
	END CATCH
END
