-- =============================================
-- Author:		<Author,,Wathanavipa>
-- Create date: <Create Date,,20220319>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_workingslip_lot_recall] 
	-- Add the parameters for the stored procedure here
	@lotno varchar(10)
AS
BEGIN
	
	EXEC [StoredProcedureDB].[dbo].[tg_sp_get_workingslip_lot_recall_ver_002] 
	@lotno = @lotno
	
END
