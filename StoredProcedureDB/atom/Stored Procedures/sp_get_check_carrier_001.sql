
CREATE PROCEDURE [atom].[sp_get_check_carrier_001]
	@lot_no nvarchar(20) = NULL,
	@carrier_no varchar(11) = NULL,
	@next_carrier_no varchar(11) = NULL,
	@mc_no varchar(50) = NULL, 
	@app_name varchar(50) = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	---------------------------------------------------------
	--- Declare
	---------------------------------------------------------<< Declare	
	DECLARE @dcarrier_no VARCHAR(20) = NULL
	DECLARE @dnext_carrier_no VARCHAR(20) = NULL
	DECLARE @old_carrier_no VARCHAR(20) = NULL
	DECLARE @old_next_carrier_no VARCHAR(20) = NULL
	DECLARE @success_status INT = 0
	DECLARE @chk_carrier_no INT = 0
	DECLARE @chk_next_carrier_no INT = 0
	DECLARE @type_carrier INT = 0 -- 1:Carrier 2:NextCarrier
	--------------------------------------------------------->> Declare

	---------------------------------------------------------
	--- Check type carrier
	---------------------------------------------------------<< Check type carrier
	SET @carrier_no = ISNULL(@carrier_no,'');
	SET @next_carrier_no = ISNULL(@next_carrier_no,'');

	IF (@carrier_no = '' AND @next_carrier_no = '') -- Carrier and NextCarrier is null
	BEGIN
		-----------------------------------------------
		SELECT 'FALSE' as Is_Pass
			, 'Carrier is null and UnloadCarrier is null !!' AS Error_Message_ENG
			, N'Carrier และ UnloadCarrier เป็นค่าว่าง !!' AS Error_Message_THA
			, N'กรุณาตรวจสอบข้อมูล !!' AS Handling 
		RETURN;
		-----------------------------------------------
	END
	ELSE
	BEGIN
		---------------------------------------------------------
		--- Set type carrier
		---------------------------------------------------------<< Set type carrier
		IF (@carrier_no != '')
		BEGIN
			SET @type_carrier = 1;
		END
		ELSE IF (@next_carrier_no != '')
		BEGIN
			SET @type_carrier = 2;
		END
		--------------------------------------------------------->> Set type carrier
	END
	--------------------------------------------------------->> Check type carrier

	---------------------------------------------------------
	--- Condition
	---------------------------------------------------------<< Condition
	IF (@type_carrier = 1)
	BEGIN
		---------------------------------------------------------
		--- Condition Carrier
		---------------------------------------------------------<< Condition Carrier
		--- Check Carrier
		SET @chk_carrier_no = (
			SELECT COUNT([carrier_no]) 
			FROM [APCSProDB].[trans].[lots] 
			WHERE [carrier_no] = @carrier_no 
			  AND [lot_no] != @lot_no
			  AND [wip_state] IN (0,10,20)
		);

		SET @chk_next_carrier_no = (
			SELECT COUNT([next_carrier_no]) 
			FROM [APCSProDB].[trans].[lots] 
			WHERE [next_carrier_no] = @carrier_no 
			  AND [lot_no] != @lot_no
			  AND [wip_state] IN (0,10,20)
		);
		
		--- Check Carrier Format
		IF (LEN(@carrier_no) = 11)
		BEGIN
			---------------------------------------------------------
			--- Format 000-00-0000
			---------------------------------------------------------<< Format 000-00-0000
			IF (SUBSTRING(@carrier_no,4,1)= '-' AND SUBSTRING(@carrier_no,7,1) = '-')
			BEGIN
				---------------------------------------------------------
				--- Format true
				---------------------------------------------------------<< Format true
				IF (@chk_carrier_no = 0 AND @chk_next_carrier_no = 0)
				BEGIN
					--- Check register in db
					IF EXISTS (
						SELECT TOP 1 [jigs].[qrcodebyuser]
						FROM [APCSProDB].[jig].[categories]
						INNER JOIN [APCSProDB].[jig].[productions] 
							ON [categories].[id] = [productions].[category_id]
						INNER JOIN APCSProDB.trans.jigs 
							ON [productions].[id] = [jigs].[jig_production_id]
						WHERE [categories].[short_name] = 'Carrier'
						  AND ([jigs].[qrcodebyuser] = @next_carrier_no OR [jigs].[barcode] = @next_carrier_no)
					)
					BEGIN
						SELECT 'FALSE' as Is_Pass
							, 'Carrier not register !!' AS Error_Message_ENG
							, N'Carrier ยังไม่ถูกลงทะเบียน !!' AS Error_Message_THA
							, N'กรุณาตรวจสอบข้อมูล !!' AS Handling;
						RETURN;
					END

					--- Get Carrier, NextCarrier
					SELECT @old_carrier_no = (CASE WHEN carrier_no = '-' OR carrier_no = '' OR carrier_no IS NULL THEN NULL ELSE carrier_no END)
						, @old_next_carrier_no = (CASE WHEN next_carrier_no = '-' OR next_carrier_no = '' OR next_carrier_no IS NULL THEN NULL ELSE next_carrier_no END)
					FROM APCSProDB.trans.lots 
					WHERE lot_no = @lot_no;

					IF (@carrier_no = @old_carrier_no)
					BEGIN
						SELECT 'FALSE' as Is_Pass
							, 'Carrier are already used with this LotNo !!' AS Error_Message_ENG
							, N'Carrier ถูกใช้กับ LotNo นี้อยู่แล้ว !!' AS Error_Message_THA
							, N'กรุณาตรวจสอบข้อมูล !!' AS Handling;
						RETURN;
					END
					ELSE IF (@carrier_no = @old_next_carrier_no)
					BEGIN
						SELECT 'FALSE' as Is_Pass
							, 'Carrier is usered to UnloadCarrier with this LotNo !!' AS Error_Message_ENG
							, N'Carrier ถูกใช้งานเป็น UnloadCarrier กับ LotNo นี้อยู่แล้ว !!' AS Error_Message_THA
							, N'กรุณาตรวจสอบข้อมูล !!' AS Handling;
						RETURN;
					END
					ELSE
					BEGIN
						SET @success_status = 1;
					END
				END
				ELSE
				BEGIN
					---------------------------------------------------------
					--- Carrier is usered
					---------------------------------------------------------<< Carrier is usered
					IF (@chk_carrier_no > 0 AND @chk_next_carrier_no > 0)
					BEGIN
						SELECT 'FALSE' as Is_Pass
							, 'Carrier is usered !!' AS Error_Message_ENG
							, N'Carrier ถูกใช้งานแล้ว !!' AS Error_Message_THA
							, N'กรุณาตรวจสอบข้อมูล !!' AS Handling;
						RETURN;
					END
					ELSE IF (@chk_carrier_no > 0 AND @chk_next_carrier_no = 0)
					BEGIN
						SELECT 'FALSE' as Is_Pass
							, 'Carrier is usered !!' AS Error_Message_ENG
							, N'Carrier ถูกใช้งานแล้ว !!' AS Error_Message_THA
							, N'กรุณาตรวจสอบข้อมูล !!' AS Handling;
						RETURN;
					END
					ELSE IF (@chk_carrier_no = 0 AND @chk_next_carrier_no > 0)
					BEGIN
						SELECT 'FALSE' as Is_Pass
							, 'Carrier is usered to UnloadCarrier !!' AS Error_Message_ENG
							, N'Carrier ถูกใช้งานเป็น UnloadCarrier แล้ว !!' AS Error_Message_THA
							, N'กรุณาตรวจสอบข้อมูล !!' AS Handling;
						RETURN;
					END
					--------------------------------------------------------->> Carrier is usered
				END
				--------------------------------------------------------->> Format true
			END
			ELSE BEGIN
				---------------------------------------------------------
				--- Format false
				---------------------------------------------------------<< Format false
				SELECT 'FALSE' as Is_Pass
					, 'Carrier format is invalid !!' AS Error_Message_ENG
					, N'รูปแบบ Carrier ไม่ถูกต้อง !!' AS Error_Message_THA
					, N'กรุณาตรวจสอบข้อมูล !!' AS Handling;
				RETURN;
				--------------------------------------------------------->> Format false
			END
			--------------------------------------------------------->> Format 000-00-0000
		END
		ELSE BEGIN
			---------------------------------------------------------
			--- Format error
			---------------------------------------------------------<< Format error
			SELECT 'FALSE' as Is_Pass
				, 'Carrier format is invalid !!' AS Error_Message_ENG
				, N'รูปแบบ Carrier ไม่ถูกต้อง !!' AS Error_Message_THA
				, N'กรุณาตรวจสอบข้อมูล !!' AS Handling;
			RETURN;
			--------------------------------------------------------->> Format error
		END
		--------------------------------------------------------->> Condition Carrier 
	END
	ELSE IF (@type_carrier = 2)
	BEGIN
		---------------------------------------------------------
		--- Condition UnloadCarrier
		---------------------------------------------------------<< Condition UnloadCarrier
		--- Check UnloadCarrier
		SET @chk_carrier_no = (
			SELECT COUNT([carrier_no]) 
			FROM [APCSProDB].[trans].[lots] 
			WHERE [carrier_no] = @next_carrier_no 
			  AND [lot_no] != @lot_no
			  AND [wip_state] IN (0,10,20)
		);

		SET @chk_next_carrier_no = (
			SELECT COUNT([next_carrier_no]) 
			FROM [APCSProDB].[trans].[lots] 
			WHERE [next_carrier_no] = @next_carrier_no 
			  AND [lot_no] != @lot_no
			  AND [wip_state] IN (0,10,20)
		);
		
		--- Check UnloadCarrier Format
		IF (LEN(@next_carrier_no) = 11)
		BEGIN
			---------------------------------------------------------
			--- Format 000-00-0000
			---------------------------------------------------------<< Format 000-00-0000
			IF (SUBSTRING(@next_carrier_no,4,1)= '-' AND SUBSTRING(@next_carrier_no,7,1) = '-')
			BEGIN
				---------------------------------------------------------
				--- Format true
				---------------------------------------------------------<< Format true
				IF (@chk_carrier_no = 0 AND @chk_next_carrier_no = 0)
				BEGIN
					--- Check register in db
					IF EXISTS (
						SELECT TOP 1 [jigs].[qrcodebyuser]
						FROM [APCSProDB].[jig].[categories]
						INNER JOIN [APCSProDB].[jig].[productions] 
							ON [categories].[id] = [productions].[category_id]
						INNER JOIN APCSProDB.trans.jigs 
							ON [productions].[id] = [jigs].[jig_production_id]
						WHERE [categories].[short_name] = 'Carrier'
						  AND ([jigs].[qrcodebyuser] = @next_carrier_no OR [jigs].[barcode] = @next_carrier_no)
					)
					BEGIN
						SELECT 'FALSE' as Is_Pass
							, 'UnloadCarrier not register !!' AS Error_Message_ENG
							, N'UnloadCarrier ยังไม่ถูกลงทะเบียน !!' AS Error_Message_THA
							, N'กรุณาตรวจสอบข้อมูล !!' AS Handling;
						RETURN;
					END

					--- Get Carrier, UnloadCarrier
					SELECT @old_carrier_no = (CASE WHEN carrier_no = '-' OR carrier_no = '' OR carrier_no IS NULL THEN NULL ELSE carrier_no END)
						, @old_next_carrier_no = (CASE WHEN next_carrier_no = '-' OR next_carrier_no = '' OR next_carrier_no IS NULL THEN NULL ELSE next_carrier_no END)
					FROM APCSProDB.trans.lots 
					WHERE lot_no = @lot_no;

					IF (@next_carrier_no = @old_carrier_no)
					BEGIN
						SELECT 'FALSE' as Is_Pass
							, 'UnloadCarrier is usered to Carrier with this LotNo !!' AS Error_Message_ENG
							, N'UnloadCarrier ถูกใช้งานเป็น Carrier กับ LotNo นี้อยู่แล้ว !!' AS Error_Message_THA
							, N'กรุณาตรวจสอบข้อมูล !!' AS Handling;
						RETURN;
					END
					ELSE IF (@next_carrier_no = @old_next_carrier_no)
					BEGIN
						SELECT 'FALSE' as Is_Pass
							, 'UnloadCarrier are already used with this LotNo !!' AS Error_Message_ENG
							, N'UnloadCarrier ถูกใช้กับ LotNo นี้อยู่แล้ว !!' AS Error_Message_THA
							, N'กรุณาตรวจสอบข้อมูล !!' AS Handling;
						RETURN;
					END
					ELSE
					BEGIN
						SET @success_status = 1;
					END
				END
				ELSE
				BEGIN
					---------------------------------------------------------
					--- UnloadCarrier is usered
					---------------------------------------------------------<< UnloadCarrier is usered
					IF (@chk_carrier_no > 0 AND @chk_next_carrier_no > 0)
					BEGIN
						SELECT 'FALSE' as Is_Pass
							, 'UnloadCarrier is usered !!' AS Error_Message_ENG
							, N'UnloadCarrier ถูกใช้งานแล้ว !!' AS Error_Message_THA
							, N'กรุณาตรวจสอบข้อมูล !!' AS Handling;
						RETURN;
					END
					ELSE IF (@chk_carrier_no > 0 AND @chk_next_carrier_no = 0)
					BEGIN
		
						SELECT 'FALSE' as Is_Pass
							, 'UnloadCarrier is usered to Carrier !!' AS Error_Message_ENG
							, N'UnloadCarrier ถูกใช้งานเป็น Carrier แล้ว !!' AS Error_Message_THA
							, N'กรุณาตรวจสอบข้อมูล !!' AS Handling;
						RETURN;
					END
					ELSE IF (@chk_carrier_no = 0 AND @chk_next_carrier_no > 0)
					BEGIN
						SELECT 'FALSE' as Is_Pass
							, 'UnloadCarrier is usered !!' AS Error_Message_ENG
							, N'UnloadCarrier ถูกใช้งานแล้ว !!' AS Error_Message_THA
							, N'กรุณาตรวจสอบข้อมูล !!' AS Handling;
						RETURN;
					END
					--------------------------------------------------------->> UnloadCarrier is usered
				END
				--------------------------------------------------------->> Format true
			END
			ELSE BEGIN
				---------------------------------------------------------
				--- Format false
				---------------------------------------------------------<< Format false
				SELECT 'FALSE' as Is_Pass
					, 'UnloadCarrier format is invalid !!' AS Error_Message_ENG
					, N'รูปแบบ UnloadCarrier ไม่ถูกต้อง !!' AS Error_Message_THA
					, N'กรุณาตรวจสอบข้อมูล !!' AS Handling;
				RETURN;
				--------------------------------------------------------->> Format false
			END
			--------------------------------------------------------->> Format 000-00-0000
		END
		ELSE BEGIN
			---------------------------------------------------------
			--- Format error
			---------------------------------------------------------<< Format error
			SELECT 'FALSE' as Is_Pass
				, 'UnloadCarrier format is invalid !!' AS Error_Message_ENG
				, N'รูปแบบ UnloadCarrier ไม่ถูกต้อง !!' AS Error_Message_THA
				, N'กรุณาตรวจสอบข้อมูล !!' AS Handling;
			RETURN;
			--------------------------------------------------------->> Format error
		END
		--------------------------------------------------------->> Condition UnloadCarrier 
	END
	--------------------------------------------------------->> Condition

	---------------------------------------------------------
	--- Result
	---------------------------------------------------------<< Result
	IF (@success_status = 1)
	BEGIN
		SELECT 'TRUE' as Is_Pass
			, '' AS Error_Message_ENG
			, N'' AS Error_Message_THA
			, N'' AS Handling
		RETURN;
	END
	--------------------------------------------------------->> Result
END
