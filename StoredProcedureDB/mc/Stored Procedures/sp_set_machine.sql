
CREATE PROCEDURE [mc].[sp_set_machine]
@id AS INT
,@is_disabled AS BIT
,@update_by AS varchar(6)
,@headquarter_id AS INT
,@name AS varchar(30)
,@machine_model_id AS INT
,@cell_ip AS varchar(15)
,@machine_ip1 AS varchar(15)
,@is_automotive AS BIT
AS
BEGIN
SET NOCOUNT ON;
UPDATE [APCSProDB].[mc].[machines]
SET 
headquarter_id = @headquarter_id
,is_disabled = @is_disabled
,updated_at = GETDATE()
,updated_by = @update_by
,name = @name
,machine_model_id = @machine_model_id
,cell_ip = @cell_ip
,machine_ip1 = @machine_ip1
,is_automotive = @is_automotive
WHERE id = @id

INSERT INTO [APCSProDB].[mc_hist].[machines_hist] 
(
	   [category]
      ,[id]
      ,[headquarter_id]
      ,[name]
      ,[short_name1]
      ,[short_name2]
      ,[barcode]
      ,[machine_model_id]
      ,[cell_ip]
      ,[machine_ip1]
      ,[machine_ip2]
      ,[terminal_ip]
      ,[display_size]
      ,[location_id]
      ,[acc_location_id]
      ,[is_automotive]
      ,[is_fictional]
      ,[connectable_number]
      ,[cell_num]
      ,[is_disabled]
      ,[code_for_strip]
      ,[application_set_id]
      ,[created_at]
      ,[created_by]
      ,[updated_at]
      ,[updated_by]
)
SELECT 2
	  ,[id]
      ,[headquarter_id]
      ,[name]
      ,[short_name1]
      ,[short_name2]
      ,[barcode]
      ,[machine_model_id]
      ,[cell_ip]
      ,[machine_ip1]
      ,[machine_ip2]
      ,[terminal_ip]
      ,[display_size]
      ,[location_id]
      ,[acc_location_id]
      ,[is_automotive]
      ,[is_fictional]
      ,[connectable_number]
      ,[cell_num]
      ,@Is_disabled
      ,[code_for_strip]
      ,[application_set_id]
      ,[created_at]
      ,[created_by]
      ,GETDATE()
      ,@update_by
	  FROM [APCSProDB].[mc].[machines] WHERE id = @Id
END

