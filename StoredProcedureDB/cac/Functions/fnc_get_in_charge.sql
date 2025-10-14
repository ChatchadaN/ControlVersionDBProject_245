CREATE FUNCTION [cac].[fnc_get_in_charge](

)
    RETURNS @table_in_charge table (
		name varchar(50)
	)
AS
BEGIN
    insert into @table_in_charge
	(
		name
	)
	select name
	from (
		select 'Mr.Santi' as name
		union
		select 'Mr.Wichan' as name
		union
		--select 'Mr.Nittiwat' as name
		select 'Ms.Waratchanok' as name
		union
		select 'Mr.ChatChai' as name
		union
		select 'Mr.Kitti' as name
		union
		select 'Ms.Onjira' as name
		union
		select 'Mr.Jatupong' as name
		union
		select 'Mr.Thanyawat' as name
		union
		select 'Mr.Somprasong' as name
		union
		select 'Ms.Nuchanart' as name
		union
		select 'Mr.Suthep' as name
		union
		select 'Mr.Sukhon' as name
		union
		select 'Mr.Channarong' as name
		union
		select 'Mr.Thana' as name
		union
		select 'Mr.Suraphan' as name
		union
		select 'Mr.Praphon' as name
		union
		select 'Mr.Chalermchai' as name
		union
		--select 'Mr.Jutawut' as name
		select 'Mr.Matthana' as name
		union
		select 'Mr.Chisiri' as name
		union
		select 'Mr.Narongdate' as name
		--union
		--select 'Mr.Jeena' as name
		--union
		--select 'Ms.Supatsorn' as name
		union
		select 'Mr.Danai' as name
		union
		select 'Mr.Chirasit' as name
		union
		select 'Mr.Panuwat' as name
		union
		select 'Mrs. Supichra' as name

		--select 'Mr.Santi' as name
		--union
		--select 'Mr.Wichan' as name
		--union
		--select 'Mr.Panuwat' as name
		--union
		--select 'Mr.Wichan' as name
		--union
		--select 'Mr.Nittiwat' as name
		--union
		--select 'Mr.Kitti' as name
		--union
		--select 'Mr.Thanyawat' as name
		--union
		--select 'Mr.ChatChai' as name
		--union
		--select 'Mr.Jatupong' as name
		--union
		--select 'Mr.Chalermchai' as name
		--union
		--select 'Mr.Jutawut' as name
		--union
		--select 'Mr.Praphon' as name
		--union
		--select 'Ms.Onjira' as name
	) as [In-charge]
	order by name

    return;
END;