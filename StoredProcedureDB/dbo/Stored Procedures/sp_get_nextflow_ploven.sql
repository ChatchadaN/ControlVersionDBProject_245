-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE sp_get_nextflow_ploven
	-- Add the parameters for the stored procedure here
	@lot_no varchar(10)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF EXISTS(SELECT [LOT_NO]
		FROM [APCSDB].[dbo].[LOT2_DATA]
		where LAY_NO = '0237'
		and REAL_DAY is not null
		and LOT_NO = @lot_no)
	BEGIN
		select OPE_NAME
		from
			(SELECT [LOT_NO]
				, [N_OPE_SEQ]
			FROM [APCSDB].[dbo].[LOT1_DATA]
			where LAY_NO = '0237'
			and LOT_NO = @lot_no) as master_data
		inner join
			(select [LOT1_DATA].[LOT_NO]
				, [LOT1_DATA].[OPE_SEQ]
				, [LAYER_TABLE].[OPE_NAME]
			from [APCSDB].[dbo].[LOT1_DATA]
			inner join [APCSDB].[dbo].[LAYER_TABLE] on [LAYER_TABLE].[LAY_NO] = [LOT1_DATA].[LAY_NO]
			where [LOT1_DATA].[LOT_NO] = @lot_no ) as next_step on [next_step].[LOT_NO] = [master_data].[LOT_NO] and [next_step].[OPE_SEQ] = [master_data].[N_OPE_SEQ]
	END
	ELSE
	BEGIN
		select 'NOT END OVEN' as OPE_NAME
	END
END
