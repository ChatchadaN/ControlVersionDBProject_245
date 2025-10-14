-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_get_lsisearch_workrecord_xml]
	-- Add the parameters for the stored procedure here
	@lot_no varchar(20) = '%'
	, @process varchar(50) = '%'
	, @jobs varchar(50) = '%'
	, @machine varchar(50) = '%'
	, @opNo varchar(50) = '%'
	, @packages varchar(50) = '%'
	, @device varchar(50) = '%'
	, @start_time DATETIME = ''
	, @end_time DATETIME = ''

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


    -- Insert statements for procedure here
	BEGIN		
		SELECT [id],
			   [process],
			   [flow],
			   [mc_no],
			   [mc_type],
			   [lot_no],
			   [package],
			   [device],
			   [lot_setup_time],
			   [lot_start_time],
			   [lot_end_time],
			   [lot_close_time],
			   [opno_setup],
			   [opno_start],
			   [opno_end],
			   ISNULL([input_qty], 0) AS [input_qty],
			   ISNULL([total_good], 0) AS [total_good],
			   ISNULL([total_ng], 0) AS [total_ng],
			   ISNULL([input_qty_adjust], 0) AS [input_qty_adjust],
			   ISNULL([good_adjust], 0) AS [good_adjust],
			   ISNULL([ng_adjust], 0) AS [ng_adjust],
			   [op_judgement],
			   ISNULL([op_rate], 0) AS [op_rate],
			   ISNULL([average_rpm], 0) AS [average_rpm],
			   ISNULL([mtbf], 0) AS [mtbf],
			   ISNULL([mttr], 0) AS [mttr],
			   ISNULL([alarm_total], 0) AS [alarm_total],
			   ISNULL([run_time], 0) AS [run_time],
			   ISNULL([stop_time], 0) AS [stop_time],
			   ISNULL([alarm_time], 0) AS [alarm_time],
			   [gl_check],
			   [lot_judgement],
			   [remark],
			   ISNULL([final_yield], 0) AS [final_yield],
			   [carrier_no],
			   [created_at],
			   [created_by],
			   [updated_at],
			   [updated_by]
		FROM [APCSProDWR].[trans].[lot_transactions]
		WHERE (@lot_no = '%' OR lot_no LIKE @lot_no)
		  AND (@process = '%' OR process LIKE @process)
		  AND (@jobs = '%' OR flow LIKE @jobs)
		  AND (@machine = '%' OR mc_no LIKE @machine)
		  AND (@packages = '%' OR package LIKE @packages)
		  AND (@device = '%' OR device LIKE @device)
		  AND (lot_start_time >= @start_time)
		  AND (lot_end_time <= @end_time)
		  AND (@opNo = '%' OR opno_start LIKE @opNo);

	END
END
