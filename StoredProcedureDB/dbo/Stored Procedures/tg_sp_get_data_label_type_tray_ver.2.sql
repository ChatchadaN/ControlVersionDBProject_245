-- =============================================
-- Author:		<Author,,Vanatjaya S. 009131 and Kittithat P. 009670>
-- Create date: <Create Date,2021/09/29,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_data_label_type_tray_ver.2]
	-- Add the parameters for the stored procedure here
	@lotno varchar(10) = ''
	,@tomson_num int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	DECLARE @Tomson_count int = 0
	DECLARE @Tray_count int = 0
	--Use Tray
	DECLARE @Tray1 INT
	DECLARE @Tray1_1 INT
	DECLARE @Tray2 INT
    -- Insert statements for procedure here

	--Get Data Tomson Count
	select @Tomson_count =  COUNT(type_of_label)  FROM APCSProDB.trans.label_issue_records 
	where lot_no = @lotno and type_of_label = 5
	--Get Data Tray Count
	select @Tray_count = COUNT(type_of_label)  FROM APCSProDB.trans.label_issue_records 
	where lot_no = @lotno and type_of_label = 6

	IF (@tomson_num <= @Tomson_count)
	BEGIN
		SET @Tray1 = iif((@Tray_count/@Tomson_count) = 1,(@tomson_num * (@Tray_count/@Tomson_count))
		,(@tomson_num * (@Tray_count/@Tomson_count)) - 1)

		--SET @Tray1_1 = case when (@Tray_count/@Tomson_count) = 1 then @tomson_num * (@Tray_count/@Tomson_count)
		--			   else (@tomson_num * (@Tray_count/@Tomson_count)) - 1 end
		SET @Tray2 = (@tomson_num * (@Tray_count/@Tomson_count))

		--Check Condition Tomson_Num Send data form OGI Cellcon
		SELECT [recorded_at]
			, [operated_by]
			, [type_of_label]
			, [label_rec].[lot_no]
			, [customer_device]
			, [rohm_model_name] 
			, FORMAT(CONVERT(int,qty),'#,0') as [qty]
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
			, [ip_address]
			, [msl_label] as MSL_LAVEL
			, [floor_life]
			, [ppbt]
			, [re_comment]
			, [version]
			, [is_logo]
			, [mc_name]
			, [barcode_1_mod]
			, [barcode_2_mod]
			, ISNULL(NULLIF(seal, ' '), ' ') as seal
			, [create_at]
			, [create_by]
			, [update_at]
			, [update_by]
			, ISNULL(NULLIF(sur.pdcd, ' '), ' ') as PDCD
			, dn.assy_name as Assy_Name
		FROM APCSProDB.trans.label_issue_records as label_rec WITH (NOLOCK)
		left join APCSProDB.trans.lots as lot WITH (NOLOCK) on label_rec.lot_no = lot.lot_no
		left join APCSProDB.trans.surpluses as sur WITH (NOLOCK) on lot.lot_no = sur.serial_no
		left join APCSProDB.method.device_names as dn  WITH (NOLOCK) on lot.act_device_name_id = dn.id
		where label_rec.lot_no = @lotno
			and ((type_of_label = 6 and (no_reel = @Tray1 or no_reel = @Tray2))
			or (type_of_label = 5 and no_reel = @tomson_num))
		order by type_of_label desc,no_reel asc
	END



END
