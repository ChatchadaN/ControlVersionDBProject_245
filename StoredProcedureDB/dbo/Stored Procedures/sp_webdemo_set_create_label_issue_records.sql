-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_webdemo_set_create_label_issue_records]
	-- Add the parameters for the stored procedure here
	@new_lotno VARCHAR(10), 
	@empid INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
		( [record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [lot_no]
		, [command_text] )
	SELECT GETDATE() --AS [record_at]
		, 4 AS [record_class]
		, ORIGINAL_LOGIN() --AS [login_name]
		, HOST_NAME() --AS [hostname]
		, APP_NAME() --AS [appname]
		, @new_lotno --AS [lot_no]
		, 'EXEC [StoredProcedureDB].[dbo].[sp_webdemo_set_create_label_issue_records]' 
			+ ' @new_lotno = ' + ISNULL( '''' + CAST( @new_lotno AS VARCHAR(10) ) + '''' , 'NULL' )
			+ ' ,@empid = ' + ISNULL( CAST( @empid AS VARCHAR(10) ), 'NULL' ); --AS [command_text]

	DECLARE @OPNo INT
		, @Customer_Device CHAR(20)  = ''
		, @Shortname CHAR(20)  = ''
		, @Device CHAR(20)  = ''
		, @Tomson CHAR(4) = ''
		, @Mno_Standard CHAR(20) = ''
		, @Required_ul_logo INT = 0
		, @SPEC CHAR(20)  = ''
		, @FLOOR_LIFE CHAR(20)  = ''
		, @PPBT CHAR(20)  = ''
		, @OPName CHAR(20)
		, @qty INT

	---- # label_issue_records
	IF NOT EXISTS (SELECT 1 FROM [APCSProDB].[trans].[label_issue_records] WHERE [type_of_label] = 2 AND [lot_no] = @new_lotno)
	BEGIN
		SELECT @Customer_Device = (
			CASE 
				WHEN ([multi_label].[USER_Model_Name] IS NULL OR [multi_label].[USER_Model_Name] = '') THEN [device_names].[name] 
				ELSE 
					CASE 
						WHEN ([multi_label].[USER_Model_Name] IS NOT NULL OR [multi_label].[USER_Model_Name] != '') AND ([multi_label].[delete_flag] = 1) THEN [device_names].[name] 
						ELSE [multi_label].[USER_Model_Name] 
					END
			END ) 
			, @Device = [device_names].[name] 
			, @Shortname = [packages].[short_name]
			, @qty = [surpluses].[pcs]
			, @Tomson = ISNULL([surpluses].[qc_instruction], '')
			, @Mno_Standard = [surpluses].[mark_no]
			, @Required_ul_logo = ISNULL([device_names].[required_ul_logo], 0)
		FROM [APCSProDB].[trans].[lots]
		INNER JOIN [APCSProDB].[method].[device_names] ON [lots].[act_device_name_id] = [device_names].[id]
		INNER JOIN [APCSProDB].[method].[packages] ON [device_names].[package_id] = [packages].[id]
		INNER JOIN [APCSProDB].[trans].[surpluses] ON [lots].[id] = [surpluses].[lot_id]
		LEFT JOIN [APCSProDB].[method].[multi_labels] AS [multi_label] ON [device_names].[name] COLLATE Latin1_General_CI_AS = [multi_label].[device_name] COLLATE Latin1_General_CI_AS
		WHERE [lots].[lot_no] = @new_lotno;

		IF EXISTS (SELECT 1 FROM [APCSProDB].[method].[mslevel_data] WHERE [Product_Name] = TRIM(@Device))
		BEGIN
			SELECT @SPEC = [Spec]
				, @FLOOR_LIFE = [Floor_Life]
				, @PPBT = [PPBT] 
			FROM [APCSProDB].[method].[mslevel_data] 
			WHERE [Product_Name] = TRIM(@Device);
		END
		ELSE
		BEGIN
			SELECT @SPEC = [Spec]
				, @FLOOR_LIFE = [Floor_Life]
				, @PPBT = [PPBT] 
			FROM [APCSProDB].[method].[mslevel_data] 
			WHERE [Product_Name] = TRIM(@Shortname);
		END

		SELECT @OPNo = [users].[emp_num]
			, @OPName =
				UPPER( CASE WHEN SUBSTRING([users].[name], 1, 3) = 'MR.' THEN 
						LTRIM(SUBSTRING([users].[name], /*start*/4/*start*/, /*end*/ IIF(CHARINDEX(' ', LTRIM(SUBSTRING([users].[name], 4, LEN([users].[name])))) = 0, LEN([users].[name]), CHARINDEX(' ', LTRIM(SUBSTRING([users].[name], 4, LEN([users].[name]))))) /*end*/ ))
					WHEN SUBSTRING([users].[name], 1, 3) = 'MS.' THEN 
						LTRIM(SUBSTRING([users].[name], /*start*/4/*start*/, /*end*/ IIF(CHARINDEX(' ', LTRIM(SUBSTRING([users].[name], 4, LEN([users].[name])))) = 0, LEN([users].[name]), CHARINDEX(' ', LTRIM(SUBSTRING([users].[name], 4, LEN([users].[name]))))) /*end*/ ))
					WHEN SUBSTRING([users].name, 1, 4) ='MISS' THEN 
						LTRIM(SUBSTRING([users].[name], /*start*/5/*start*/, /*end*/ IIF(CHARINDEX(' ', LTRIM(SUBSTRING([users].[name], 5, LEN([users].[name])))) = 0, LEN([users].[name]), CHARINDEX(' ', LTRIM(SUBSTRING([users].[name], 5, LEN([users].[name]))))) /*end*/ ))
					WHEN SUBSTRING([users].name, 1, 4) ='MRS.' THEN 
						LTRIM(SUBSTRING([users].[name], /*start*/5/*start*/, /*end*/ IIF(CHARINDEX(' ', LTRIM(SUBSTRING([users].[name], 5, LEN([users].[name])))) = 0, LEN([users].[name]), CHARINDEX(' ', LTRIM(SUBSTRING([users].[name], 5, LEN([users].[name]))))) /*end*/ ))
					WHEN SUBSTRING([users].name, 1, 15) = 'Acting Sub. Lt.' THEN 
						LTRIM(SUBSTRING([users].[name], /*start*/16/*start*/, /*end*/ IIF(CHARINDEX(' ', LTRIM(SUBSTRING([users].[name], 16, LEN([users].[name])))) = 0, LEN([users].[name]), CHARINDEX(' ', LTRIM(SUBSTRING([users].[name], 16, LEN([users].[name]))))) /*end*/ ))
					ELSE 
						( CASE WHEN CHARINDEX(' ', [users].[name]) = 0 THEN 
								/*find '.'*/( CASE WHEN CHARINDEX('.', [users].[name]) = 0 THEN [users].[name]
									ELSE REPLACE(LTRIM((SUBSTRING([users].[name], 1, CHARINDEX('.', [users].[name])))), '.', '')
								END )/*find '.'*/
							ELSE /*find ' '*/LTRIM(SUBSTRING([users].[name], 1, CHARINDEX(' ', [users].[name])))/*find ' '*/
						END ) 
				END )
		FROM [APCSProDB].[man].[users]
		WHERE [users].[id] = @empid;

		INSERT INTO [APCSProDB].[trans].[label_issue_records]
			( [recorded_at]
			, [operated_by]
			, [type_of_label]
			, [lot_no]
			, [customer_device]
			, [rohm_model_name]
			, [qty]
			, [barcode_lotno]
			, [tomson_box]
			, [tomson_3]
			, [box_type]
			, [barcode_bottom]
			, [mno_std]
			, [std_qty_before]
			, [mno_hasuu]
			, [hasuu_qty_before]
			, [no_reel]
			, [qrcode_detail]
			, [type_label_laterat]
			, [mno_std_laterat]
			, [mno_hasuu_laterat]
			, [barcode_device_detail]
			, [op_no]
			, [op_name]
			, [seq]
			, [msl_label]
			, [floor_life]
			, [ppbt]
			, [re_comment]
			, [version]
			, [is_logo]
			, [mc_name]
			, [seal]
			, [create_at]
			, [create_by]
			, [update_at]
			, [update_by] )
		SELECT GETDATE() AS [recorded_at]
			, @OPNo AS [operated_by]
			, 2 AS [type_of_label]
			, @new_lotno AS [lot_no]
			, @Customer_Device AS [customer_device]
			, @Device AS [rohm_model_name]
			, @qty AS [qty]
			, CAST(SUBSTRING(@new_lotno, 1, 4) AS CHAR(4)) + ' ' + CAST(SUBSTRING(@new_lotno, 5, 6) AS CHAR(6)) AS [barcode_lotno]
			, '' AS [tomson_box]
			, @Tomson AS [tomson_3]
			, '' AS [box_type]
			, FORMAT(CAST(@qty AS INT),'000000') + ' ' + CAST(SUBSTRING(@new_lotno, 1, 4) + SPACE(1) + SUBSTRING(@new_lotno, 5, 6) AS CHAR(10)) AS [barcode_bottom]
			, @Mno_Standard AS [mno_std]
			, '' AS [std_qty_before]
			, @Mno_Standard AS [mno_hasuu]
			, '' AS [hasuu_qty_before]
			, 1 AS [no_reel]
			, CAST(@Device AS VARCHAR(19)) + FORMAT(CAST(@qty AS INT), '000000') + @new_lotno + FORMAT(1, '000') AS [qrcode_detail]
			, '' AS [type_label_laterat]
			, '' AS [mno_std_laterat]
			, '' AS [mno_hasuu_laterat]
			, CAST((@Device) AS CHAR(20)) AS[barcode_device_detail]
			, @OPNo AS [op_no]
			, @OPName AS [op_name]
			, '' AS [seq]
			, CAST((@SPEC) AS VARCHAR(15)) AS [msl_label]
			, CAST((@FLOOR_LIFE) AS VARCHAR(15)) AS [floor_life]
			, CAST((@PPBT) AS VARCHAR(15)) AS [ppbt]
			, '' AS [re_comment]
			, '' AS [version]
			, @Required_ul_logo AS [is_logo]
			, '' AS [mc_name]
			, FORMAT(GETDATE(), 'ddMMMyy') AS [seal]
			, GETDATE() AS [create_at]
			, @empid AS [create_by]
			, GETDATE() AS [update_at]
			, @empid AS [update_by];
	END

	IF EXISTS (SELECT 1 FROM [APCSProDB].[trans].[label_issue_records] WHERE [type_of_label] = 2 AND [lot_no] = @new_lotno)
	BEGIN
		SELECT 'TRUE' AS [Is_Pass] 
			, '' AS [Error_Message_ENG]
			, N'' AS [Error_Message_THA] 
			, N'' AS [Handling];
		RETURN;
	END
	ELSE
	BEGIN
		INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
			( [record_at]
			, [record_class]
			, [login_name]
			, [hostname]
			, [appname]
			, [lot_no]
			, [command_text] )
		SELECT GETDATE() --AS [record_at]
			, 4 AS [record_class]
			, ORIGINAL_LOGIN() --AS [login_name]
			, HOST_NAME() --AS [hostname]
			, APP_NAME() --AS [appname]
			, @new_lotno --AS [lot_no]
			, 'EXEC [StoredProcedureDB].[dbo].[sp_webdemo_set_create_label_issue_records]' 
				+ ' LotNo : ' + ISNULL( '''' + CAST( @new_lotno AS VARCHAR(10) ) + '''' , 'NULL' ) 
				+ ' Error : insert data trans.label_issue_records error.'; --AS [command_text]

		SELECT 'FALSE' AS [Is_Pass] 
			, 'insert data trans.label_issue_records error !!' AS [Error_Message_ENG]
			, N'เพิ่มข้อมูล trans.label_issue_records ไม่สำเร็จ !!' AS [Error_Message_THA] 
			, N'' AS [Handling];
		RETURN;
	END
END
