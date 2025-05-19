

--exec QORT_ARM_SUPPORT.dbo.DepoReconcil @sendmail = 1



CREATE PROCEDURE [dbo].[DepoReconcil]

	--@taskName varchar(32) = null

	@sendmail bit

AS

BEGIN



	SET NOCOUNT ON



	begin try



		

	--	set @taskName = nullif(@taskName, '')

	--	declare @sendmail bit = 0

		declare @n int = 0

		declare @ytdDate date



		

		while dbo.fIsBusinessDay(DATEADD(DAY, -1-@n, getdate())) = 0 

			begin	

		set @n = @n + 1 

			end

		set @ytdDate = (DATEADD(DAY, -1-@n, getdate())) -- определили вчерашний бизнес день

		

		declare @ytdInt int = cast(convert(varchar, @ytdDate, 112) as int)

		declare @Message varchar(1024)

		declare @NotifyEmail varchar(1024) = 'depo@armbrok.am;araksya.harutyunyan@armbrok.am;arevik.petrosyan@armbrok.am;QORT@armbrok.am'--'aleksandr.mironov@armbrok.am'--;armine.khachatryan@armbrok.am';sona.nalbandyan@armbrok.am;Hayk.Manaselyan@armbrok.am;comp
liance@armbrok.am;armine.khachatryan@armbrok.am'

		declare @WaitCount int



		exec QORT_ARM_SUPPORT.dbo.upload_Depolite @QueryDate = @ytdDate



		if not exists (select 1 from QORT_BACK_TDB..CheckPositions where InfoSource in ('DEPOLITE') and CheckDate = @ytdInt) return

		if not exists (select 1 from QORT_BACK_TDB..CheckPositions where InfoSource in ('DEPEND') and CheckDate = @ytdInt) return



		if OBJECT_ID('tempdb..#t', 'U') is not null drop table #t

		if OBJECT_ID('tempdb..#t1', 'U') is not null drop table #t1

		if OBJECT_ID('tempdb..#t3', 'U') is not null drop table #t3



	select sub.SubaccName NameClient, sub.SubAccCode Account, acc.Name Settlement, ass.ISIN ISIN, pos.VolFree PositionQort

	, IIF(acc.Name in ('CLIENT_CDA_OWN', 'CLIENT_CDA_Own_ Frozen'), depend.depocode, depolite.depocode) DepoAccount

	, CAST((cast(isnull(sub.SubAccCode,'') as varchar(128))+'/'+cast(isnull(acc.Name,'') collate Cyrillic_General_CS_AS as varchar(128))+'/'+cast(isnull(ass.ISIN,'') as varchar(128))) as varchar(128)) subcontoQORT

	into #t

	from QORT_BACK_DB..PositionHist pos

	left outer join QORT_BACK_DB..Subaccs sub on pos.Subacc_ID = sub.id

	left outer join QORT_BACK_DB..Accounts acc on pos.Account_ID = acc.id

	left outer join QORT_BACK_DB..Assets ass on pos.Asset_ID = ass.id 

	OUTER APPLY (

    SELECT TOP 1 dep.DEPOCode as DEPOCode

    FROM QORT_BACK_DB..FirmDEPOAccs dep

    WHERE sub.SubAccCode = TRIM(dep.Code) COLLATE Cyrillic_General_CS_AS and trim(dep.Name) = 'Armbrok_DepoLite' COLLATE Cyrillic_General_CS_AS

) AS depolite	

	OUTER APPLY (

    SELECT TOP 1 dep.DEPOCode as DEPOCode

    FROM QORT_BACK_DB..FirmDEPOAccs dep

    WHERE sub.SubAccCode = TRIM(dep.Code) COLLATE Cyrillic_General_CS_AS and trim(dep.Name) = 'Armbrok_Depend' COLLATE Cyrillic_General_CS_AS

) AS depend

	where OldDate = @ytdInt and pos.VolFree <> 0

	and ass.AssetType_Const = 1 -- type Securities only

	and sub.SubAccCode not in ('AS_test')

	and left(IIF(acc.Name in ('CLIENT_CDA_OWN', 'CLIENT_CDA_Own_ Frozen'), depend.depocode, depolite.depocode),2) not in ('78');-- исключил счета, которых невидно в Депенд, но на которые зачислили бумаги

	----------------------------удаляем строки с одинаковым субконтоКорт которые образуются когда у клиента несколько счетов ДЕПО------------------

	WITH CTE AS (
    SELECT *,
           ROW_NUMBER() OVER (PARTITION BY subcontoQORT ORDER BY subcontoQORT) AS RowNum
    FROM #t -- замените на фактическое название таблицы
)
DELETE FROM CTE
WHERE RowNum > 1;

	

	select * from #t --where isin = 'AMGB1029A250'

	order by Account 



	select CAST((isnull(chk.subacc_code,'')+'/'+isnull(chk.account_ExportCode,'')+'/'+cast(isnull(asss.isin,right(Asset_ShortName,12)) as varchar(128)) collate Cyrillic_General_CS_AS)  as varchar(128))  subcontoOUT

		, chk.Subacc_Code Subacc_Code, Asset_ShortName Asset_ShortName, round(isnull(volfree,0),4) volume, InfoSource

	into #t1

	from QORT_BACK_TDB..CheckPositions chk

	left outer join QORT_BACK_DB..Assets asss on asss.ShortName = chk.Asset_ShortName --and asss.IsTrading = 'y'

	where chk.CheckDate = @ytdInt

	and chk.Asset_ShortName not in ('AssetNoQortAMWGMCS10ER5', 'AssetNoQortAMFMVCH01ER1') 

	and chk.Asset_ShortName not like '%NONE-570%' --исключил мусорные бумаги из сверки с Depend

	and chk.Subacc_Code not in ('AS1994') -- исключил позиции по счетам, которые закрыты

	and asss.AssetClass_Const not in(3,4) -- исключил опционы и фьючерсы



	insert into #t1 --(subcontoOUT, Subacc_Code, Asset_ShortName

	select CAST((isnull(chk.subacc_code,'')+'/'+'CLIENT_CDA_Own_ Frozen'+'/'+cast(isnull(asss.isin,Asset_ShortName) as varchar(128)) collate Cyrillic_General_CS_AS)  as varchar(128))  subcontoOUT

		, chk.Subacc_Code Subacc_Code

		, Asset_ShortName Asset_ShortName

		, isnull(chk.volume, 0) volume

		, InfoSource

		--, chk.Account_ExportCode

	from QORT_BACK_TDB..CheckPositions chk

	left outer join QORT_BACK_DB..Assets asss on asss.ShortName = chk.Asset_ShortName --and asss.IsTrading = 'y'

	where chk.CheckDate = @ytdInt and isnull(chk.Volume,0) <> 0 and chk.Asset_ShortName not in ('AssetNoQortAMWGMCS10ER5', 'AssetNoQortAMFMVCH01ER1') and chk.Asset_ShortName not like '%NONE-570%'

	

	select * from #t1  

	order by subcontoOUT 



	select 

	isnull(t.NameClient, IIF(LEFT(t1.subcontoOUT,2) = 'AS', sub.SubaccName, '-')

	

			) NameClient

	, isnull(t.Account, t1.Subacc_Code) Account

	, isnull (t.Settlement,SUBSTRING(t1.subcontoOUT, CHARINDEX('/', t1.subcontoOUT) + 1,
           CHARINDEX('/', t1.subcontoOUT, CHARINDEX('/', t1.subcontoOUT) + 1) - CHARINDEX('/', t1.subcontoOUT) - 1
       )) Settlement

	, isnull(t.ISIN,RIGHT(t1.subcontoOUT,12)) ISIN

	, ISNULL(t.positionQort,0) positionQort

	, isnull(t.DepoAccount,

	

			case LEFT(t1.subcontoOUT,2)

			when '42' then SUBSTRING(t1.subcontoOUT, 1, CHARINDEX('_', t1.subcontoOUT) - 1) collate Cyrillic_General_CS_AS

			when '74' then SUBSTRING(t1.subcontoOUT, 1, CHARINDEX('_', t1.subcontoOUT) - 1) collate Cyrillic_General_CS_AS

			when 'AS' then iif(left(isnull (t.Settlement,SUBSTRING(t1.subcontoOUT, CHARINDEX('/', t1.subcontoOUT) + 1, CHARINDEX('/', t1.subcontoOUT, CHARINDEX('/', t1.subcontoOUT) + 1) - CHARINDEX('/', t1.subcontoOUT) - 1
							)),14) = 'CLIENT_CDA_Own', isnull(
t.DepoAccount,(select top 1 frm.DepoCode from QORT_BACK_DB..FirmDEPOAccs frm where isnull(t.Account, t1.Subacc_Code) = frm.code collate Cyrillic_General_CS_AS)), isnull(t.DepoAccount,(select top 1 DepodivisionCode from QORT_BACK_DB..FirmDEPOAccs where isn
ull(t.Account, t1.Subacc_Code) = trim(code) collate Cyrillic_General_CS_AS))) -- много написано, но это всего лишь IIF

			when 'On' then iif(left(isnull (t.Settlement,SUBSTRING(t1.subcontoOUT, CHARINDEX('/', t1.subcontoOUT) + 1, CHARINDEX('/', t1.subcontoOUT, CHARINDEX('/', t1.subcontoOUT) + 1) - CHARINDEX('/', t1.subcontoOUT) - 1
							)),14) = 'CLIENT_CDA_Own', isnull(
t.DepoAccount,(select top 1 frm.DepoCode from QORT_BACK_DB..FirmDEPOAccs frm where isnull(t.Account, t1.Subacc_Code) = frm.code collate Cyrillic_General_CS_AS)), isnull(t.DepoAccount,(select top 1 DepodivisionCode from QORT_BACK_DB..FirmDEPOAccs where isn
ull(t.Account, t1.Subacc_Code) = trim(code) collate Cyrillic_General_CS_AS))) -- много написано, но это всего лишь IIF
			when 'AB' then iif(left(isnull (t.Settlement,SUBSTRING(t1.subcontoOUT, CHARINDEX('/', t1.subcontoOUT) + 1, CHARINDEX('/', t1.subconto
OUT, CHARINDEX('/', t1.subcontoOUT) + 1) - CHARINDEX('/', t1.subcontoOUT) - 1
							)),14) = 'CLIENT_CDA_Own', '7420000000011', '42000012000070')

			else iif(CHARINDEX('74', t1.Subacc_Code) > 0,SUBSTRING(t1.Subacc_Code, CHARINDEX('74', t1.Subacc_Code), 13)

				,iif(CHARINDEX('42', t1.Subacc_Code) > 0,SUBSTRING(t1.Subacc_Code, CHARINDEX('42', t1.Subacc_Code), 15)

			    ,'-'))

				

			end

			) DepoAccount

	, isnull(t.subcontoQORT, t1.subcontoOUT) subcontoQORT

	, isnull(t1.subcontoOUT,t.subcontoQORT) subcontoOUT

	, isnull(t1.Subacc_Code, t.Account) Subacc_Code

	, isnull(t1.Asset_ShortName, t.ISIN) Asset_ShortName

	, iif(t1.InfoSource = 'DEPEND' and asse.AssetClass_Const in(9,6,7)	and asse.ISIN not in('XS2010028939','XS2010043904', 'XS0114288789') and left(asse.ISIN,2) <> 'AM'

				, isnull(t1.volume, 0)/asse.BaseValueOrigin, isnull(t1.volume, 0)) volume

	, isnull(t1.InfoSource,'-') InfoSource

	,(round(ISNULL(t.positionQort,0),4) - iif(t1.InfoSource = 'DEPEND' and asse.AssetClass_Const in(9,6,7)	and asse.ISIN not in('XS2010028939','XS2010043904','XS0114288789') and left(asse.ISIN,2) <> 'AM'

				, round(isnull(t1.volume, 0)/asse.BaseValueOrigin,4), round(isnull(t1.volume, 0),4))) as Result

	into #t3

	from #t t

	full outer join #t1 t1 on t.subcontoQORT = t1.subcontoOUT

	left outer join QORT_BACK_DB..Assets asse on asse.ShortName = t1.Asset_ShortName --and asse.IsTrading = 'y'

	--left outer join QORT_BACK_DB..FirmDEPOAccs fdep on fdep.Code collate Cyrillic_General_CS_AS = LEFT(t1.subcontoOUT,6) collate Cyrillic_General_CS_AS

	left outer join QORT_BACK_DB..Subaccs sub on sub.SubAccCode collate Cyrillic_General_CS_AS = LEFT(t1.subcontoOUT,6) collate Cyrillic_General_CS_AS

	order by subcontoQORT

	select * from #t3 order by Account 

	--return





	-- блок формирования уведомления--------------------------------------------------------------------------------------------------

			declare @result table (Data int, ClientName varchar(250), Account varchar(128), Settlement varchar(128)

				, Asset_ShortName varchar (128), ISIN varchar (16), positionQort float, DepoAccount varchar(128), positionOUT float, Result float)

    insert into @result (Data, ClientName, Account, Settlement, Asset_ShortName, ISIN, positionQort, DepoAccount, positionOUT, Result)

	select distinct @ytdInt as Data

	 , IIF(t3.NameClient = '-', ISNULL((SELECT DISTINCT NAME_TRANSLATE FROM QORT_ARM_SUPPORT..ClientNameTranslate WHERE ACCOUNT = t3.DepoAccount collate Cyrillic_General_CS_AS), t3.NameClient),t3.NameClient) ClientName

	 , t3.Account Account

	 , t3.Settlement Settlement 

	 , t3.Asset_ShortName Asset_ShortName

	 , t3.ISIN ISIN

	 , t3.positionQort positionQort

	 , t3.DepoAccount DepoAccount

	 , t3.volume positionOUT

	 , round(t3.Result,4) Result

	from #t3 t3

	where t3.Result <> 0 and left(Account, 2) in ('AS', 'Cl', 'cl', 'On') and not (t3.ISIN = 'AMTLCLS10ER3' and left(Account, 2) in ('Cl', 'cl'))

		or (left(Account, 2) in ('AR') and (DepoAccount = '7420000000011' or DepoAccount = '-')  and t3.Result <> 0)

	order by Account

	select * from @result order by Account

	--return

	

	if not exists (select ClientName from @result) return



	if @SendMail = 1 begin

		declare @NotifyMessage varchar(max)

		declare @NotifyTitle varchar(1024) = null

	set @NotifyMessage = cast(

		(

			select '//1\\' + cast(QORT_ARM_SUPPORT.dbo.fIntToDateVarchar (tt.Data) as varchar)

				+ '//2\\' + cast(tt.ClientName as varchar)

				--+ '//4\\' + 'BGColor="'+QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50 - 100 / @MaxDaysPercent, 4) +'"//5\\'+ cast(DaysDelayed as varchar)

				--+ '//2\\' + cast(cast(cast(t.PutPlannedDate as varchar) as date) as varchar) --PlannedDelivery

				--+ '//2\\' + cast(cast(cast(t.TradeDate as varchar) as date) as varchar) --TradeDate

				+ '//2\\' + cast (tt.Account as varchar(32))-- collate Cyrillic_General_CI_AS

				+ '//2\\' + tt.Settlement collate Cyrillic_General_CI_AS 

				+ '//2\\' + tt.Asset_ShortName collate Cyrillic_General_CI_AS 

				+ '//2\\' + tt.ISIN collate Cyrillic_General_CI_AS 

				+ '//2\\' + cast(QORT_ARM_SUPPORT.dbo.fFloatToDecimal13(tt.positionQort) as varchar)

				+ '//2\\' + cast(tt.DepoAccount as varchar)

				+ '//2\\' + cast(QORT_ARM_SUPPORT.dbo.fFloatToDecimal13(tt.positionOUT) as varchar)

				+ '//2\\' + cast(QORT_ARM_SUPPORT.dbo.fFloatToDecimal(tt.Result) as varchar)

				--+ '//2\\' + isnull(fCP.FirmShortName, '') collate Cyrillic_General_CI_AS --CounterParty

				--+ '//2\\' + cast(@ReportDate as varchar) --ReportDate

				--+ '//2\\' + DelayPercent

				--+ '//2\\' + QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50, 4) BGColor

			--	+ '//3\\'

			-- exec QORT_ARM_SUPPORT.dbo.CheckTradeAssetsSanction

			from @result tt

			ORDER BY Account

			for xml path('')

		) as varchar(max))

	--set @fileReport = @FilePath + @fileReport*/

	set @NotifyMessage = replace(@NotifyMessage, '//1\\', '<tr><td>')

		set @NotifyMessage = replace(@NotifyMessage, '//2\\', '</td><td>')

		set @NotifyMessage = replace(@NotifyMessage, '//3\\', '</td></tr>')

		set @NotifyMessage = replace(@NotifyMessage, '//4\\', '</td><td ')

		set @NotifyMessage = replace(@NotifyMessage, '//5\\', '>')



		set @NotifyMessage = 'is an automatically generated message.

		

		

		<br><br><table border="1"><tr BGColor="#CCCCCC"><font color="black"/>'

			+ '<td>Date'

			+ '</td><td>ClientName'

			+ '</td><td>Account'

			+ '</td><td>Settlement'

			+ '</td><td>Asset_ShortName'

			+ '</td><td>ISIN'

			+ '</td><td>PositionQort'

			+ '</td><td>DepoAccount'

			+ '</td><td>PositionCustody'

			+ '</td><td>Result'

			/*+ '</td><td>Volume'

			+ '</td><td>SubaccName'

			+ '</td><td>Operation'

			+ '</td><td>CounterParty'

			+ '</td><td>ReportDate' */

			+ '</tr>' + @NotifyMessage + '</table>'



	set @NotifyTitle = 'Reconciliation of securities balance with the Custodу'

		EXEC msdb.dbo.sp_send_dbmail

			@profile_name = 'qort-sql-mail'

			, @recipients = @NotifyEmail

			, @subject = @NotifyTitle

			, @BODY_FORMAT = 'HTML'

			, @body = @NotifyMessage --*/

			--, @file_attachments = @fileReport



			end -- конец блока отправки сообщения





	







	end try

	begin catch

		while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		select @Message result, 'STATUS' defaultTask, 'red' color

	end catch



END

