
-- =============================================
-- Author:		<Database Admin,,NutchanaT k.>
-- Create date: <14/07/2025,,>
-- Description:	<List Employee,,>
-- =============================================
CREATE PROCEDURE [mc].[sp_set_models]
	-- Add the parameters for the stored procedure here
	 @method AS INT --(1: Insert , 2: Update)
	  ,@id AS INT = 0
	  ,@name AS  varchar (30)
      ,@short_name AS  nvarchar (20)
      ,@headquarter_id AS INT
      ,@maker_id AS INT = NULL
      ,@process_type AS tinyint = NULL
      ,@map_using AS tinyint = NULL
      ,@map_type AS tinyint = NULL
      ,@bin_type AS tinyint = NULL
      ,@is_linked_with_work AS tinyint = NULL
      ,@enable_lot_max AS tinyint = NULL
      ,@ppid_type1  AS tinyint = NULL
      ,@ppid_type2  AS tinyint = NULL
      ,@is_carrier_register  AS tinyint = NULL
      ,@is_carrier_transfer  AS tinyint = NULL
      ,@is_carrier_verification_setup AS tinyint = NULL
      ,@is_carrier_verification_end   AS tinyint = NULL
      ,@limit_sec_for_carrierinput    AS INT = NULL
      ,@allowed_control_condition    AS tinyint = NULL
      ,@is_magazine_register AS tinyint = NULL
      ,@is_magazine_transfer AS tinyint = NULL
      ,@is_magazine_verification_setup AS tinyint = NULL
      ,@is_magazine_verification_end AS tinyint = NULL
      ,@limit_sec_for_magazineinput AS INT = NULL
      ,@wafer_map_using AS tinyint = NULL
      ,@wafer_map_type AS tinyint = NULL
      ,@wafer_map_bin_type AS tinyint = NULL
	  ,@emp_code AS varchar (6)  = NULL

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- ########## VERSION 001 ##########
	EXEC [APIStoredProVersionDB].[mc].[sp_set_model_ver_001]
	 @method =  @method
	,@id     = @id
	,@name   =    @name   
	,@short_name   =    @short_name   
	,@headquarter_id =    @headquarter_id 
	,@maker_id  =    @maker_id  
	,@process_type  =    @process_type  
	,@map_using  =    @map_using  
	,@map_type  =    @map_type  
	,@bin_type  =    @bin_type  
	,@is_linked_with_work  =    @is_linked_with_work  
	,@enable_lot_max  =    @enable_lot_max  
	,@ppid_type1   =    @ppid_type1   
	,@ppid_type2   =    @ppid_type2   
	,@is_carrier_register  =    @is_carrier_register  
	,@is_carrier_transfer  =    @is_carrier_transfer  
	,@is_carrier_verification_setup=    @is_carrier_verification_setup
	,@is_carrier_verification_end  =    @is_carrier_verification_end  
	,@limit_sec_for_carrierinput   =    @limit_sec_for_carrierinput   
	,@allowed_control_condition   =    @allowed_control_condition   
	,@is_magazine_register =    @is_magazine_register 
	,@is_magazine_transfer =    @is_magazine_transfer 
	,@is_magazine_verification_setup =    @is_magazine_verification_setup 
	,@is_magazine_verification_end =    @is_magazine_verification_end 
	,@limit_sec_for_magazineinput  =    @limit_sec_for_magazineinput  
	,@wafer_map_using =    @wafer_map_using 
	,@wafer_map_type  =    @wafer_map_type  
	,@wafer_map_bin_type    =   @wafer_map_bin_type                   
	,@emp_code=    @emp_code



	-- ########## VERSION 001 ##########

END
