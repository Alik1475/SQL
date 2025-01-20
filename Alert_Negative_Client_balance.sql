

-- exec QORT_ARM_SUPPORT.dbo.Alert_Negative_Client_balance @SendMail = 0

CREATE PROCEDURE [dbo].[Alert_Negative_Client_balance] @SelectData BIT = 0

	,@SendMail BIT = 1 -- включена отправка

	,@NotifyEmail VARCHAR(1024) = 'backoffice@armbrok.am;samvel.sahakyan@armbrok.am;lida.tadeosyan@armbrok.am;qort@armbrok.am;'

	,@IsClient BIT = NULL

AS

BEGIN

	BEGIN TRY

		IF nullif(@NotifyEmail, '') IS NULL

			SET @NotifyEmail = 'aleksandr.mironov@armbrok.am' --;qortsupport@armbrok.am;



		DECLARE @Message VARCHAR(max)

		DECLARE @ReportDate DATE = getdate()

		DECLARE @ReportDateInt INT = cast(convert(VARCHAR, @ReportDate, 112) AS INT)

		DECLARE @NotifyMessage VARCHAR(max)

		DECLARE @NotifyTitle VARCHAR(1024) = NULL

		DECLARE @sql VARCHAR(1024)

		DECLARE @date AS INT = cast(convert(VARCHAR, dateadd(DAY, - 8, GETDATE()), 112) AS INT)



		IF OBJECT_ID('tempdb..#t', 'U') IS NOT NULL

			DROP TABLE #t



		SELECT sa.SubAccCode

			,fr.name ClientName

			,pos.VolFree

			,ass.Name

			,acc.name accname

			,crs.Bid * pos.VolFree VolumeUSD

			,isnull(frs.Name, '-') Sales

			,cast(0 AS FLOAT) TotalVolumeUSD

			,'' AS Position

		INTO #t

		FROM QORT_BACK_DB..Position pos

		LEFT OUTER JOIN QORT_BACK_DB..Subaccs sa ON sa.id = pos.SubAcc_ID

		LEFT OUTER JOIN QORT_BACK_DB..Firms fr ON fr.id = sa.OwnerFirm_ID

		LEFT OUTER JOIN QORT_BACK_DB..Firms frs ON frs.id = fr.Sales_ID

		LEFT OUTER JOIN QORT_BACK_DB..Assets ass ON ass.id = pos.Asset_ID

		LEFT OUTER JOIN QORT_BACK_DB..CrossRates crs ON crs.TradeAsset_ID = pos.Asset_ID

			AND InfoSource = 'MainCurBank'

		LEFT OUTER JOIN QORT_BACK_DB..Accounts acc ON acc.id = pos.Account_ID

		WHERE ass.AssetType_Const IN (3) -- 	Cash market

			AND pos.VolFree NOT IN (0)

			AND LEFT(sa.SubAccCode, 2) <> 'AB'

			AND acc.name NOT IN ('ARMBR_MONEY_BLOCK')



		SELECT *

		FROM #t



		SELECT SubAccCode

			,ClientName

			,SUM(VolumeUSD) AS TotalVolumeUSD

			,STRING_AGG(CAST(dbo.fFloatToMoney2Varchar(VolFree) AS VARCHAR(50)) + Name, '; ') AS AllCurrencyPosition

			,Sales Sales

		INTO #t2

		FROM #t

		-- where TotalVolumeUSD < 0

		GROUP BY SubAccCode

			,ClientName

			,Sales;



		SELECT *

		FROM #t2 --return



		SET @NotifyMessage = cast((

					SELECT --'//1\\' + cast(@ReportDate as varchar) --ReportDate

						--+ '//1\\' + isnull(fCP.FirmShortName, '') collate Cyrillic_General_CI_AS --CounterParty

						--+ '//2\\' + iif(tt.IsClient = 0, 'no', 'yes')-- isClientDeal

						+ '//1\\' + tt.ClientName collate Cyrillic_General_CI_AS

						--+ '//1\\' + isnull(tp.ExternalNum,'') collate Cyrillic_General_CI_AS

						--+ '//2\\' + tt.Sales collate Cyrillic_General_CI_AS

						--+ '//2\\' + tt.OrderNum collate Cyrillic_General_CI_AS

						+ '//2\\' + cast(tt.SubAccCode AS VARCHAR)

						--+ '//2\\' + isnull(nullif(cast(t.CpTrade_ID as varchar), '-1'), '')

						--+ '//4\\' + 'BGColor="'+QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50 - 100 / @MaxDaysPercent, 4) +'"//5\\'+ cast(DaysDelayed as varchar)

						--+ '//2\\' + tt.Client collate Cyrillic_General_CI_AS

						+ '//2\\' + cast(dbo.fFloatToMoney2Varchar(tt.TotalVolumeUSD) AS VARCHAR) collate Cyrillic_General_CI_AS

						--+ '//2\\' + tt.Operation collate Cyrillic_General_CI_AS

						--+ '//2\\' + tt.ISIN collate Cyrillic_General_CI_AS

						--+ '//2\\' + tt.Asset collate Cyrillic_General_CI_AS

						+ '//2\\' + cast(tt.AllCurrencyPosition AS VARCHAR) collate Cyrillic_General_CI_AS + '//2\\' + tt.Sales collate Cyrillic_General_CI_AS

						--+ '//2\\' + cast(cast(t.Volume1 as decimal(32,2)) as varchar)

						--+ '//2\\' + tt.PriceCurrency collate Cyrillic_General_CI_AS

						--+ '//2\\' + cast(tt.Volume as varchar) collate Cyrillic_General_CI_AS

						--+ '//2\\' + tt.Counterparty collate Cyrillic_General_CI_AS

						--+ '//2\\' + cast(tt.Trade_ID as varchar)

						--+ '//2\\' + tt.AgreeNum collate Cyrillic_General_CI_AS

						+ '//3\\'

					--, iif(fo.BOCode = '00001', 0, 1) isClientDeal

					--, t.CpTrade_ID

					FROM #t2 tt

					WHERE tt.TotalVolumeUSD < 0

					ORDER BY SubAccCode DESC

					FOR XML path('')

					) AS VARCHAR(max))

		SET @NotifyMessage = replace(@NotifyMessage, '//1\\', '<tr><td>')

		SET @NotifyMessage = replace(@NotifyMessage, '//2\\', '</td><td>')

		SET @NotifyMessage = replace(@NotifyMessage, '//3\\', '</td></tr>')

		SET @NotifyMessage = replace(@NotifyMessage, '//4\\', '</td><td ')

		SET @NotifyMessage = replace(@NotifyMessage, '//5\\', '>')

		-- заголовки HTML-таблицы

		SET @NotifyMessage = 'This is an automatically generated message.</td><td>

		<br><br><table border="1"><tr BGColor="#CCCCCC"><font color="black"/>'

			--+ '<td>Report Date'

			--+ '</td><td>Counter Party'

			--+ '<td>Counter Party'

			--+ '</td><td>Is Client Trade'

			+ '<td>Owner of sub-account'

			--+ '<td>ExternalNum'

			+ '</td><td>Sub-account'

			--	+ '</td><td>OrderNum'

			--	+ '</td><td>ClientCode'

			--	+ '</td><td>Client'

			--	+ '</td><td>TradeDate'

			--	+ '</td><td>Operation'

			--	+ '</td><td>Operation'

			--	+ '</td><td>ISIN'

			--	+ '</td><td>Asset'

			+ '</td><td>Estimate position(USD)' + '</td><td>AllCurrencyPosition' + '</td><td>Sales'

			--	+ '</td><td>Volume'

			--	+ '</td><td>Counterparty'

			--	+ '</td><td>Trade_ID'

			--	+ '</td><td>AgreeNum'

			--	+ '</td><td>Sales'

			+ '</td></tr>' + @NotifyMessage + '</table>'

		--	set @fileReport = @FilePath + @fileReport

		SET @NotifyTitle = 'Alert – Current Negative Balance – Client Positions'



		EXEC msdb.dbo.sp_send_dbmail @profile_name = 'qort-sql-mail' --'qort-test-sql'

			,@recipients = @NotifyEmail

			,@subject = @NotifyTitle

			,@BODY_FORMAT = 'HTML'

			,@body = @NotifyMessage

			--, @file_attachments = @fileReport

	END TRY



	BEGIN CATCH

		WHILE @@TRANCOUNT > 0

			ROLLBACK TRAN



		SET @Message = 'ERROR: ' + ERROR_MESSAGE();



		INSERT INTO QORT_ARM_SUPPORT.dbo.uploadLogs (

			logMessage

			,errorLevel

			)

		VALUES (

			@message

			,1001

			);



		PRINT @Message



		SELECT @Message Result

			,'red' ResultColor

	END CATCH

END

