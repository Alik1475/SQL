









-- exec QORT_ARM_SUPPORT.dbo.OrdersUpdate

CREATE PROCEDURE [dbo].[OrdersUpdate]

	--@SelectData bit = 0

      @SendMail bit = 0

	 ,@NotifyEmail varchar(1024) = 'aleksandr.mironov@armbrok.am;sona.nalbandyan@armbrok.am'

	 

AS



BEGIN



begin try



declare @Message varchar(1024) -- для уведомлений об ошибках



declare @todayDate date = getdate()

declare @todayInt int = cast(convert(varchar, @todayDate, 112) as int)



insert into QORT_BACK_TDB..ImportTradeInstrs (

ET_Const, IsProcessed, SystemID, AuthorFIO)



select 4 ET_Const, 1 IsProcessed, ti.id id, 

cast('Modified: '+um.first_name + um.last_name+'('+ QORT_ARM_SUPPORT.dbo.fIntToDateVarchar(ti.modified_date) + ' ' +

iif(left(ti.modified_time,2) > 23,left(ti.modified_time,2),cast(cast(left(ti.modified_time,2) as varchar)+ ':'+ cast(substring(cast(ti.modified_time as varchar),3,2) as varchar) as varchar))+');'+

' Created: '+uc.first_name + uc.last_name + ' '+ '('+ QORT_ARM_SUPPORT.dbo.fIntToDateVarchar(ti.created_date) + ' '+

iif(left(ti.created_time,2) > 23,left(ti.created_time,2),cast(cast(left(ti.created_time,2) as varchar)+ ':'+ cast(substring(cast(ti.created_time as varchar),3,2) as varchar) as varchar))+')' as varchar(100)) AuthorFIO



from QORT_BACK_DB..TradeInstrs ti

left outer join QORT_BACK_DB..Users uc with (nolock) on uc.id = ti.user_created

left outer join QORT_BACK_DB..Users um with (nolock) on um.id = ti.user_modified

where ti.modified_date = @todayInt and ti.user_modified not in(1,2,3,4,5,6,7,8,9,10,11,12,13) -- пользователи - серверные компоненты



select 4 ET_Const, 1 IsProcessed, ti.id SystemID

, IIF(tr.Trade_ID is null, ti.IS_Const, iif(ph.PC_Const is null, 2, 5)) as is_const -- здесь только фазы PC_Const = 4 (full delivery)

, ph.PhaseDate

, ti.Qty Qty_Order

, ph.QtyBefore Qty_Trade

, CAST (0 as float) Qty_TradeSum

, ti.IS_Const IS_Const_curr

INTO #tt

from QORT_BACK_DB..TradeInstrs ti

left outer join QORT_BACK_DB..Users uc  on uc.id = ti.user_created

left outer join QORT_BACK_DB..Users um  on um.id = ti.user_modified

left outer join QORT_BACK_DB..TradeInstrLinks tr  on ti.id = tr.TradeInstr_ID and (select repotrade_id from QORT_BACK_DB..Trades where tr.Trade_ID = id) < 0 -- убрали сделки РЕПО из апдейда статусов

left outer join QORT_BACK_DB..Phases ph on tr.Trade_ID = ph.Trade_ID and ph.PC_Const = 4 and ph.IsCanceled = 'n' 

where ti.date > 20240401 and ph.PC_Const is not null -- поручения с начала года. Нужно будет придумать логику - сократить поиск

SELECT * FROM #tt

order by SystemID

--select * from #tt

UPDATE #tt
SET Qty_TradeSum = (
    SELECT SUM(Qty_Trade)
    FROM #tt AS t2
    WHERE t2.SystemID = #tt.SystemID
)

--select * from #tt order by SystemID return

UPDATE #tt
SET is_const = 11 where Qty_Order < Qty_TradeSum and Qty_Order <> 0 -- is_const = 7 правильно указать. НО тогда статус станет Done. Времеено пока Арка не подскажет решение.
UPDATE #tt
SET is_const = 4 where Qty_Order > Qty_TradeSum and Qty_Orde
r <> 0  

------------------------------------- УДАЛЕНИЕ СТРОК ГДЕ НЕ ПОМЕНЯЛСЯ СТАТУС---------------------------
delete from #tt where is_const = IS_Const_curr;

----------------------------- УДАЛЕНИЕ ЗАДВОЕННЫХ СТРОК, ОСТАВЛЯЯ ГДЕ МАКСИМАЛЬНАЯ ФАЗА-----
-------------
WITH CTE AS (

    SELECT ROW_NUMBER() OVER (PARTITION BY SystemID ORDER BY PhaseDate DESC) AS RowNum

         , *

    FROM #tt 

)

DELETE FROM CTE

WHERE RowNum > 1;

-----------------------------------------------------
select * from #tt-- return
	insert into QORT_BACK_TDB..ImportTradeInstrs (

	ET_Const, IsProcessed, SystemID, IS_Const, FinishDate)

	select ET_Const, IsProcessed, SystemID, is_const, IIF(is_const IN(5), PhaseDate, 0) as FinishDate

	from #tt

	select * from #tt

drop table #tt







	

	end try

	begin catch

		while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		print @Message

		select @Message Result, 'red' ResultColor

	end catch



END
