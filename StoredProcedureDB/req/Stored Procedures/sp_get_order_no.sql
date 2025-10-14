-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [req].[sp_get_order_no]
	-- Add the parameters for the stored procedure here
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	DECLARE @id INT;

	-- clear date
	UPDATE [APCSProDWR].[req].[number]
	SET [id] = (CASE WHEN CAST(GETDATE() AS DATE) > CAST([timestamp] AS DATE) THEN 0 ELSE [id] END)
		, [timestamp] = GETDATE()
	WHERE [item] = 'orders.order_no';

	-- get date
	SELECT @id = [id] + 1
	FROM [APCSProDWR].[req].[number]
	WHERE [item] = 'orders.order_no';
	
	UPDATE [APCSProDWR].[req].[number]
	SET [id] = @id
		, [timestamp] = GETDATE()
	WHERE [item] = 'orders.order_no';

	 SELECT 'J' -- J first
		+ FORMAT(GETDATE(), 'yy') -- year 2
		+ FORMAT(GETDATE(), 'MM') -- month 2
		+ FORMAT(GETDATE(), 'dd') -- day 2
		+ FORMAT(@id, '0000') -- auto number 4
	AS [order_no];
END