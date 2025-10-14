
-- =============================================
-- Author:		<Database Admin,,NutchanaT k.>
-- Create date: <14/07/2025,,>
-- Description:	<List Employee,,>
-- =============================================
CREATE PROCEDURE [mc].[sp_set_regis_machines]
	-- Add the parameters for the stored procedure here
	@headquarter_id AS INT
	,@name AS  varchar (30)
	,@short_name1 AS varchar (20)
	,@short_name2 AS varchar (20) =NULL
	,@barcode AS varchar (20) =NULL
	,@machine_model_id AS INT =NULL
	,@cell_ip AS varchar (15) =NULL
	,@machine_ip1 AS varchar (15) =NULL
	,@machine_ip2 AS varchar (15) =NULL
	,@terminal_ip AS varchar (15) =NULL
	,@display_size AS varchar (10) =NULL
	,@location_id AS INT =NULL
	,@machine_arrived AS date 
	,@serial_no  AS nvarchar (20) =NULL
	,@acc_location_id AS INT =NULL
	,@machine_level AS int =NULL
	,@is_fictional AS BIT =NULL
	,@connectable_number AS tinyint =NULL
	,@cell_num  AS tinyint =NULL
	,@is_disabled AS BIT =NULL
	,@code_for_strip char(2) =NULL
	,@application_set_id AS INT =NULL
	,@emp_code AS varchar (6) =NULL

AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	-- ########## VERSION 001 ##########
	EXEC [APIStoredProVersionDB].[mc].[sp_set_regis_machines_ver_001]
	@headquarter_id 	 = @headquarter_id 
	,@name 		         = @name 
	,@short_name1 		 = @short_name1 
	,@short_name2 		 = @short_name2 
	,@barcode 		     = @barcode 
	,@machine_model_id 	 = @machine_model_id 
	,@cell_ip 		     = @cell_ip 
	,@machine_ip1 		 = @machine_ip1 
	,@machine_ip2 		 = @machine_ip2 
	,@terminal_ip 		 = @terminal_ip 
	,@display_size 		 = @display_size 
	,@location_id 		 = @location_id 
	,@machine_arrived 	 = @machine_arrived 
	,@serial_no 		     = @serial_no 
	,@acc_location_id 	 = @acc_location_id 
	,@machine_level		 = @machine_level
	,@is_fictional 		 = @is_fictional 
	,@connectable_number  = @connectable_number 
	,@cell_num		  = @cell_num
	,@is_disabled 		 = @is_disabled 
	,@code_for_strip 	 = @code_for_strip 
	,@application_set_id	 = @application_set_id
	,@emp_code		        = @emp_code


	-- ########## VERSION 001 ##########

END
