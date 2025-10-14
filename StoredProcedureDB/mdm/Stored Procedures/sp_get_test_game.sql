-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [mdm].[sp_get_test_game]
	-- Add the parameters for the stored procedure here

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	BEGIN
		SELECT surpluses.[id]
		  ,[lot_id]
		  ,[pcs]
		  ,TRIM([serial_no]) AS lot_no
		  ,[in_stock]
		  ,wip_state
		  ,packages.name
	  FROM [APCSProDB].[trans].[surpluses]
	  inner join [APCSProDB].[trans].lots on surpluses.lot_id = lots.id
	  inner join [APCSProDB].method.packages on lots.act_package_id = packages.id
	  where in_stock = 0 and surpluses.location_id is not null and wip_state != 20 
	--and packages.name in (
	--  'HRP5',
	--'HRP7',
	--'HSON8',
	--'HSON8-HF',
	--'HSON-A8',
	--'HSOP-M36',
	--'MSOP10',
	--'MSOP8',
	--'MSOP8-HF',
	--'SOP20',
	--'SOP22',
	--'SOP24',
	--'SOP24-HF',
	--'SOT223-4',
	--'SOT223-4F',
	--'SSOP-A20',
	--'SSOP-A24',
	--'SSOP-A32',
	--'SSOP-A44',
	--'SSOP-B24',
	--'SSOP-B28',
	--'SSOP-B40',
	--'TO220-6M',
	--'TO220-7M',
	--'TO252',
	--'TO252-5',
	--'TO252-J5',
	--'TO252-J5F',
	--'TO252S-5',
	--'TO252S-5+',
	--'TO252S-7+',
	--'TO263-3',
	--'TO263-3F',
	--'TO263-5',
	--'TO263-5F',
	--'TO263-7',
	--'TO263-7L',
	--'TSSOP-B30',
	--'TSSOP-B8J',
	--'TSSOP-C10J',
	--'SSOP-B24R',
	--'TO252S-3',
	--'WSOF5',
	--'TO252-J3',
	--'WSOF6',
	--'WSOF6I',
	--'HVSOF5',
	--'HVSOF6',
	--'HVSOF6-HF',
	--'SOP4',
	--'SOP4-HF',
	--'VSOF5'
	--  )
	END
END
