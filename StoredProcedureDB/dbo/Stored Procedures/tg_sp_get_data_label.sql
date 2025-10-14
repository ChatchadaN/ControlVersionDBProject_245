
--Temporarily enable xp_cmdshell


CREATE PROCEDURE [dbo].[tg_sp_get_data_label] 
	-- Add the parameters for the stored procedure here
	
AS
BEGIN
	
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
	declare @DateStamp varchar(2000)

	declare @path varchar(2000)
	declare @Txt varchar(2000)

	declare @YYYY int
	declare @MM int
	declare @DD int

	declare @YYYY_Txt varchar(2000)
	declare @MM_Txt varchar(2000)
	declare @DD_Txt varchar(2000)

    -- Insert statements for procedure here
	set @YYYY = DATEPART(YYYY,GETDATE())
	set @YYYY_Txt = CAST(@YYYY As varchar(2000))

	set @MM =  DATEPART(MM,GETDATE())
	set @MM_Txt = CAST(@MM As varchar(2000))

	set @DD =  DATEPART(DD,GETDATE())
	set @DD_Txt = CAST(@DD As varchar(2000))

	SET @DateStamp = @YYYY_Txt + '_' + @MM_Txt +'_'+ @DD_Txt 

	Set @path = 'C:\Logfile'+ @DateStamp +'.txt'
	set @Txt = 'test to read file text'

	EXECUTE xp_cmdshell @path ,no_output ,@Txt ,no_output

END


