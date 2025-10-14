
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE  PROCEDURE [trans].[sp_get_lot_last_process]
	-- Add the parameters for the stored procedure here
		  @LotNo      NVARCHAR(20)		
		, @Process     INT		

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;	
	SELECT TOP 1 'TRUE' AS [Status] 
		, '' AS [Error_Message_ENG]
		, N'' AS [Error_Message_THA] 
		, N'' AS [Handling]
		, L.lot_no 
		, MC.name AS mc_no
		, M.emp_num AS opno_start
		,PKG.name AS pkg_name
   FROM [APCSProDB].[trans].[lot_process_records] AS LPR
   INNER JOIN  [APCSProDB].[trans].[lots] AS L 
   ON  LPR.lot_id = L.id 
   --ADD 2024-12-07
   INNER JOIN [APCSProDB].[method].[packages] AS PKG
   ON L.act_package_id = PKG.id
   --ADD 2024-12-07
   INNER JOIN [APCSProDB].[method].[processes] AS PC 
   ON LPR.process_id = PC.id
   INNER JOIN[APCSProDB].[mc].[machines] AS MC 
   ON LPR.machine_id = MC.id
   INNER JOIN[APCSProDB].[man].[users] AS M 
   ON LPR.operated_by = M.id
   WHERE L.lot_no = @LotNo  
	   AND LPR.process_id = @Process   
	   AND LPR.record_class = 1
   ORDER BY LPR.recorded_at DESC
   

END
