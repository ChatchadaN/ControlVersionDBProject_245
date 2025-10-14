CREATE FUNCTION [trans].[fnc_get_e_slip_id](
	@e_slip_id varchar(50)
)
    RETURNS @table table (
		lot_no varchar(10),
		e_slip_id varchar(50)
	)
AS
BEGIN
    insert into @table 
	(
		lot_no
		, e_slip_id
	)
	select lot_no
		, e_slip_id
	from APCSProDB.trans.lots
	where e_slip_id = @e_slip_id;

    return;
END;