-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date : 2023/02/06 Time : 15.35,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[tg_sp_get_AutoRun_Dlot_new]
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;


	INSERT INTO [StoredProcedureDB].[dbo].[exec_sp_history]
	([record_at]
      , [record_class]
      , [login_name]
      , [hostname]
      , [appname]
      , [command_text])
	SELECT GETDATE()
		,'4'
		,ORIGINAL_LOGIN()
		,HOST_NAME()
		,APP_NAME()
		,'EXEC [dbo].[tg_sp_get_AutoRun_Dlot_new]'


    -- Insert statements for procedure here
	--update autorun D Lot
	UPDATE [APCSProDWH].[tg].[AutoRunDLot]
	SET AutoRun = (AutoRun - 1)
	WHERE DayOfWeek = DATEPART(dw,getdate())

	--Get data newlotno
	 (SELECT right(YEAR(GETDATE()),2)
	 + case when len(DATEPART(week, GETDATE())) = 1 then CONCAT('0',DATEPART(week, GETDATE())) 
			else CAST(DATEPART(week, GETDATE()) As varchar ) end 
	 + CAST('D' AS varchar) 
	 + CAST(DATEPART(dw,getdate()) AS varchar)
	 + CAST(AutoRun As varchar)
	 + CAST('V' AS varchar) As lotnew
	 FROM [APCSProDWH].[tg].[AutoRunDLot] where DayOfWeek = DATEPART(dw,getdate()))
END
