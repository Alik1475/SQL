

--exec QORT_ARM_SUPPORT_TEST.dbo.DRAFT



Create PROCEDURE [dbo].[AB0001Correction]

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



		if OBJECT_ID('tempdb..#t', 'U') is not null drop table #t







		if OBJECT_ID('tempdb..#t1', 'U') is not null drop table #t1



		insert into QORT_BACK_TDB_UAT..CorrectPositions (ET_Const,Isprocessed, CT_Const, RegistrationDate, Subacc_Code, Asset, Size, Account_ExportCode, Comment2)

		SELECT 2 as ET_Const, 1 as Isprocessed, 7 as CT_Const, @todayInt as RegistrationDate,

		sa.SubAccCode as Subacc_Code, ass.ShortName as Asset, ph.VolFree*(-1) as Size, acc.ExportCode as Account_ExportCode, 'For execution' Comment2

		

		FROM QORT_BACK_DB_UAT..Position ph with (nolock) 

		left outer join QORT_BACK_DB_UAT..Subaccs sa with (nolock) on sa.id= ph.Subacc_ID 

		left outer join QORT_BACK_DB_UAT..Assets ass with (nolock) on ph.Asset_ID = ass.id

		left outer join QORT_BACK_DB_UAT..Accounts acc with (nolock) on ph.Account_ID = acc.id

		where sa.SubAccCode = 'AB0001' and ph.VolFree > 0





		--select * from #t1



	







	end try

	begin catch

		while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		select @Message result, 'STATUS' defaultTask, 'red' color

	end catch



END

