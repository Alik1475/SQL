

--exec QORT_ARM_SUPPORT.dbo.updateBrokCommission



CREATE PROCEDURE [dbo].[updateBrokCommission]



AS

BEGIN



	SET NOCOUNT ON



	begin try



		declare @todayDate date = getdate()

		declare @todayInt int = cast(convert(varchar, @todayDate, 112) as int)

		declare @Message varchar(1024)

		declare @rows int

		declare @aid int = 0

		declare @WaitCount int

		declare @totalcurt int



		if OBJECT_ID('tempdb..#t', 'U') is not null drop table #t



		if OBJECT_ID('tempdb..##Result', 'U') is not null drop table ##Result



		if OBJECT_ID('tempdb..#t1', 'U') is not null drop table #t1

	

		SELECT 8 as ET_Const, 1 as Isprocessed

		, acc.ExportCode AccountExportCode

		, comm.Date

		, Comm.Time

		, Comm.BackID

		, Comm.Balance

		, Comm.BONum

		, tr.BuySell

		, asss.ShortName Calc_Currency_ShortName

		, Comm.Calc_Value

		, Comm.Comment

		, Comm.Commission_ID

		, ass.ShortName

		, accc.ExportCode

		, subb.SubAccCode GetSubAccCode

		, Comm.id as ID

		, sub.SubAccCode

		, Comm.InfoSource

		, PC_Const

		, Comm.PlanDate

		, Comm.Size

		, Comm.Trade_ID

		, tr.TradeDate

		, tr.TradeNum

		, tss.Name TSSection_Name

		into ##Result

		FROM QORT_BACK_DB.dbo.BlockCommissionOnTrades Comm with (nolock) 

		left outer join QORT_BACK_DB.dbo.Assets ass on ass.id = Comm.Asset_ID

		left outer join QORT_BACK_DB.dbo.Subaccs sub on sub.id = Comm.Subacc_ID

		left outer join QORT_BACK_DB.dbo.Accounts acc on acc.id = Comm.Account_ID

		left outer join QORT_BACK_DB.dbo.Trades tr on tr.id = Comm.Trade_ID

		left outer join QORT_BACK_DB.dbo.Assets asss on asss.id = Comm.Calc_Currency_ID

		left outer join QORT_BACK_DB.dbo.Accounts accc on accc.id = Comm.GetAccount_ID

		left outer join QORT_BACK_DB.dbo.Subaccs subb on subb.id = Comm.GetSubacc_ID

		left outer join QORT_BACK_DB.dbo.TSSections tss on tss.id = tr.TSSection_ID

		

		where comm.Date = @todayInt

		and Comm.Enabled = 0

		and ExecDate = 0

		--and tss.Name = 'AIX_Securities'

		select * from ##Result  

		--/*

		insert into QORT_BACK_TDB.dbo.ImportBlockCommissionOnTrades (ET_Const,Isprocessed

		, AccountExportCode

		, AccrualDate

		, AccrualTime

		, BackID

		, Balance

		, BONum

		, BuySell

		, Calc_Currency_ShortName

		, Calc_Value

		, Comment

		, Commission_SID

		, Currency_ShortName

		, GetAccountExportCode

		, GetSubAccCode

		, ID

		, SubAccCode

		, InfoSource

		, PC_Const

		, PlanDate

		, Size	

		, Trade_SystemID

		, TradeDate

		, TradeNum

		, TSSection_Name	

		)

	--*/

		select * from ##Result

			set @WaitCount = 1200

		while (@WaitCount > 0 and exists (select top 1 1 from QORT_BACK_TDB.dbo.ImportBlockCommissionOnTrades t with (nolock) where t.IsProcessed in (1,2)))

		begin

			waitfor delay '00:00:03'

			set @WaitCount = @WaitCount - 1

		end



	ALTER TABLE ##Result
	ADD Order_ID INT



		  UPDATE ##Result
	SET Order_ID = isnull(tsl.TradeInstr_ID, CAST(right(SubAccCode,4) as int))
	FROM ##Result rs
	left outer join QORT_BACK_DB.dbo.TradeInstrLinks tsl on tsl.Trade_ID = rs.Trade_ID
	





	update ##Result 

	set balance = ROUND(balance, 0)

	  , Calc_Value = ROUND(Calc_Value, 0)

	  , Size = IIF((ROUND(Size, 0) < 1), 1, ROUND(Size, 0))

	  , ET_Const = 2

	  



	  -- блок обновлнения данных для АМХ

	  select  DENSE_RANK() OVER (ORDER BY r.Order_ID) AS rank_num

	  , ROW_NUMBER() OVER (PARTITION BY Order_ID ORDER BY tra.TradeTime desc) AS row_num

	  , r.Size

	  ,r.SubAccCode, r.id

	  , 0 as total_sum

	  , tra.TradeTime

	  into #t

	  from ##Result r

	  left outer join QORT_BACK_DB.dbo.Trades tra on tra.id = r.trade_id

	  where r.TSSection_Name = 'AMX_Securities'

	  select * from #t



	  UPDATE #t
	SET total_sum = sub.total_sum
	FROM (
    SELECT rank_num, SUM(size) AS total_sum
    FROM #t
    GROUP BY rank_num
	) AS sub
	WHERE #t.rank_num = sub.rank_num;



	  select * from #t

	 



	  UPDATE R

	  set balance = (5000 - t.total_sum) + t.Size

	  , Calc_Value = (5000 - t.total_sum) + t.Size

	  , Size = (5000 - t.total_sum) + t.Size

	  from ##Result R

	  left outer join #t t on t.ID = R.ID

	  where t.total_sum < 5000 and t.row_num = 1 AND R.TSSection_Name = 'AMX_Securities'





	  -- блок обновления данных для AIX - AMD



	    select  DENSE_RANK() OVER (ORDER BY r.Order_ID) AS rank_num

	  , ROW_NUMBER() OVER (PARTITION BY r.Order_ID ORDER BY tra.TradeTime desc) AS row_num

	  , r.Size

	  ,r.SubAccCode, r.id

	  , 0 as total_sum

	  , tra.TradeTime

	  into #t1

	  from ##Result r

	  left outer join QORT_BACK_DB.dbo.Trades tra on tra.id = r.trade_id

	  where r.TSSection_Name = 'AIX_Securities' and r.ShortName = 'AMD'--

	  select * from #t1



	    UPDATE #t1
	SET total_sum = sub.total_sum
	FROM (
    SELECT rank_num, SUM(size) AS total_sum
    FROM #t1
    GROUP BY rank_num
	) AS sub
	WHERE #t1.rank_num = sub.rank_num;



	  select * from #t1

	 



	  UPDATE R

	  set balance = (100000 - t1.total_sum) + t1.Size

	  , Calc_Value = (100000 - t1.total_sum) + t1.Size

	  , Size = (100000 - t1.total_sum) + t1.Size

	  from ##Result R

	  left outer join #t1 t1 on t1.ID = R.ID

	  where t1.total_sum < 100000 and t1.row_num = 1 AND R.TSSection_Name = 'AIX_Securities' and R.ShortName = 'AMD'--



	  -- блок обновления данных для AIX - USD

	  if OBJECT_ID('tempdb..#t2', 'U') is not null drop table #t2



	  	    select  DENSE_RANK() OVER (ORDER BY r.Order_ID) AS rank_num

	  , ROW_NUMBER() OVER (PARTITION BY r.Order_ID ORDER BY tra.TradeTime desc) AS row_num

	  , r.Size

	  ,r.SubAccCode, r.id

	  , 0 as total_sum

	  , tra.TradeTime

	  into #t2

	  from ##Result r

	  left outer join QORT_BACK_DB.dbo.Trades tra on tra.id = r.trade_id

	  where r.TSSection_Name = 'AIX_Securities' and r.ShortName = 'USD'--

	  select * from #t2



	    UPDATE #t2
	SET total_sum = sub.total_sum
	FROM (
    SELECT rank_num, SUM(size) AS total_sum
    FROM #t2
    GROUP BY rank_num
	) AS sub
	WHERE #t2.rank_num = sub.rank_num;



	  select * from #t2

	 

	 set @totalcurt = ROUND(100000 / (select bid from QORT_BACK_DB.dbo.CrossRatesHist where OldDate = @todayInt

																						and InfoSource = 'CBA-1'

																						and TradeAsset_ID in (8))-- USD

																						, 0)

	  UPDATE R

	  set balance = (@totalcurt - t2.total_sum) + t2.Size

	  , Calc_Value = (@totalcurt - t2.total_sum) + t2.Size

	  , Size = (@totalcurt - t2.total_sum) + t2.Size

	  from ##Result R

	  left outer join #t2 t2 on t2.ID = R.ID

	  where t2.total_sum < @totalcurt and t2.row_num = 1 AND R.TSSection_Name = 'AIX_Securities' and R.ShortName = 'USD'--

	  --/*



	  ALTER TABLE ##Result
		DROP COLUMN Order_ID



		insert into QORT_BACK_TDB.dbo.ImportBlockCommissionOnTrades (ET_Const,Isprocessed

		, AccountExportCode

		, AccrualDate

		, AccrualTime

		, BackID

		, Balance

		, BONum

		, BuySell

		, Calc_Currency_ShortName

		, Calc_Value

		, Comment

		, Commission_SID

		, Currency_ShortName

		, GetAccountExportCode

		, GetSubAccCode

		, ID

		, SubAccCode

		, InfoSource

		, PC_Const

		, PlanDate

		, Size	

		, Trade_SystemID

		, TradeDate

		, TradeNum

		, TSSection_Name	

		)

	--*/

		select * from ##Result

		---------------------------------- удаление значений в таблице начисленных комиссий--------

		delete FROM QORT_BACK_DB.dbo.BlockPositionHist where Date = @todayInt



		-------------------------------------------------------------------------------------------------

	end try

	begin catch

		while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		select @Message result, 'STATUS' defaultTask, 'red' color

	end catch



END

