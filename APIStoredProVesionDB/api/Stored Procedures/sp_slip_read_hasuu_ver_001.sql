-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [api].[sp_slip_read_hasuu_ver_001]
	-- Add the parameters for the stored procedure here
	@username varchar(10)
	,	@lot_no varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF EXISTS(SELECT [lot_no]
		FROM [APCSProDB].[trans].[label_issue_records]
		WHERE [lot_no] = @lot_no)
	BEGIN
		SELECT CAST(1 AS BIT) AS [status]
		, [id]
		, ISNULL([recorded_at], GETDATE())
		, RIGHT('000000' + CAST(ISNULL([operated_by], 0) AS VARCHAR(6)), 6) AS [operated_by]
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
		, RIGHT('000000' + CAST([op_no] AS VARCHAR(6)), 6) AS [op_no]
		, ISNULL([op_name], '') AS [op_name]
		, ISNULL([seq], 0) AS [seq]
		, ISNULL([ip_address], '') AS [ip_address]
		, ISNULL([msl_label], '') AS [msl_label]
		, ISNULL([floor_life], '') AS [floor_life]
		, ISNULL([ppbt], '') AS [ppbt]
		, ISNULL([re_comment], '') AS [re_comment]
		, ISNULL([version], 0) AS [version]
		, ISNULL([is_logo], 0) AS [is_logo]
		, ISNULL([mc_name], '') AS [mc_name]
		, ISNULL([barcode_1_mod], '') AS [barcode_1_mod]
		, ISNULL([barcode_2_mod], '') AS [barcode_2_mod]
		, ISNULL([seal], '') AS [seal]
		, ISNULL([create_at], GETDATE()) AS [create_at]
		, ISNULL([create_by], 0) AS [create_by]
		, ISNULL([update_at], GETDATE()) AS [update_at]
		, ISNULL([update_by], 0) AS [update_by]
		, ISNULL([host_name], '') AS [host_name]
		, ISNULL([app_name], '') AS [app_name]
		FROM [APCSProDB].[trans].[label_issue_records]
		WHERE [lot_no] = @lot_no
		AND [type_of_label] = 2
	END
	ELSE
	BEGIN
		SELECT CAST(1 AS BIT) AS [status]
		, 0 AS [id]
		, GETDATE() AS [recorded_at]
		, '' AS [operated_by]
		, 0 AS [type_of_label]
		, '' AS [lot_no]
		, '' AS [customer_device]
		, '' AS [rohm_model_name]
		, '' AS [qty]
		, '' AS [barcode_lotno]
		, '' AS [tomson_box]
		, '' AS [tomson_3]
		, '' AS [box_type]
		, '' AS [barcode_bottom]
		, '' AS [mno_std]
		, '' AS [std_qty_before]
		, '' AS [mno_hasuu]
		, '' AS [hasuu_qty_before]
		, '' AS [no_reel]
		, '' AS [qrcode_detail]
		, '' AS [type_label_laterat]
		, '' AS [mno_std_laterat]
		, '' AS [mno_hasuu_laterat]
		, '' AS [barcode_device_detail]
		, '' AS [op_no]
		, '' AS [op_name]
		, 0 AS [seq]
		, '' AS [ip_address]
		, '' AS [msl_label]
		, '' AS [floor_life]
		, '' AS [ppbt]
		, '' AS [re_comment]
		, 0 AS [version]
		, 0 AS [is_logo]
		, '' AS [mc_name]
		, '' AS [barcode_1_mod]
		, '' AS [barcode_2_mod]
		, '' AS [seal]
		, GETDATE() AS [create_at]
		, 0 AS [create_by]
		, GETDATE() AS [update_at]
		, 0 AS [update_by]
		, '' AS [host_name]
		, '' AS [app_name]
	END
END
