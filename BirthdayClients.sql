

-- exec QORT_ARM_SUPPORT.dbo.BirthdayClients

CREATE PROCEDURE [dbo].[BirthdayClients] 

--@SendMail BIT

AS

BEGIN

	SET NOCOUNT ON;



	BEGIN TRY

		-- Объявление переменных

		DECLARE @todayDate DATE = GETDATE()

		DECLARE @todayInt INT = CAST(CONVERT(VARCHAR, @todayDate, 112) AS INT)

		DECLARE @WaitCount INT

		DECLARE @Message VARCHAR(1024)

		DECLARE @NotifyEmail VARCHAR(128) = 'qort@armbrok.am'

		DECLARE @NotifyEmail1 VARCHAR(128)

		DECLARE @NotifyMessage VARCHAR(max)

		DECLARE @NotifyTitle VARCHAR(64) = 'Upcoming Client Birthdays for Sales: '

		DECLARE @sql VARCHAR(1024)

		DECLARE @n INT = 1



		WHILE dbo.fIsBusinessDay(DATEADD(DAY, @n, @todayDate)) = 0

		BEGIN

			SET @n = @n + 1;

		END



		IF OBJECT_ID('tempdb..#tk', 'U') IS NOT NULL

			DROP TABLE #tk



		SELECT DENSE_RANK() OVER (

				ORDER BY Sales_ID

				) AS RowNum

			,NormalDate

			,Sales_ID

			,Name

			,FlagName

			,Email

			,ID

			,SubAccCode

			,StatusDescription

			,MaxDate

			,0 AS Turnover

		INTO #tk

		FROM (

			SELECT CASE 

					WHEN ISDATE(CAST(DateOfBirth AS VARCHAR(12))) = 1

						THEN CONVERT(DATE, CAST(DateOfBirth AS VARCHAR(12)), 112)

					ELSE NULL

					END AS NormalDate

				,Firms.Sales_ID

				,Firms.Name

				,ty.FlagName

				,firms.Email

				,firms.id

				,ss.SubAccCode

				,CASE ss.ACSTAT_Const

					WHEN 1

						THEN 'New'

					WHEN 2

						THEN 'Documents for signature/registration'

					WHEN 3

						THEN 'Signed documents'

					WHEN 4

						THEN 'Conditionally active'

					WHEN 5

						THEN 'Active'

					WHEN 6

						THEN 'Blocked'

					WHEN 7

						THEN 'Terminated'

					WHEN 8

						THEN 'Reserved'

					WHEN 9

						THEN 'On registration'

					WHEN 10

						THEN 'Dormant'

					WHEN 11

						THEN 'Denial'

					WHEN 12

						THEN 'In the process of terminating'

					ELSE 'Unknown Status'

					END AS StatusDescription

				,pp.MaxDate

			FROM QORT_BACK_DB.dbo.Firms

			LEFT OUTER JOIN QORT_BACK_DB.dbo.Subaccs ss ON ss.OwnerFirm_ID = QORT_BACK_DB.dbo.Firms.id

			OUTER APPLY (

				SELECT *

				FROM QORT_ARM_SUPPORT.dbo.FTGetIncludedFlags(Firms.FT_Flags)

				) AS ty

			OUTER APPLY (

				SELECT MAX(PhaseDate) AS MaxPhaseDate

				FROM QORT_BACK_DB.dbo.Phases ph

				WHERE ph.SubAcc_ID = ss.id

				) AS pp1

			OUTER APPLY (

				SELECT MAX(DATE) AS MaxCorrectDate

				FROM QORT_BACK_DB.dbo.CorrectPositions cr

				WHERE cr.SubAcc_ID = ss.id

				) AS pp2

			OUTER APPLY (

				SELECT CASE 

						WHEN pp1.MaxPhaseDate > pp2.MaxCorrectDate

							THEN pp1.MaxPhaseDate

						ELSE pp2.MaxCorrectDate

						END AS MaxDate

				) AS pp

			WHERE Firms.IsFirm = 'n'

				AND Firms.Enabled = 0

			--	and Firms.Sales_ID = 618 -- Victor

				AND ISNULL(ty.FlagName, '') = 'FT_CLIENT'

				AND Firms.STAT_Const NOT IN (

					7

					,11

					,12

					) -- Terminated, Denial, In the process of terminating

			) AS FilteredFirms

		WHERE (

				MONTH(NormalDate) > MONTH(@todayDate)

				OR (

					MONTH(NormalDate) = MONTH(@todayDate)

					AND DAY(NormalDate) > DAY(@todayDate)

					)

				)

			AND (

				MONTH(NormalDate) < MONTH(DATEADD(day, @n, @todayDate))

				OR (

					MONTH(NormalDate) = MONTH(DATEADD(day, @n, @todayDate))

					AND DAY(NormalDate) <= DAY(DATEADD(day, @n, @todayDate))

					)

				);

	--select * from #tk return

		DECLARE @SubAccCode VARCHAR(50);

		DECLARE @OutputParam1 FLOAT;

		DECLARE @OutputParam2 FLOAT;

		DECLARE @ID INT;-- предполагается, что в таблице #tk есть уникальный идентификатор ID для каждой строки



		-- Создаем курсор для выборки SubAccCode и ID из таблицы #tk

		DECLARE cur CURSOR

		FOR

		SELECT SubAccCode

			,ID

		FROM #tk;



		OPEN cur;



		FETCH NEXT

		FROM cur

		INTO @SubAccCode

			,@ID;



		WHILE @@FETCH_STATUS = 0

		BEGIN

			-- Вызываем процедуру для текущего SubAccCode и сохраняем результат в @OutputParam1

			EXEC QORT_ARM_SUPPORT.dbo.ReportTurnOverAMDCompliance @DataFrom = '2022-01-01'

				,@DataTo = @todayDate

				,@SubAccCode = @SubAccCode

				,@OutputParam = @OutputParam1 OUTPUT

				,@OutputParamCL = @OutputParam2 OUTPUT;



			-- Обновляем колонку Turnover для текущего ID

			UPDATE #tk

			SET Turnover = isnull(@OutputParam1,0)

			WHERE ID = @ID;



			-- Переходим к следующей записи

			FETCH NEXT

			FROM cur

			INTO @SubAccCode

				,@ID;

		END



		-- Закрываем и освобождаем курсор

		CLOSE cur;



		DEALLOCATE cur;



		SELECT *

		FROM #tk



		-- return

		SET @n = cast((

					SELECT max(rownum)

					FROM #tk

					) AS INT)



		DECLARE @salesID INT

		DECLARE @salesName VARCHAR(250)



		PRINT @n



		WHILE @n > 0

		BEGIN

			set @NotifyTitle = 'Upcoming Client Birthdays for Sales: '

			SET @salesID = CAST((

						SELECT TOP 1 Sales_ID

						FROM #tk

						WHERE RowNum = @n

						) AS INT)

			SET @salesName = CAST((

						SELECT name

						FROM QORT_BACK_DB.dbo.Firms

						WHERE id = @salesID

						) AS VARCHAR(250))

			SET @NotifyEmail = cast(isnull((

							SELECT email

							FROM QORT_BACK_DB.dbo.FirmContacts

							WHERE Contact_ID = @salesID

								AND firm_ID = 2

								AND fct_const = 2

							), '') AS VARCHAR(1024)) + ';QORT@armbrok.am;'

			--SET @NotifyEmail = 'qort@armbrok.am' -- для отладки

			SET @NotifyMessage = cast((

						SELECT '//1\\' + REPLACE(cast(isnull(FORMAT(tt.NormalDate, 'dd MMM yyyy', 'en-US'), '') AS VARCHAR(50)), ' ', '-')

							--+ '//2\\' 

							--+ '//4\\' + 'BGColor="'+QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50 - 100 / @MaxDaysPercent, 4) +'"//5\\'+ cast(DaysDelayed as varchar)

							--+ '//2\\' + cast(isnull(DBO.fIntToDateVarchar(tt.MaxDate), '') AS VARCHAR(50))

							--+ '//2\\' + cast(cast(cast(t.TradeDate as varchar) as date) as varchar) --TradeDate

							+ '//2\\' + isnull(tt.SubAccCode, '') collate Cyrillic_General_CI_AS 

							+ '//2\\' + isnull(tt.Name, '')  collate Cyrillic_General_CI_AS

							+ '//2\\' + isnull(tt.Email, '')  collate Cyrillic_General_CI_AS 

							+ '//2\\' + isnull(tt.StatusDescription, '')   collate Cyrillic_General_CI_AS 

							+ '//2\\' + REPLACE(cast(dbo.fFloatToCurrency(isnull(tt.Turnover, 0)) AS VARCHAR(32)), ' ', ' ') + 'USD' collate Cyrillic_General_CI_AS

							+ '//2\\' + CASE 
										WHEN ISNULL(tt.MaxDate, '') = '' OR tt.MaxDate = 0 
										THEN '-' 
										ELSE REPLACE(CAST(FORMAT(CONVERT(DATE, CAST(tt.MaxDate AS VARCHAR(50)), 112), 'dd MMM yyyy', 'en-US') AS VARCHAR(50)), ' ', '-')
									
END collate Cyrillic_General_CI_AS 

							+ '//2\\' + isnull(@salesName, '')  collate Cyrillic_General_CI_AS 

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

						WHERE Sales_ID = @salesID

						FOR XML path('')

						) AS VARCHAR(max))

			--set @fileReport = @FilePath + @fileReport

			SET @NotifyMessage = replace(@NotifyMessage, '//1\\', '<tr><td>')

			SET @NotifyMessage = replace(@NotifyMessage, '//2\\', '</td><td>')

			SET @NotifyMessage = replace(@NotifyMessage, '//3\\', '</td></tr>')

			SET @NotifyMessage = replace(@NotifyMessage, '//4\\', '</td><td ')

			SET @NotifyMessage = replace(@NotifyMessage, '//5\\', '>')

			SET @NotifyMessage = '<br><br><table border="1"><tr BGColor="#CCCCCC"><font color="black"/>' 

				+ '<td>Birthday' 

				+ '</td><td>SubAccCode' 

				+ '</td><td>ClientName' 

				+ '</td><td>Email' 

				+ '</td><td>Status'

				+ '</td><td>TurnoverSince2023' 

				+ '</td><td>LastTransactionDate' 

				+ '</td><td>Sales'

				--	+ '</td><td>Comment'

				--+ '</td><td>CorrectedUser'

				/*+ '</td><td>Volume'

			+ '</td><td>SubaccName'

			+ '</td><td>Operation'

			+ '</td><td>CounterParty'

			+ '</td><td>ReportDate' */

				+ '</tr>' + @NotifyMessage + '</table><br><br><br>'



			PRINT @SALESID

			PRINT @NotifyMessage

			PRINT @NotifyEmail

            set @NotifyTitle = @NotifyTitle + @salesName



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

			SET @n = @n - 1

		END

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

