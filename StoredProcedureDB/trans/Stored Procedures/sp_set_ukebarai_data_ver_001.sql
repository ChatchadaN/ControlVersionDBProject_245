-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_ukebarai_data_ver_001]
	-- Add the parameters for the stored procedure here
	@lot_id INT
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @LotID int = 0
	declare @JobID int = 0
	declare @date varchar(6) = NULL
	declare @time varchar(4) = NULL
	declare @good_qty int = 0
	declare @ng_qty int = 0
	declare @shipment_qty int = 0
	declare @LotNo varchar(10) 
	declare @process_no int = 0

    -- Insert statements for procedure here
	--<<--------------------------------------------------------------------------
	--- ** log exec
	-->>-------------------------------------------------------------------------
	insert into [StoredProcedureDB].[dbo].[exec_sp_history]
	(
		[record_at]
		, [record_class]
		, [login_name]
		, [hostname]
		, [appname]
		, [command_text]
		, [lot_no]
	)
	select GETDATE()
		, '4'
		, ORIGINAL_LOGIN()
		, HOST_NAME()
		, APP_NAME()
		, 'exec [dbo].[sp_set_ukebarai_data] @lot_id = ' + ISNULL(CAST(@lot_id as varchar),'')
		, (select cast([lot_no] as varchar) from [APCSProDB].[trans].[lots] where [id] = @lot_id);
	--------------------------------------------------------------------------
	--- **  select data insert [APCSProDWH].[dbo].[ukebarais]
	-------------------------------------------------------------------------
	select top (1) @LotID = lot_id
		, @JobID = job_id 
		, @date = format([lot_process_records].[recorded_at], 'yyMMdd') 
		, @time = format([lot_process_records].[recorded_at], 'HHmm')
		, @good_qty = [lot_process_records].[qty_last_pass]
		, @ng_qty = [lot_process_records].[qty_last_fail]
		, @shipment_qty = iif([lot_process_records].[process_id] = 18,isnull([lot_process_records].[qty_out],0),0)
	from [APCSProDB].[trans].[lot_process_records]
	where [lot_process_records].[lot_id] = @lot_id 
		and [lot_process_records].[record_class] = 2
	order by [lot_process_records].[id] desc;  

	select @LotNo = TRIM([lots].[lot_no]) from [APCSProDB].[trans].[lots]
	where [lots].[id] = @lot_id;

	select @process_no = [jobs].[job_no] from [APCSProDB].[method].[jobs]
	inner join [APCSProDB].[method].[processes] on [jobs].[process_id] = [processes].[id]
	where [jobs].[id] = @JobID;

	----------------------check good_qty & ng_qty & shipment_qty -----------------------
	if @good_qty < 0 or @ng_qty < 0 or @shipment_qty < 0
	begin
		insert into [APCSProDWH].[dbo].[ukebarai_errors]
		(
			[lot_no]
			,[process_no]
			,[date]
			,[time]
			,[good_qty]
			,[ng_qty]
			,[shipment_qty]
			,[mc_name]
		)
		values
		(
			 @Lotno
			,@process_no
			,@date
			,@time
			,@good_qty
			,@ng_qty
			,@shipment_qty
			,HOST_NAME()
		);
	end
	else 
	begin
		insert into [APCSProDWH].[dbo].[ukebarais]
		(
			[lot_no]
			,[process_no]
			,[date]
			,[time]
			,[good_qty]
			,[ng_qty]
			,[shipment_qty]
			,[mc_name]
		)
		values
		(
			 @Lotno
			,@process_no
			,@date
			,@time
			,@good_qty
			,@ng_qty
			,@shipment_qty
			,HOST_NAME()
		);
	end
END
