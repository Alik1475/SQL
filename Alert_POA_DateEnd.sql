

-- exec QORT_ARM_SUPPORT.dbo.Alert_POA_DateEnd

CREATE PROCEDURE [dbo].[Alert_POA_DateEnd] 



AS

BEGIN

	SET NOCOUNT ON;



	BEGIN TRY

		-- Объявление переменных

		DECLARE @todayDate DATE = GETDATE()

		DECLARE @todayInt INT = CAST(CONVERT(VARCHAR, @todayDate, 112) AS INT)

		DECLARE @BdayInt_1 int 

		DECLARE @WaitCount INT = 0

		DECLARE @Message VARCHAR(1024)

		DECLARE @NotifyEmail VARCHAR(max) = 'backoffice@armbrok.am;onboarding@armbrok.am;qort@armbrok.am'-- 'Aleksandr.mironov@armbrok.am'--

		DECLARE @NotifyMessage1 VARCHAR(2000) = '<p><strong>Dear Colleagues,</strong></p>



<p>This is a reminder that the power of attorney for the authorized representative is set to expire <strong> tomorrow (in one business day)</strong>.</p>



<p>We kindly request all departments to:</p>



<ol>

    <li><strong>Review</strong> their processes for any pending operations related to this representative.</li>

    <li><strong>Report</strong> any issues or concerns that could affect the termination of their authority.</li>

    <li><strong>Ensure</strong> that all necessary data is processed and transferred in compliance with internal regulations.</li>

</ol>



<p>If an extension or renewal is required, please initiate the necessary procedures promptly.</p>



<p><strong>Thank you!</strong></p>'



		DECLARE @NotifyMessage VARCHAR(max)

		DECLARE @NotifyTitle VARCHAR(64) 

		--DECLARE @sql VARCHAR(1024)

		DECLARE @n INT = 0



		WHILE @WaitCount < 1

			BEGIN

				SET @n = @n + 1;

				-- Если это рабочий день, увеличиваем счетчик рабочих дней

				IF dbo.fIsBusinessDay(DATEADD(DAY, @n, @todayDate)) = 1

				BEGIN

					SET @WaitCount = @WaitCount + 1;

				END

			END;



	set @BdayInt_1 = CAST(CONVERT(VARCHAR, DATEADD(DAY, @n, @todayDate), 112) AS INT)

	--print @BdayInt_1 return

	CREATE TABLE #TempRoles (

    Description NVARCHAR(100),

    Value INT

);



				INSERT INTO #TempRoles (Description, Value)

				VALUES

					('Agent', 1),

					('Representative', 2),

					('Beneficiary', 3),

					('Beneficial owner', 4),

					('Decisions maker', 5),

					('Ultimate Beneficial Owner', 6),

					('Trustee', 7),

					('Settlor', 8),

					('Protector', 9),

					('Shareholder', 10),

					('Parent', 11),

					('Fund manager', 12),

					('Fund administrator', 13),

					('Secretary', 14),

					('Administrator', 15),

					('Employee', 16),

					('Nominee shareholder', 17),

					('Originator', 18);





		IF OBJECT_ID('tempdb..#tk', 'U') IS NOT NULL

			DROP TABLE #tk



			select fir.Name as Name

				,	fir.BOCode as BOCode 

				, con.FCT as EntityRole

				, ADocTypes.Name as ADocTypes

				, isnull(Afirm.Name, 'Not filled') as Principal_Name

				, isnull(sub.SubAccCodes,'-') as Principal_SubAccCodes

				, QORT_ARM_SUPPORT.dbo.fIntToDateVarchar(ADocs.ADocDate ) as DateSign

				, QORT_ARM_SUPPORT.dbo.fIntToDateVarchar(ADocs.ADocDateEnd ) as DateEnd

				, isnull(Afirm.sales,'-') as sales

			into #tk

			from QORT_BACK_DB.dbo.ADocs ADocs

			left outer join QORT_BACK_DB.dbo.Firms fir on fir.id = ADocs.Firm_ID

			left outer join QORT_BACK_DB.dbo.ADocTypes ADocTypes on ADocTypes.id = ADocs.ADocType_ID

			outer apply (select Afirm.name as Name

									, f.Name as sales

									, Afirm.id as Afirm_id

						from QORT_BACK_DB.dbo.Firms Afirm		

						left outer join QORT_BACK_DB.dbo.Firms f on f.id = Afirm.Sales_ID

						where Afirm.id = ADocs.AFirm_ID	

						) as Afirm

			  OUTER APPLY

        (

            SELECT STRING_AGG(CAST(sub.SubAccCode AS NVARCHAR(32)), ',') AS SubAccCodes

            FROM QORT_BACK_DB.dbo.Subaccs sub

            WHERE sub.OwnerFirm_ID = Afirm.Afirm_id

                  AND sub.Enabled = 0

                --  AND sub.ACSTAT_Const IN ( 5, 7 ) -- Условие для выборки 

        ) as sub

				outer apply (select distinct CPfirm.Name as Name,

												CPfirm.id as CPfirm_id

						from QORT_BACK_DB.dbo.Firms CPfirm					

						where CPfirm.id = ADocs.CpFirm_ID						

						) as CPfirm

		 OUTER APPLY

		        (

            SELECT STRING_AGG(CAST(FCT.Description AS NVARCHAR(32)), ',') AS FCT

            FROM QORT_BACK_DB.dbo.FirmContacts con

			left outer join #TempRoles FCT on FCT.Value = con.FCT_Const

            WHERE  con.IsCancel = 'n' and

                 ((ADocs.Afirm_id < 0 and con.Contact_ID = ADocs.firm_id and con.Firm_ID = ADocs.CpFirm_ID) 

						OR (ADocs.Afirm_id > 0 and con.Contact_ID = ADocs.firm_id and con.Firm_ID = ADocs.Afirm_id))

        ) as con

			where ADocs.ADocDateEnd = @BdayInt_1

			and ADocs.ADocDateEnd > 0

			and con.FCT is not null

		



select * from #tk

--return



	if exists (select BOCode from #tk) begin 

			set @NotifyTitle = 'ALERT: Upcoming Expiry of Power of Attorney'

			--SET @NotifyEmail = 'aleksandr.mironov@armbrok.am'-- для отладки

			SET @NotifyMessage = cast((

						SELECT '//1\\' + isnull(tt.Name, '-') collate Cyrillic_General_CI_AS 

							--+ '//2\\' 

							--+ '//4\\' + 'BGColor="'+QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50 - 100 / @MaxDaysPercent, 4) +'"//5\\'+ cast(DaysDelayed as varchar)

							--+ '//2\\' + cast(isnull(DBO.fIntToDateVarchar(tt.MaxDate), '') AS VARCHAR(50))

							--+ '//2\\' + cast(cast(cast(t.TradeDate as varchar) as date) as varchar) --TradeDate						

							+ '//2\\' + isnull(tt.BOCode, '') collate Cyrillic_General_CI_AS 

							+ '//2\\' + isnull(tt.EntityRole, '') collate Cyrillic_General_CI_AS 

							+ '//2\\' + isnull(tt.ADocTypes, '')  collate Cyrillic_General_CI_AS

							+ '//2\\' + isnull(tt.Principal_Name, '') collate Cyrillic_General_CI_AS

							+ '//2\\' + isnull(tt.Principal_SubAccCodes, '') collate Cyrillic_General_CI_AS

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

				+ '<td>Authorised person' 

				+ '</td><td>Code in BO' 

				+ '</td><td>Entity Roles' 

				+ '</td><td>Type of Authority' 

				+ '</td><td>Principal Name' 

				+ '</td><td>Principal SubAccCodes' 

				+ '</td><td>Effective Date' 

				+ '</td><td>Expiration Date'

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

