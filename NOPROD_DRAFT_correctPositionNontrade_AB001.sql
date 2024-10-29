

--exec QORT_ARM_SUPPORT_TEST.dbo.NOPROD_DRAFT_correctPositionNontrade_AB001



create PROCEDURE [dbo].[NOPROD_DRAFT_correctPositionNontrade_AB001]

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



		insert into QORT_BACK_TDB_UAT..CorrectPositions (ET_Const,Isprocessed, SystemID, CT_Const, Subacc_Code, Asset, Account_ExportCode

		, RegistrationDate, GetAccount_ExportCode, GetSubacc_Code, GetSubaccOwnerFirm_ShortName, GetSubaccOwnerFirm_BOCode)

		SELECT 4 as ET_Const, 1 as Isprocessed, corP.id SystemID, CT_Const

		,sa.SubAccCode as Subacc_Code, ass.ShortName as Asset, acc.ExportCode Account_ExportCode, CorP.RegistrationDate RegistrationDate

		, iif(Corp.GetAccount_ID > 0, acc1.ExportCode, acc.ExportCode) GetAccount_ExportCode , IIF(CorP.GetSubAcc_ID > 0, sa1.SubAccCode, 'AB0001') GetSubacc_Code

		, f1.FirmShortName GetSubaccOwnerFirm_ShortName

		, f1.BOCode GetSubaccOwnerFirm_BOCode

		--into #t

		FROM QORT_BACK_DB_UAT..CorrectPositions CorP with (nolock) 

		left outer join QORT_BACK_DB_UAT..Subaccs sa with (nolock) on sa.id= CorP.Subacc_ID

		left outer join QORT_BACK_DB_UAT..Subaccs sa1 with (nolock) on sa1.id= CorP.GetSubAcc_ID

		left outer join QORT_BACK_DB_UAT..Firms f1 with (nolock) on f1.id= sa1.OwnerFirm_ID

		left outer join QORT_BACK_DB_UAT..Assets ass with (nolock) on CorP.Asset_ID = ass.ID

		left outer join QORT_BACK_DB_UAT..Accounts acc with (nolock) on CorP.Account_ID = acc.id

		left outer join QORT_BACK_DB_UAT..Accounts acc1 with (nolock) on CorP.GetAccount_ID = acc1.id

		where CorP.Date > 20240601 and CT_Const in (72,71,55,70,32,15)   --70 - statement fee

																		 --32 - Depository fee-maintenace

																		 --15 - Brokerage commission for Repo trade

	and sa.SubAccCode = 'AS1049'

		--select * from #t

		

	







	end try

	begin catch

		while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		select @Message result, 'STATUS' defaultTask, 'red' color

	end catch



END

