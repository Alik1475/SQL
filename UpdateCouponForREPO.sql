

--exec QORT_ARM_SUPPORT_TEST.dbo.DRAFT



CREATE PROCEDURE [dbo].[UpdateCouponForREPO]

	

AS

BEGIN



	SET NOCOUNT ON



	begin try



			if OBJECT_ID('tempdb..#t', 'U') is not null drop table #t

	if OBJECT_ID('tempdb..#tt', 'U') is not null drop table #tt

	declare @Message varchar(1024)

	declare @n int

	declare @tab table (idn int)

	declare @asssetID int 

	declare @todayDate date = getdate()

	declare @todayInt int = cast(convert(varchar, @todayDate, 112) as int)

	-----------------------------------------------блок обнуления ставки и объема купона--------------------------------------------

	select cup.CouponNum, cup.Description DescriptionCurr, cup.Volume, cup.Procent, ass.ShortName, CAST(cast(cup.CouponNum as varchar(128))+'/'+cast(cup.Volume as varchar(128))+'/'+cast(cup.Procent as varchar(128)) as varchar(128)) Description--, *

	into #t

	from QORT_BACK_DB_UAT..Trades tr

	left outer join QORT_BACK_DB_UAT..TSSections ts on ts.id = tr.TSSection_ID

	left outer join QORT_BACK_DB_UAT..Securities sec on sec.id = tr.Security_ID

	left outer join QORT_BACK_DB_UAT..Coupons cup on cup.Asset_ID = sec.Asset_ID and cup.BeginDate < @todayInt and cup.EndDate > @todayInt

	left outer join QORT_BACK_DB_UAT..Assets ass on cup.Asset_ID = ass.id

	where tr.TradeDate > 20240101 and ts.Name in ('AMX_REPO','ОТС_REPO') and tr.PutDate = 0 and tr.Enabled <> tr.id and charindex('/',cup.Description) = 0

 

	--select distinct * from #t

	 insert into QORT_BACK_TDB_UAT..Coupons (ET_Const, IsProcessed, Asset_ShortName, CouponNum, Procent, Volume, Description)

	 select distinct 4 as ET_Const, 1 as IsProcessed, ShortName Asset_ShortName, CouponNum CouponNum, 0 as Procent, 0 as Volume, Description

	 from #t 



	 ------------------------------------------------блок возрата значений ставки и объема купона-------------------------------------------

	select ROW_NUMBER() OVER (ORDER BY coup.Asset_ID) AS num, coup.Description Description1, coup.Asset_ID Asset_ID1, coup.CouponNum CouponNum, asss.ShortName Asset_ShortName

	into #tt

	from QORT_BACK_DB_UAT..Coupons coup

	 left outer join QORT_BACK_DB_UAT..Assets asss on asss.id = coup.Asset_ID

	where charindex('/',coup.Description) <> 0



	-- select * from #tt



		set @n = cast((select max(num) from #tt) as int)

	 ------------------------------------запускаем цикл проверки по каждому купону, имеющему "/" в наименовании Description, который ранее отобрали в таюлицу-----------------------------

	 while @n > 0

	 begin

		delete from @tab

		set @asssetID = CAST((select asset_id1 from #tt where num = @n) as int)



		insert into @tab (idn) 

		select trd.id idn from QORT_BACK_DB_UAT..Trades trd

			left outer join QORT_BACK_DB_UAT..Securities Sc on Sc.ID = trd.Security_ID 

			left outer join QORT_BACK_DB_UAT..Assets asse on asse.id = Sc.Asset_ID

		where trd.PutDate = 0 and trd.Enabled <> trd.id 

		and trd.TSSection_ID in (157,160) -- in ('AMX_REPO','ОТС_REPO')

		and trd.NullStatus = 'n' and Sc.Asset_ID = @asssetID



	  --select * from @tab 



		if EXISTS(select idn from @tab) -- проверка есть сделки с бумагой, у которой купон был сброшен или нет---------------------------

			begin
				set @n = @n - 1
			end
		  else
			begin

				insert into QORT_BACK_TDB_UAT..Coupons (ET_Const, IsProcessed, Description, Asset_ShortName, CouponNum, Volume,Procent)

				select 4 as ET_Const, 1 as IsProcessed, LEFT(Description1, CHARINDEX('/', Description1) - 1) Description

				, Asset_ShortName

				, CouponNum

				, SUBSTRING(Description1, CHARINDEX('/', Description1) + 1, CHARINDEX('/', Description1, CHARINDEX('/', Description1) + 1) - CHARINDEX('/', Description1) - 1) as Volume

				, SUBSTRING(Description1, CHARINDEX('/', Description1, CHARINDEX('/', Description1) + 1) + 1, LEN(Description1)) as Procent
				from #tt
				where Asset_ID1 = @asssetID

				set @n = @n - 1
			--select * from @tab 
			end
	   END -- конец цикла







	end try

	begin catch

		while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		select @Message result, 'STATUS' defaultTask, 'red' color

	end catch



END

