-- =============================================
-- Author:		Apichaya Sazuzao
-- Create date: 17/07/2025
-- Description:	get label_shipment_logo
-- =============================================
CREATE PROCEDURE [method].[sp_get_label_shipment_logo_ver_001]  
@value int = 0
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

    SELECT [id]
      ,[value]
      ,[description]
      ,[file_extension]
      ,[picture_data]
      ,[created_at]
      ,[created_by]
      ,[updated_at]
      ,[updated_by]
  FROM [APCSProDBFile].[method].[label_shipment_logo]
    WHERE ([value] = @value or ISNULL(@value,0) = 0 )

END
