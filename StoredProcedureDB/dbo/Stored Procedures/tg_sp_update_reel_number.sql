-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE  [dbo].[tg_sp_update_reel_number]
	-- Add the parameters for the stored procedure here
	@lotno varchar(10)
	,@type_label_drypack int = 0
	,@type_label_tomson int = 0
	,@Reel_num char(1) = ''
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @Version_count int = 0
	--DECLARE @Version_count_type_of_label_0 int = 0
	DECLARE @QR_CODE_VALUE_Update VARCHAR(90) = ''
	DECLARE @QR_CODE_VALUE_Update_type_of_label_0 VARCHAR(90) = ''
	DECLARE @QR_CODE_VALUE_STR VARCHAR(90) = ''
	DECLARE @Reel_Value VARCHAR(3) = ''
	DECLARE @Reel_Value_type_label_0 VARCHAR(3) = ''

    -- Insert statements for procedure here
	
	--IF @type_label_drypack = 4 and @type_label_tomson = 0 --DRYPACK
	--BEGIN
	--	--Send Parameter Type_of_label != 0
	--	select @Version_count = VERSION from APCSProDB.trans.label_issue_records
	--	where lot_no = @lotno and type_of_label = @type_label_drypack and no_reel = @Reel_num 

	--	--type label != 0
	--	select @Reel_Value  =  Cast((VERSION) as char(1)) + '0' + no_reel from	APCSProDB.trans.label_issue_records 
	--	where lot_no = @lotno and type_of_label = @type_label_drypack and no_reel = @Reel_num

	--	select @QR_CODE_VALUE_Update = @QR_CODE_VALUE_STR + @Reel_Value

	--	select  Cast((@QR_CODE_VALUE_Update) as char(90))

	--	select @Reel_Value

		
	--END
	--ELSE IF @type_label_tomson = 5 and @type_label_drypack = 0 --TOMSON
	--BEGIN
	--	--Send Parameter Type_of_label != 0
	--	select @Version_count = VERSION from APCSProDB.trans.label_issue_records
	--	where lot_no = @lotno and type_of_label = @type_label_tomson and no_reel = @Reel_num 

	--	select @QR_CODE_VALUE_STR = SUBSTRING(qrcode_detail,1,35) from APCSProDB.trans.label_issue_records where lot_no = @lotno

	--	--type label != 0
	--	select @Reel_Value  =  Cast((VERSION) as char(1)) + '0' + no_reel from	APCSProDB.trans.label_issue_records 
	--	where lot_no = @lotno and type_of_label = @type_label_tomson and no_reel = @Reel_num

	--	select @QR_CODE_VALUE_Update = @QR_CODE_VALUE_STR + @Reel_Value

	--	select  Cast((@QR_CODE_VALUE_Update) as char(90))

	--	select @Reel_Value

		

	--END
	--ELSE IF @type_label_drypack = 4 and @type_label_tomson = 5 -- DRYPACK AND TOMSON
	--BEGIN
	--	--Test type label = 4 and 5
	--	select @Reel_Value_type_label_0  =  Cast((VERSION) as char(1)) + '0' + no_reel from	APCSProDB.trans.label_issue_records 
	--	where lot_no = @lotno and type_of_label in(4,5) and no_reel = @Reel_num

	--	select @QR_CODE_VALUE_Update_type_of_label_0 = @QR_CODE_VALUE_STR + @Reel_Value_type_label_0

	--	select Cast((@QR_CODE_VALUE_Update_type_of_label_0) as char(90))

	--	select @Reel_Value_type_label_0  as testdata
	--END


	IF @type_label_drypack = 4 and @type_label_tomson = 5
		BEGIN
			--Test type label = 4 and 5
			select @Reel_Value_type_label_0  =  Cast((VERSION) as char(1)) + '0' + no_reel from	APCSProDB.trans.label_issue_records 
			where lot_no = @lotno and type_of_label in(4,5) and no_reel = @Reel_num

			select @QR_CODE_VALUE_STR = SUBSTRING(qrcode_detail,1,35) from APCSProDB.trans.label_issue_records where lot_no = @lotno

			select @QR_CODE_VALUE_Update_type_of_label_0 = @QR_CODE_VALUE_STR + @Reel_Value_type_label_0

			select Cast((@QR_CODE_VALUE_Update_type_of_label_0) as char(90))

			select @Reel_Value_type_label_0  as testdata

			UPDATE APCSProDB.trans.label_issue_records SET qrcode_detail =  @QR_CODE_VALUE_Update_type_of_label_0
			WHERE lot_no = @lotno and type_of_label = @type_label_drypack  and no_reel = @Reel_num

			UPDATE APCSProDB.trans.label_issue_records SET qrcode_detail =  @QR_CODE_VALUE_Update_type_of_label_0
			WHERE lot_no = @lotno and type_of_label = @type_label_tomson and no_reel = @Reel_num

			select qrcode_detail as type4 from APCSProDB.trans.label_issue_records 
			where lot_no = @lotno and type_of_label = 4 and no_reel = @Reel_num

			select qrcode_detail as type5 from APCSProDB.trans.label_issue_records 
			where lot_no = @lotno and type_of_label = 5 and no_reel = @Reel_num
		END
	ELSE
	BEGIN
		IF @Version_count != 0
		BEGIN
			IF @type_label_drypack = 4 and @type_label_tomson = 0
			BEGIN
				--Send Parameter Type_of_label != 0
				select @Version_count = VERSION from APCSProDB.trans.label_issue_records
				where lot_no = @lotno and type_of_label = @type_label_drypack and no_reel = @Reel_num 

				select @QR_CODE_VALUE_STR = SUBSTRING(qrcode_detail,1,35) from APCSProDB.trans.label_issue_records where lot_no = @lotno

				--type label != 0
				select @Reel_Value  =  Cast((VERSION) as char(1)) + '0' + no_reel from	APCSProDB.trans.label_issue_records 
				where lot_no = @lotno and type_of_label = @type_label_drypack and no_reel = @Reel_num

				select @QR_CODE_VALUE_Update = @QR_CODE_VALUE_STR + @Reel_Value

				select  Cast((@QR_CODE_VALUE_Update) as char(90))

				select @Reel_Value

				UPDATE APCSProDB.trans.label_issue_records SET qrcode_detail =  @QR_CODE_VALUE_Update
				WHERE lot_no = @lotno and type_of_label = @type_label_drypack and no_reel = @Reel_num

				select qrcode_detail from APCSProDB.trans.label_issue_records 
				where lot_no = @lotno and type_of_label = @type_label_drypack and no_reel = @Reel_num
			END
			ELSE IF @type_label_tomson = 5 and @type_label_drypack = 0
			BEGIN
				--Send Parameter Type_of_label != 0
				select @Version_count = VERSION from APCSProDB.trans.label_issue_records
				where lot_no = @lotno and type_of_label = @type_label_tomson and no_reel = @Reel_num 

				select @QR_CODE_VALUE_STR = SUBSTRING(qrcode_detail,1,35) from APCSProDB.trans.label_issue_records where lot_no = @lotno

				--type label != 0
				select @Reel_Value  =  Cast((VERSION) as char(1)) + '0' + no_reel from	APCSProDB.trans.label_issue_records 
				where lot_no = @lotno and type_of_label = @type_label_tomson and no_reel = @Reel_num

				select @QR_CODE_VALUE_Update = @QR_CODE_VALUE_STR + @Reel_Value

				select  Cast((@QR_CODE_VALUE_Update) as char(90))

				select @Reel_Value

				UPDATE APCSProDB.trans.label_issue_records SET qrcode_detail =  @QR_CODE_VALUE_Update
				WHERE lot_no = @lotno and type_of_label = @type_label_tomson and no_reel = @Reel_num

				select qrcode_detail from APCSProDB.trans.label_issue_records 
				where lot_no = @lotno and type_of_label = @type_label_tomson and no_reel = @Reel_num
			END
			
		END
		ELSE IF @Version_count = 0
		BEGIN
			IF @type_label_drypack = 4 and @type_label_tomson = 0
			BEGIN
				select qrcode_detail from APCSProDB.trans.label_issue_records 
				where lot_no = @lotno and type_of_label = @type_label_drypack and no_reel = @Reel_num
			END
			ELSE IF @type_label_tomson = 5 and @type_label_drypack = 0
			BEGIN
				select qrcode_detail from APCSProDB.trans.label_issue_records 
				where lot_no = @lotno and type_of_label = @type_label_tomson and no_reel = @Reel_num
			END
		END
	END
END
