

-- exec QORT_ARM_SUPPORT.dbo.Alert_TerminationDate

CREATE PROCEDURE [dbo].[Alert_TerminationDate] 



AS

BEGIN

	SET NOCOUNT ON;



	BEGIN TRY

		-- Объявление переменных

		DECLARE @todayDate DATE = GETDATE()

		DECLARE @todayInt INT = CAST(CONVERT(VARCHAR, @todayDate, 112) AS INT)

		DECLARE @BdayInt_3 int 

		DECLARE @WaitCount INT = 0

		DECLARE @Message VARCHAR(1024)

		DECLARE @NotifyEmail VARCHAR(max) = 'backoffice@armbrok.am;onboarding@armbrok.am;accounting@armbrok.am;qort@armbrok.am'

		DECLARE @NotifyMessage1 VARCHAR(2000) = '<p><strong>Dear Colleagues,</strong></p>



        <p>This is a reminder that the following client account is scheduled for closure in <strong>three business days</strong>.</p>



        <p>We kindly request that all departments:</p>



        <ol>

            <li><strong>Review</strong> their processes for any pending operations related to this account.</li>

            <li><strong>Report</strong> any issues or concerns that could affect the closure process.</li>

            <li><strong>Ensure</strong> all client data is processed and transferred in compliance with internal regulations.</li>

        </ol>



        <p><strong>Thank you!</strong></p>

'

		DECLARE @NotifyMessage VARCHAR(max)

		DECLARE @NotifyTitle VARCHAR(64) 

		--DECLARE @sql VARCHAR(1024)

		DECLARE @n INT = 0



		WHILE @WaitCount < 3

			BEGIN

				SET @n = @n + 1;

				-- Если это рабочий день, увеличиваем счетчик рабочих дней

				IF dbo.fIsBusinessDay(DATEADD(DAY, @n, @todayDate)) = 1

				BEGIN

					SET @WaitCount = @WaitCount + 1;

				END

			END;



	set @BdayInt_3 = CAST(CONVERT(VARCHAR, DATEADD(DAY, @n, @todayDate), 112) AS INT)



		IF OBJECT_ID('tempdb..#tk', 'U') IS NOT NULL

			DROP TABLE #tk



			select fir.Name as Name

				,	fir.BOCode as BOCode 

				, sub.SubAccCode as SubAccCode

				, QORT_ARM_SUPPORT.dbo.fIntToDateVarchar(Cla.DateSign) as DateSign

				, QORT_ARM_SUPPORT.dbo.fIntToDateVarchar(Cla.DateEnd) as DateEnd

				, fir.sales as sales

			into #tk

			from QORT_BACK_DB.dbo.ClientAgrees Cla

			outer apply (select sub.SubAccCode as SubAccCode 

								, sub.ACSTAT_Const as ACSTAT_Const

						from QORT_BACK_DB.dbo.Subaccs sub 					

						where sub.id = Cla.SubAcc_ID	

						) as sub

			outer apply (select distinct fir.Name as Name

								, fir.BOCode as BOCode

								, f.Name as sales				

						from QORT_BACK_DB.dbo.Firms fir

						left outer join QORT_BACK_DB.dbo.Firms f on f.id = fir.Sales_ID

						where fir.id = Cla.OwnerFirm_ID						

						) as fir

			

			where Cla.DateEnd = @BdayInt_3

			and Cla.DateEnd > 0

			and sub.ACSTAT_Const not in(7) -- 7(Terminated)

			and cla.enabled = 0



select * from #tk

--return

if exists (select BOCode from #tk) begin 

			set @NotifyTitle = 'ALERT: Scheduled Account Termination'

			--SET @NotifyEmail = 'aleksandr.mironov@armbrok.am'-- для отладки

			SET @NotifyMessage = cast((

						SELECT '//1\\' + isnull(tt.Name, '-') collate Cyrillic_General_CI_AS 

							--+ '//2\\' 

							--+ '//4\\' + 'BGColor="'+QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50 - 100 / @MaxDaysPercent, 4) +'"//5\\'+ cast(DaysDelayed as varchar)

							--+ '//2\\' + cast(isnull(DBO.fIntToDateVarchar(tt.MaxDate), '') AS VARCHAR(50))

							--+ '//2\\' + cast(cast(cast(t.TradeDate as varchar) as date) as varchar) --TradeDate

							+ '//2\\' + isnull(tt.BOCode, '') collate Cyrillic_General_CI_AS 

							+ '//2\\' + isnull(tt.SubAccCode, '')  collate Cyrillic_General_CI_AS

							+ '//2\\' + isnull(tt.DateSign, '')  collate Cyrillic_General_CI_AS 

							+ '//2\\' + isnull(tt.DateEnd, '')   collate Cyrillic_General_CI_AS 

							--+ '//2\\' + REPLACE(cast(dbo.fFloatToCurrency(isnull(tt.Turnover, 0)) AS VARCHAR(32)), ' ', ' ') + 'USD' collate Cyrillic_General_CI_AS

							+ '//2\\' + isnull(tt.sales, '')  collate Cyrillic_General_CI_AS 

							--+ '//2\\' + cast(isnull(tt.Correct_ID, '') AS VARCHAR(32)) -- collate Cyrillic_General_CI_AS

							--+ '//2\\' + isnull(tt.Comment2, '') --collate Cyrillic_General_CI_AS

							--+ '//2\\' + isnull(tt.User_Created, '')

							--+ '//2\\' + isnull(fCP.FirmShortName, '') collate Cyrillic_General_CI_AS --CounterParty

							--+ '//2\\' + cast(@ReportDate as varchar) --ReportDate

							--+ '//2\\' + DelayPercent

							--+ '//2\\' + QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50, 4) BGColor

							--	+ '//3\\'

							-- exec QORT_ARM_SUPPORT.dbo.CheckTradeAssetsSanction

						FROM #tk tt

						FOR XML path('')

						) AS VARCHAR(max))

			--set @fileReport = @FilePath + @fileReport

			SET @NotifyMessage = replace(@NotifyMessage, '//1\\', '<tr><td>')

			SET @NotifyMessage = replace(@NotifyMessage, '//2\\', '</td><td>')

			SET @NotifyMessage = replace(@NotifyMessage, '//3\\', '</td></tr>')

			SET @NotifyMessage = replace(@NotifyMessage, '//4\\', '</td><td ')

			SET @NotifyMessage = replace(@NotifyMessage, '//5\\', '>')

			SET @NotifyMessage = '<br><br><table border="1"><tr BGColor="#CCCCCC"><font color="black"/>' 

				+ '<td>Name' 

				+ '</td><td>Code in BO' 

				+ '</td><td>Sub-account' 

				+ '</td><td>Status assigned date' 

				+ '</td><td>Termination date'

				+ '</td><td>Sales-manager' 

				--+ '</td><td>LastTransactionDate' 

				--+ '</td><td>Sales'

				--	+ '</td><td>Comment'

				--+ '</td><td>CorrectedUser'

				/*+ '</td><td>Volume'

			+ '</td><td>SubaccName'

			+ '</td><td>Operation'

			+ '</td><td>CounterParty'

			+ '</td><td>ReportDate' */

				+ '</tr>' + @NotifyMessage + '</table><br><br><br>'





			set @NotifyMessage = @NotifyMessage1 + @NotifyMessage

			PRINT @NotifyEmail

          



			--/*

		  -- Отправка email

            EXEC msdb.dbo.sp_send_dbmail

                @profile_name = 'qort-sql-mail',--'qort-test-sql'

                @recipients = @NotifyEmail,

                @subject = @NotifyTitle,

                @BODY_FORMAT = 'HTML',

                @body = @NotifyMessage

                --@file_attachments = @fileReport;

				--*/

		end

	END TRY



	BEGIN CATCH

		-- Обработка исключений

		WHILE @@TRANCOUNT > 0

			ROLLBACK TRAN



		SET @Message = 'ERROR: ' + ERROR_MESSAGE();



		-- Вставка сообщения об ошибке в таблицу uploadLogs

		INSERT INTO QORT_ARM_SUPPORT.dbo.uploadLogs (

			logMessage

			,errorLevel

			)

		VALUES (

			@Message

			,1001

			);



		-- Возвращаем сообщение об ошибке

		SELECT @Message AS result

			,'STATUS' AS defaultTask

			,'red' AS color;

	END CATCH

END

