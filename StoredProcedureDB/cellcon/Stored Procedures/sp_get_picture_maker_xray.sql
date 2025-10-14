-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [cellcon].[sp_get_picture_maker_xray] 
	-- Add the parameters for the stored procedure here
	 @package varchar(50) = ''
	,@device  varchar(50) = ''

AS
BEGIN

	declare  @IsUse bit
	       -- ,@ErrorMessage varchar(50)

			set @IsUse = 0
			 SELECT TOP (1) @IsUse = Case when Marker = 'Yes' then 1 else 0 end

			 from DBx.dbo.XrayMarker		
			 WHERE (Package = @package) AND (Device = @device)
             order by id desc

			--if (@@ROWCOUNT = 0)
			--begin
			--	set	@ErrorMessage = 'data not found'
			--end
			 select @IsUse as IsUse --,@ErrorMessage as errorMessage
END
