-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_lcl]
	-- Add the parameters for the stored procedure here
       @lot_no AS VARCHAR(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @lot_id AS INT,
			@sf_id AS INT,
			@is_sf AS INT,
			@device_id AS INT,
			@job_id AS INT,
			@lcl_value AS DECIMAL(18,0),
			@to_job_id AS INT

		IF NOT EXISTS(SELECT 1 FROM [APCSProDB].[trans].[lots] WHERE lot_no = @lot_no) 
		BEGIN
			SELECT 'FALSE' as Is_Pass,'Lot No. is not registered. !!'   AS Error_Message_ENG
								,N'Lot No นี้ยังไม่ถูกลงทะเบียน !!' AS Error_Message_THA
								,N'กรุณาตรวจสอบเลข Lot No' AS Handling
								,NULL AS lcl
			RETURN
		END

		SELECT @lot_id = id, 
				@is_sf = is_special_flow, 
				@sf_id = special_flow_id, 
				@device_id = act_device_name_id,
				@job_id = act_job_id
		FROM [APCSProDB].[trans].[lots] 	
		WHERE lot_no = @lot_no


		--//////////////// Master FLOW
		IF @is_sf = 0 BEGIN
				--//////// Flow OS, GO/NG default LCL Value = 1
				IF @job_id = 50 or @job_id = 366 BEGIN
					SELECT 'TRUE' as Is_Pass,'' AS Error_Message_ENG
							,N'' AS Error_Message_THA
							,N'' AS Handling
							,1 AS lcl 	
				END
				ELSE IF @job_id = 88 or @job_id = 278 BEGIN
					SELECT 'TRUE' as Is_Pass,'' AS Error_Message_ENG
							,N'' AS Error_Message_THA
							,N'' AS Handling
							,0 AS lcl 	
				END
				ELSE BEGIN	
					--//////// check job commons
					IF EXISTS(SELECT 1 FROM APCSProDB.trans.job_commons WHERE job_id = @job_id) BEGIN
						SELECT @to_job_id = to_job_id FROM APCSProDB.trans.job_commons WHERE job_id = @job_id
						--//////// job commons
							IF (NOT EXISTS(SELECT lcl
										FROM [APCSProDB].[trans].[lots] INNER JOIN
										[APCSProDB].[trans].[lcl_masters] on [APCSProDB].[trans].[lots].act_device_name_id = [APCSProDB].[trans].[lcl_masters].[device_id] 		
										WHERE lot_no = @lot_no and [APCSProDB].[trans].[lcl_masters].[job_id] = @to_job_id))
							BEGIN
								SELECT 'FALSE' as Is_Pass,'Devcie Name and Flow name are not register LCL data. !!'   AS Error_Message_ENG
								,N'Devcie และ Flow นี้ยังไม่ถูกลงทะเบียนข้อมูล LCL !!' AS Error_Message_THA
								,N'กรุณาตรวจสอบ DeviceName ที่เว็บ QYI หรือ ติดต่อแผนก QYI' AS Handling
								,NULL AS lcl
								RETURN
							END

							SELECT 'TRUE' as Is_Pass,'' AS Error_Message_ENG
									,N'' AS Error_Message_THA
									,N'' AS Handling
									,lcl 
								FROM [APCSProDB].[trans].[lots] INNER JOIN
										[APCSProDB].[trans].[lcl_masters] on [APCSProDB].[trans].[lots].act_device_name_id = [APCSProDB].[trans].[lcl_masters].[device_id] 
							WHERE lot_no = @lot_no and [APCSProDB].[trans].[lcl_masters].[job_id] = @to_job_id

						RETURN
					END
					ELSE BEGIN
						--//////// job not commons
						IF (NOT EXISTS(SELECT lcl
							FROM [APCSProDB].[trans].[lots] INNER JOIN
									[APCSProDB].[trans].[lcl_masters] on [APCSProDB].[trans].[lots].act_device_name_id = [APCSProDB].[trans].[lcl_masters].[device_id] 
								
							WHERE lot_no = @lot_no AND [APCSProDB].[trans].[lcl_masters].[job_id] = @job_id))
						BEGIN
							SELECT 'FALSE' as Is_Pass,'Devcie Name and Flow name are not register LCL data. !!'   AS Error_Message_ENG
								,N'Devcie และ Flow นี้ยังไม่ถูกลงทะเบียนข้อมูล LCL !!' AS Error_Message_THA
								,N'กรุณาตรวจสอบ DeviceName ที่เว็บ QYI หรือ ติดต่อแผนก QYI' AS Handling
								,NULL AS lcl
							RETURN
						END

						SELECT 'TRUE' as Is_Pass,'' AS Error_Message_ENG
							,N'' AS Error_Message_THA
							,N'' AS Handling
							,lcl 
						FROM [APCSProDB].[trans].[lots] INNER JOIN
								[APCSProDB].[trans].[lcl_masters] on [APCSProDB].[trans].[lots].act_device_name_id = [APCSProDB].[trans].[lcl_masters].[device_id] 
								
						WHERE lot_no = @lot_no AND [APCSProDB].[trans].[lcl_masters].[job_id] = @job_id

						RETURN
					END
				END
		END

		--//////////////// SPECIAL FLOW
		ELSE IF @is_sf = 1 BEGIN
			DECLARE @job_id_sf AS INT
			SELECT @job_id_sf = lsf.job_id
						FROM [APCSProDB].[trans].[lots] INNER JOIN
						APCSProDB.trans.special_flows sf ON sf.id = lots.special_flow_id INNER JOIN 
						APCSProDB.trans.lot_special_flows lsf ON lsf.special_flow_id = sf.id AND sf.step_no = lsf.step_no 
						WHERE lot_no = @lot_no

				--//////// Flow OS, GO/NG default LCL Value = 1
				IF @job_id_sf = 50 or @job_id_sf = 366 BEGIN
					SELECT 'TRUE' as Is_Pass,'' AS Error_Message_ENG
							,N'' AS Error_Message_THA
							,N'' AS Handling
							,1 AS lcl 		
				END
				ELSE IF @job_id = 88 or @job_id = 278 BEGIN
					SELECT 'TRUE' as Is_Pass,'' AS Error_Message_ENG
							,N'' AS Error_Message_THA
							,N'' AS Handling
							,0 AS lcl 	
				END
				ELSE BEGIN	
					--//////// check job commons
					IF EXISTS(SELECT 1 FROM APCSProDB.trans.job_commons WHERE job_id = @job_id_sf) BEGIN
						SELECT @to_job_id = to_job_id FROM APCSProDB.trans.job_commons WHERE job_id = @job_id_sf
						--//////// job commons
							IF (NOT EXISTS(SELECT lcl
										FROM [APCSProDB].[trans].[lots] INNER JOIN
										[APCSProDB].[trans].[lcl_masters] on [APCSProDB].[trans].[lots].act_device_name_id = [APCSProDB].[trans].[lcl_masters].[device_id] 		
										WHERE lot_no = @lot_no and [APCSProDB].[trans].[lcl_masters].[job_id] = @to_job_id))
							BEGIN
								SELECT 'FALSE' as Is_Pass,'Devcie Name and Flow name are not register LCL data. !!'   AS Error_Message_ENG
								,N'Devcie และ Flow นี้ยังไม่ถูกลงทะเบียนข้อมูล LCL !!' AS Error_Message_THA
								,N'กรุณาตรวจสอบ DeviceName ที่เว็บ QYI หรือ ติดต่อแผนก QYI' AS Handling
								,NULL AS lcl
								RETURN
							END

							SELECT 'TRUE' as Is_Pass,'' AS Error_Message_ENG
									,N'' AS Error_Message_THA
									,N'' AS Handling
									,lcl 
								FROM [APCSProDB].[trans].[lots] INNER JOIN
										[APCSProDB].[trans].[lcl_masters] on [APCSProDB].[trans].[lots].act_device_name_id = [APCSProDB].[trans].[lcl_masters].[device_id] 
							WHERE lot_no = @lot_no and [APCSProDB].[trans].[lcl_masters].[job_id] = @to_job_id

						RETURN
					END
					ELSE BEGIN
						--//////// job not commons
						IF (NOT EXISTS(SELECT lcl
							FROM [APCSProDB].[trans].[lots] INNER JOIN
									[APCSProDB].[trans].[lcl_masters] on [APCSProDB].[trans].[lots].act_device_name_id = [APCSProDB].[trans].[lcl_masters].[device_id] 
								
							WHERE lot_no = @lot_no AND  [APCSProDB].[trans].[lcl_masters].[job_id] = @job_id_sf))
						BEGIN
							SELECT 'FALSE' as Is_Pass,'Devcie Name and Flow name are not register LCL data. !!'   AS Error_Message_ENG
								,N'Devcie และ Flow นี้ยังไม่ถูกลงทะเบียนข้อมูล LCL !!' AS Error_Message_THA
								,N'กรุณาตรวจสอบ DeviceName ที่เว็บ QYI หรือ ติดต่อแผนก QYI' AS Handling
								,NULL AS lcl
							RETURN
						END

						SELECT 'TRUE' as Is_Pass,'' AS Error_Message_ENG
							,N'' AS Error_Message_THA
							,N'' AS Handling
							,lcl 
						FROM [APCSProDB].[trans].[lots] INNER JOIN
								[APCSProDB].[trans].[lcl_masters] on [APCSProDB].[trans].[lots].act_device_name_id = [APCSProDB].[trans].[lcl_masters].[device_id] 
								
						WHERE lot_no = @lot_no AND  [APCSProDB].[trans].[lcl_masters].[job_id] = @job_id_sf

						RETURN
					END
				END

		END
END
