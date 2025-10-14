
---- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [material].[sp_get_supplier_001]
	-- Add the parameters for the stored procedure here
		@supplier_cd		NVARCHAR(10)  = NULL
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;
    -- Insert statements for procedure here

		 SELECT	  supplier_cd
				, [name]
				, ISNULL(CONVERT(VARCHAR , suppliers.created_at,121),'')		AS created_at
				, ISNULL([employees].emp_code,'')		AS created_by
				, ISNULL(CONVERT(VARCHAR , suppliers.updated_at,121),'')		AS updated_at
				, ISNULL(updated.emp_code,'')			AS updated_by
		FROM  APCSProDB.material.suppliers
		LEFT JOIN [10.29.1.230].[DWH].[man].[employees]
		ON  [employees].id = suppliers.created_by
		LEFT JOIN [10.29.1.230].[DWH].[man].[employees]		AS updated
		ON  updated.id = suppliers.created_by
		WHERE supplier_cd = @supplier_cd  OR @supplier_cd IS NULL  
		 
END
