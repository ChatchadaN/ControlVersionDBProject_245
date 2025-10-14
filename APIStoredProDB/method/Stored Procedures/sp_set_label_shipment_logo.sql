-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [method].[sp_set_label_shipment_logo]
	@value			INT,
      @description		VARCHAR(MAX)	= null,
      @file_extension	VARCHAR(5)		,
      @picture_data		nvarchar(MAX)	,
	  @emp_code			nvarchar(6)		= null
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    -- Insert statements for procedure here
	EXEC APIStoredProVersionDB.method.sp_set_label_shipment_logo_ver_001
		@value			=	@value,
		@description	=	@description,
		@file_extension =	@file_extension,
		@picture_data	=	@picture_data ,
		@emp_code		=   @emp_code
END
