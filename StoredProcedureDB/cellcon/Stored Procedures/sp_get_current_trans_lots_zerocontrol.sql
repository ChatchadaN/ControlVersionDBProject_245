-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_get_current_trans_lots_zerocontrol]
	-- Add the parameters for the stored procedure here
		@lot_no varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
		DECLARE	@isSpecialFlow as int,
			@specialFlowId as int

			SELECT	@isSpecialFlow = APCSProDB.trans.lots.is_special_flow,
					@specialFlowId = APCSProDB.trans.lots.special_flow_id
					FROM APCSProDB.trans.lots WHERE APCSProDB.trans.lots.lot_no = @lot_no

		IF (@isSpecialFlow = 1)
		BEGIN
			SELECT APCSProDB.trans.lots.lot_no,APCSProDB.trans.lots.id as LotId,APCSProDB.trans.lots.qty_pass as Good
                ,APCSProDB.trans.lots.qty_fail as NG ,APCSProDB.trans.lots.qty_p_nashi as PNashi,APCSProDB.trans.lots.qty_front_ng as FrontNg
                ,APCSProDB.trans.lots.qty_marker as MarkerNg,APCSProDB.trans.lots.qty_cut_frame as CutFrame
                ,APCSProDB.trans.lots.qty_pass_step_sum as GoodStepSum,APCSProDB.trans.lots.qty_fail_step_sum as NgStepSum 
				,APCSProDB.trans.lots.qty_hasuu as Surplus
				,APCSProDB.trans.lots.qty_out as Shipment
				,APCSProDB.trans.lots.is_special_flow as IsSpecialFlow
				,APCSProDB.trans.lots.special_flow_id as SpecialFlowId
                FROM APCSProDB.trans.lots WHERE APCSProDB.trans.lots.lot_no = @lot_no
		END
		
END
