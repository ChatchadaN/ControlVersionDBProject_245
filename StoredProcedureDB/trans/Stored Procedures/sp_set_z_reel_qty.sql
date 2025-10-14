-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [trans].[sp_set_z_reel_qty]
	-- Add the parameters for the stored procedure here
	@lot_no varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here
	declare @qty_disable int = NULL
	declare @reel_disable int = NULL
	declare @qty_out int = NULL
	declare @qty_hasuu int = NULL
	declare @pcs_per_pack int = NULL

	if exists( 
		select 1 
		from APCSProDB.trans.label_issue_records where  lot_no = @lot_no and type_of_label = 21
	) 
	begin
		select 'PC_Request'
	end
	else begin
		set @pcs_per_pack = (select pcs_per_pack from APCSProDB.trans.lots
		inner join APCSProDB.method.device_names on lots.act_device_name_id = device_names.id
		where  lot_no = @lot_no)

		select @qty_disable = sum(CAST(qty as int)),@reel_disable = count(qty)  from APCSProDB.trans.label_issue_records
		where  lot_no = @lot_no and type_of_label = 0

		set @qty_out = (select sum(CAST(qty as int)) as qty from APCSProDB.trans.label_issue_records
		where  lot_no = @lot_no and type_of_label = 3)

		set @qty_hasuu = (select sum(CAST(qty as int)) as qty from APCSProDB.trans.label_issue_records
		where  lot_no = @lot_no and type_of_label = 2)

		--select isnull(@qty_disable,0) as qty_disable
		--, @reel_disable as reel_disable
		--, (@qty_hasuu + isnull(@qty_disable,0)) as qty_hasuu
		--, @qty_out as qty_out
		--, @pcs_per_pack as pcs_per_pack

		update APCSProDB.trans.surpluses
			set pcs = (@qty_hasuu + isnull(@qty_disable,0))
		where  serial_no = @lot_no;

		update APCSProDB.trans.lots
			set qty_out = @qty_out
				, qty_hasuu = (@qty_hasuu + isnull(@qty_disable,0))
		where lot_no = @lot_no;

		update APCSProDB.trans.label_issue_records
			set qty = (@qty_hasuu + isnull(@qty_disable,0))
				, barcode_bottom = RIGHT('000000'+ CONVERT(VARCHAR,(@qty_hasuu + isnull(@qty_disable,0))),6)
					+ ' ' + Cast(SUBSTRING(lot_no, 1, 4) + ' ' + SUBSTRING(lot_no, 5, 6) as char(10))
		where  lot_no = @lot_no and type_of_label = 2;
	end
END
