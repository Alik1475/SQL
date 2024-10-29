

--exec QORT_ARM_SUPPORT.dbo.ForRepo_PutDatePayDateCorrect



CREATE PROCEDURE [dbo].[ForRepo_PutDatePayDateCorrect]

	@taskName varchar(32) = null

AS

BEGIN



	SET NOCOUNT ON



	begin try



		set @taskName = nullif(@taskName, '')

		declare @todayDate date = getdate()

		declare @todayInt int = cast(convert(varchar, @todayDate, 112) as int)

		declare @Message varchar(1024)

		declare @rows int

		declare @aid int = 0

		declare @WaitCount int



		IF OBJECT_ID('tempdb.dbo.#t', 'U') IS NOT NULL DROP TABLE #t;



		--INSERT INTO QORT_BACK_TDB.dbo.ImportTrades (ET_Const, IsProcessed, TradeNum, BuySell, TradeDate, TSSection_Name, IsRepo2, BackDate, IsSynchronize) 

		select 4 as ET_Const,1 as IsProcessed, Trd.TradeNum, Trd.BuySell, Trd.TradeDate, Tss.Name, Trd.IsRepo2, Tr.PayPlannedDate, 'y' as IsSynchronize--, Tr.PutPlannedDate PutPlannedDate

		--into #t

				from QORT_BACK_DB.dbo.Trades Tr		

		left outer join QORT_BACK_DB.dbo.TSSections Tss with (nolock) on Tss.ID = Tr.TSSection_ID

		left outer join QORT_BACK_DB.dbo.Trades Trd with (nolock) on Tr.ID = Trd.RepoTrade_ID

		where  tr.TT_Const in (1,6) and tr.IsRepo2 = 'y' and tr.PutPlannedDate <> tr.PayPlannedDate and Tr.Enabled <> tr.ID and tr.VT_Const <> 10--статус подписи(10 - расторжение)

	

	end try

	begin catch

		while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		select @Message result, 'STATUS' defaultTask, 'red' color

	end catch



END
