-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE lds.sp_set_lot_record_menu_template_manual
	@template_name NVARCHAR(50), @column_name NVARCHAR(50), @emp_id int
AS
BEGIN
	-- SET NOCOUNT ON added to prevent extra result sets from
	-- interfering with SELECT statements.
	SET NOCOUNT ON;

	DECLARE @menu_id int, @template_id int, @new_id int;

     select @menu_id = id
	 from APCSProDWR.lds.lot_record_menu
	 where column_name = @column_name;

	 select @template_id = id
	 from APCSProDWR.lds.lot_record_templates
     where [name] = @template_name


	 EXEC	[StoredProcedureDB].[lds].[sp_get_number_id]
						@TABLENAME = 'lot_record_menu_templates.id',
						@NEWID = @new_id OUTPUT

	 insert into APCSProDWR.lds.lot_record_menu_templates
	 (id, lot_record_templates_id, lot_record_menu_id, is_display, created_at, created_by)
	VALUES
	(@new_id, @template_id, @menu_id, 1, GETDATE(), @emp_id)


END
