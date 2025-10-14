-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[sp_set_check_label]
	-- Add the parameters for the stored procedure here
	@qrcode varchar(max)
	,@code39_1 varchar(50)
	,@code39_2 varchar(50)
	,@data datetime
	,@mc varchar(20)
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	IF not exists(
		select 1 from  [DBx].[dbo].[check_label]
		 where [check_label].[qrcode] = @qrcode
		 and [check_label].code39_1 = @code39_1
		 and [check_label].code39_2 = @code39_2
		 and [check_label].MC = @mc
	 )
		 begin
			insert into [DBx].[dbo].[check_label] values (@qrcode,@code39_1,@code39_2,@data,@mc);
		 end
	 /*else
		begin
			select 'not insert'
		end*/
END
