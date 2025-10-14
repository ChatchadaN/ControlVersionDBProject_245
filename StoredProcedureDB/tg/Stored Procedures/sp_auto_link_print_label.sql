

CREATE PROCEDURE [tg].[sp_auto_link_print_label] 
	-- Add the parameters for the stored procedure here
	@LotNo VARCHAR(10),
	@EmpNo VARCHAR(10),
	@MachineID INT = NULL,
	@TypeOfLabel INT = NULL,
	@NoReel INT = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @Factory_Code INT --# 64646 RIST | 61300 REMA
	DECLARE @PCCode INT --# [lots].[pc_instruction_code]
	DECLARE @Machine VARCHAR(MAX) --# [machines].[name]
	DECLARE @BaseURL VARCHAR(MAX) 
	DECLARE @IsARC BIT = 0 --# (1) All Reel | (0) Reel By Reel
	DECLARE @Link VARCHAR(MAX) 
	DECLARE @TypeLotNo VARCHAR(1)
	DECLARE @PrintMode VARCHAR(MAX)
	DECLARE @Version INT = 0
	
	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	(
		  [record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no]
	)
	SELECT GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'EXEC [tg].[sp_auto_link_print_label]  @LotNo = ''' + ISNULL(@LotNo,'') 
				+ ''', @EmpNo = ''' + ISNULL(@EmpNo,'') 
				+ ''', @MachineID = ''' + ISNULL(CAST(@MachineID AS varchar(2)),'') 
				+ ''', @TypeOfLabel = ''' + ISNULL(CAST(@TypeOfLabel AS varchar(2)),'') 
				+ ''', @NoReel = ''' + ISNULL(CAST(@NoReel AS varchar(2)),'') + ''''
		, ISNULL(@LotNo,'NULL'); 

	SELECT @Machine = [name] 
	FROM [APCSProDB].[mc].[machines] 
	WHERE [id] = @MachineID

	SELECT @PCCode = [pc_instruction_code]
		, @TypeLotNo = SUBSTRING(@LotNo, 5, 1)
	FROM [APCSProDB].[trans].[lots]
	WHERE [lot_no] = @LotNo

	SELECT @Factory_Code = [factories].[factory_code]
	FROM [APCSProDB].[man].[users]
	INNER JOIN [APCSProDB].[man].[user_organizations] 
		ON [users].[id] = [user_organizations].[user_id]
	INNER JOIN [APCSProDB].[man].[organizations] 
		ON [user_organizations].[organization_id] = [organizations].[id]
	LEFT JOIN [APCSProDB].[man].[headquarters] 
		ON [organizations].[headquarter_id] = [headquarters].[id]
	LEFT JOIN [APCSProDB].[man].[factories] 
		ON [headquarters].[factory_id] = [factories].[id]
	WHERE [users].[emp_num] = @EmpNo

	IF EXISTS (
		SELECT  1 AS [Value]
			,[machines].[name]
		FROM [APCSProDB].[mc].[machines]
		INNER JOIN [APCSProDB].[trans].[machine_jigs] 
			ON [APCSProDB].[mc].[machines].[id] = [APCSProDB].[trans].[machine_jigs].[machine_id]
		INNER JOIN [APCSProDB].[trans].[jigs]
			ON [APCSProDB].[trans].[machine_jigs].[jig_id] = [APCSProDB].[trans].[jigs].[id] 
		INNER JOIN [APCSProDB].[jig].[productions] 
			ON [APCSProDB].[trans].[jigs].[jig_production_id] = [APCSProDB].[jig].[productions].[id] 
		INNER JOIN [APCSProDB].[jig].[categories] 
			ON [APCSProDB].[jig].[productions].[category_id] = [APCSProDB].[jig].[categories].[id] 
		INNER JOIN [APCSProDB].[method].[processes] 
			ON [APCSProDB].[jig].[categories].[lsi_process_id] = [APCSProDB].[method].[processes].[id] 
		INNER JOIN APCSProDB.trans.jig_conditions 
			ON [APCSProDB].[trans].[jigs].[id] = [APCSProDB].[trans].[jig_conditions].[id]
		WHERE status = 'On Machine'
		AND [APCSProDB].[mc].[machines].[id] = @MachineID
		AND [APCSProDB].[jig].[categories].[name] = 'ARC'
	)
	BEGIN
		SET @IsARC = 1
	END

	-- #--------------------------------------------------------------------------------------------------------# --

	IF @Factory_Code IS NULL
	BEGIN
		SELECT 'FALSE' AS [Status] 
			,N'' AS [Result]
			,'Factory_Code is null !!' AS [error_Message_ENG]
			,N'ไม่พบข้อมูล Factory Code!!' AS [error_Message_THA] 
			,N'Please contact system' AS [handling]
		RETURN
	END

	IF @Factory_Code = 64646  --# RIST
	BEGIN
		SET @BaseURL = 'http://webserv/'
	END
	ELSE IF @Factory_Code = 61300 --# REMA
	BEGIN
		SET @BaseURL = 'http://110.25.254.38/'
	END

	IF @IsARC = 1
	BEGIN
		SET @PrintMode = 'RohmTest/Atom/LabelFormatV2/GetDataAutoPrintAllReel_TP_NewFC_View?'  ---# Print All
	END
	ELSE
	BEGIN
		SET @PrintMode = 'rohmtest/Atom/LabelFormatV2/AutoPrintLabelTypeReelandHasuuView?'  ---# Print By Reel
	END

	-----# PC REQUEST #----------------------------------------------------------------------------------------------
	
	IF @PCCode = 13
	BEGIN
		IF @TypeOfLabel = 2  --#Hasuu label of PC-Request #Modify : 2025.03.12 Time : 16.33 by Aomsin
		BEGIN
			SET @PrintMode = 'rohmtest/Atom/LabelFormatV2/AutoPrintLabelTypeReelandHasuuView?'

			SET @Link = @BaseURL
					+ @PrintMode
					+ 'Lotno=' + @LotNo
					+ '&Type_of_label=' + CAST(@TypeOfLabel AS VARCHAR(10))
					+ '&Mcno=' + @Machine

			SELECT 'TRUE' AS [Status]
				,@Link AS [Result]
				,'Retrun URL Successfully (Hasuu)' AS [error_Message_ENG]
				,N'ส่งต่อ URL สำเร็จ (เศษที่เหลือ)' AS [error_Message_THA] 
				,N'Successfully' AS [handling]
			RETURN
		END
		ELSE
		BEGIN
			SET @PrintMode = 'rohmtest/Atom/LabelFormatV2/GetDataAutoPrintPCRequest_TP_NewFC_View?'

			SET @Link = @BaseURL
					+ @PrintMode
					+ 'Lotno=' + @LotNo
					+ '&Mcno=' + @Machine

			SELECT 'TRUE' AS [Status] 
				,@Link AS [Result]
				,'Retrun URL Successfully (PC-Request Mode : 13)' AS [error_Message_ENG]
				,N'ส่งต่อ URL สำเร็จ (PC-Request Mode : 13)' AS [error_Message_THA] 
				,N'Successfully' AS [handling]
			RETURN 
		END
	END
	--ELSE IF @PCCode = 11  --ปัจจุบันทาง TP Cellcon ยังไม่มีการ Auto print ของงานประเภทนี้ ยัง print label ผ่าน เว็บอยู่
	--BEGIN
	--	PRINT 'PCCODE 11'
	--	SET @PrintMode = 'rohmtest/Atom/LabelFormatV2/AutoPrintLabelTypeReelandHasuuView?'

	--	SET @Link = @BaseURL
	--				+ @PrintMode
	--				+ 'Lotno=' + @LotNo
	--				+ '&Mcno=' + @Machine

	--	SELECT 'TRUE' AS Status 
	--	,@Link AS error_Message_ENG
	--	,N'' AS error_Message_THA 
	--	,N'Successfully' AS handling
	--	RETURN 
	--END
	ELSE
	BEGIN
		IF @TypeOfLabel = 3  ---# Reel
		BEGIN
			PRINT 'TYPEOFLABEL 3'
			IF @IsARC = 1 
			BEGIN
				PRINT 'MACHINE ARC'
				SET @Link = @BaseURL
						+ @PrintMode
						+ 'Lotno=' + @LotNo
						+ '&Type_of_label=' + CAST(@TypeOfLabel AS VARCHAR(10))
						+ '&No_reel='
						+ '&Mcno=' + @Machine

				SELECT 'TRUE' AS [Status] 
					,@Link AS [Result]
					,'Retrun URL Successfully (MACHINE ARC)' AS [error_Message_ENG]
					,N'ส่งต่อ URL สำเร็จ (เครื่องจักมี ARC)' AS [error_Message_THA] 
					,N'Successfully' AS [handling]
				RETURN 
			END
			ELSE
			BEGIN
				PRINT 'MACHINE NOT ARC'
				IF @NoReel != 0
				BEGIN
				PRINT 'NO. REEL'
					SET @Link = @BaseURL
							+ @PrintMode
							+ 'Lotno=' + @LotNo
							+ '&Type_of_label=' + CAST(@TypeOfLabel AS VARCHAR(10))
							+ '&No_reel=' + CAST(@NoReel AS VARCHAR(10))
							+ '&Mcno=' + @Machine

				--SELECT 'TRUE' AS [Status] 
				--	,@Link AS [Result]
				--	,'Retrun URL Successfully (MACHINE NOT ARC)' AS [error_Message_ENG]
				--	,N'ส่งต่อ URL สำเร็จ (เครื่องจักรไม่มี ARC)' AS [error_Message_THA] 
				--	,N'Successfully' AS [handling]
				--RETURN

					--add condition check version print label #2025.05.07 time : 16.51 by Aomsin
					SELECT @Version = [version] FROM [APCSProDB].[trans].[label_issue_records] 
					WHERE lot_no = @LotNo 
					AND type_of_label = 3
					AND no_reel = CAST(@NoReel AS CHAR(3))

					Declare @lot_id int = 0, @count_row int = 0
					select @lot_id = id from APCSProDB.trans.lots where lot_no = @LotNo

					set @count_row = (select Count(lot_id) from APCSProDB.trans.lot_combine 
					where [app_name] = 'LSMS System' 
					and lot_id =  @lot_id)

					IF (@count_row >= 1)  --#2025.Mar.07 Time : 20.06 by Aomsin
					BEGIN
						SELECT 'TRUE' AS [Status] 
							,@Link AS [Result]
							,'Retrun URL Successfully (MACHINE NOT ARC)' AS [error_Message_ENG]
							,N'ส่งต่อ URL สำเร็จ (เครื่องจักรไม่มี ARC)' AS [error_Message_THA] 
							,N'Successfully' AS [handling]
						RETURN
					END

					IF (@Version > 0)
					BEGIN
						
						SELECT 'FALSE' AS [Status] 
							,'' AS [Result]
							,'The print label has already been ordered (Label Double).' AS [error_Message_ENG]
							,N'มีการสั่ง Print Label ไปแล้ว (Label ซ้ำ).' AS [error_Message_THA] 
							,N'Please reprint label on LSMS website (โปรด reprint label บน เว็บ LSMS)' AS [handling]
						RETURN
					END
					ELSE
					BEGIN
						SELECT 'TRUE' AS [Status] 
							,@Link AS [Result]
							,'Retrun URL Successfully (MACHINE NOT ARC)' AS [error_Message_ENG]
							,N'ส่งต่อ URL สำเร็จ (เครื่องจักรไม่มี ARC)' AS [error_Message_THA] 
							,N'Successfully' AS [handling]
						RETURN
					END
				END
			END
		END
		ELSE IF @TypeOfLabel = 2 --# Hasuu
		BEGIN
			SET @PrintMode = 'rohmtest/Atom/LabelFormatV2/AutoPrintLabelTypeReelandHasuuView?'

			SET @Link = @BaseURL
					+ @PrintMode
					+ 'Lotno=' + @LotNo
					+ '&Type_of_label=' + CAST(@TypeOfLabel AS VARCHAR(10))
					+ '&Mcno=' + @Machine

			SELECT 'TRUE' AS [Status]
				,@Link AS [Result]
				,'Retrun URL Successfully (Hasuu)' AS [error_Message_ENG]
				,N'ส่งต่อ URL สำเร็จ (เศษที่เหลือ)' AS [error_Message_THA] 
				,N'Successfully' AS [handling]
			RETURN
		END
		ELSE
		BEGIN
			SELECT 'FALSE' AS [Status] 
				,N'' AS [Result]
				,'No have condition auto print label !!' AS [error_Message_ENG]
				,N'ไม่เข้าเงื่อนไขการสั่งปริ้นแบบอัตโนมัติ !!' AS [error_Message_THA] 
				,N'Please check informations' AS [handling]
			RETURN
		END
	END
END
