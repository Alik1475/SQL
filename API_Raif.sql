

-- exec QORT_ARM_SUPPORT..API_Raif

CREATE PROCEDURE [dbo].[API_Raif]

AS

BEGIN

	-- Проверка и создание временных таблиц

	IF OBJECT_ID('tempdb..#Curloutput_TEST') IS NOT NULL

		DROP TABLE #Curloutput_TEST;



	IF OBJECT_ID('tempdb..#Curloutput') IS NOT NULL

		DROP TABLE #Curloutput;



	IF OBJECT_ID('tempdb..#ParsedResults') IS NOT NULL

		DROP TABLE #ParsedResults;



	IF OBJECT_ID('tempdb..#FactCode') IS NOT NULL

		DROP TABLE #FactCode;



	DECLARE @Message VARCHAR(1024) -- для уведомлений об ошибках

	DECLARE @todayDate DATE = GETDATE()

	DECLARE @todayInt INT = CAST(CONVERT(VARCHAR, @todayDate, 112) AS INT)

	DECLARE @StatementDate NVARCHAR(50) = CONVERT(NVARCHAR, @todayDate, 23);-- Дата в формате yyyy-MM-dd



	CREATE TABLE #Curloutput_TEST (OUTPUT NVARCHAR(MAX));



	CREATE TABLE #ParsedResults (

		ContractorInn NVARCHAR(50)

		,CreditDocument NVARCHAR(255)

		,Debet FLOAT

		,Credit FLOAT

		,DocumentNumber NVARCHAR(50)

		,Account NVARCHAR(50)

		,OrganizationName NVARCHAR(255)

		,Purpose NVARCHAR(255)

		,ValuationDate NVARCHAR(50)

		,ContractorName NVARCHAR(255)

		,OperationDate NVARCHAR(50)

		,OperationType NVARCHAR(50)

		,StatementDate NVARCHAR(50)

		,StatementType NVARCHAR(50)

		,Avisetype NVARCHAR(50)

		,ContractorAccount NVARCHAR(50)

		,ContractorBankName NVARCHAR(255)

		,AccountCurrency NVARCHAR(10)

		,Uip NVARCHAR(50)

		,IntradayOperationId NVARCHAR(50)

		,ErrorMessage NVARCHAR(MAX)

		,DATE INT

		);



	-- Заполнение таблицы #Curloutput данными

	-- EXEC QORT_ARM_SUPPORT..Draft;

	DECLARE @TotalRows INT;

	DECLARE @CurrentRow INT = 1;

	DECLARE @Account NVARCHAR(50);

	DECLARE @CurlCommand NVARCHAR(4000);

	DECLARE @JsonResult NVARCHAR(MAX);

	DECLARE @ErrorMessage NVARCHAR(MAX);

	DECLARE @NotifyMessage VARCHAR(max)

	DECLARE @NotifyMessage1 VARCHAR(max)

	DECLARE @NotifyTitle VARCHAR(1024) = NULL

	DECLARE @NotifyEmail VARCHAR(1024)

	DECLARE @NotifyEmail1 VARCHAR(1024)

	DECLARE @SendMail INT = 1

	DECLARE @SendMail1 INT = 1

	DECLARE @WaitCount INT

	-- Получаем токены 

	DECLARE @IdToken NVARCHAR(MAX);

	DECLARE @AccessToken NVARCHAR(MAX);



	-- Запрос для получения значений

	SELECT TOP 1 @IdToken = [IdToken]

		,@AccessToken = [AccessToken]

	--, @RefreshToken = [RefreshToken]

	FROM [QORT_ARM_SUPPORT].[dbo].[TokenHistory]

	ORDER BY [RetrievedAt] DESC;



	-- Печатаем значения для проверки

	PRINT 'IdToken: ' + ISNULL(@IdToken, 'NULL');

	PRINT 'AccessToken: ' + ISNULL(@AccessToken, 'NULL');



	--PRINT 'RefreshToken: ' + ISNULL(@RefreshToken, 'NULL');

	SELECT FactCode

	INTO #FactCode

	FROM QORT_BACK_DB..Accounts

	WHERE Enabled = 0

		AND DepoFirm_ID = 827 -- Raiffeisen

		AND FactCode <> ''



	-- Получаем общее количество строк

	SELECT @TotalRows = COUNT(*)

	FROM #FactCode;



	-- Цикл для обработки данных по одному аккаунту за раз

	WHILE @CurrentRow <= @TotalRows

	BEGIN

		-- Получаем один аккаунт для обработки

		SELECT @Account = FactCode

		FROM (

			SELECT ROW_NUMBER() OVER (

					ORDER BY (

							SELECT NULL

							)

					) AS RowNum

				,FactCode

			FROM #FactCode

			) AS OrderedData

		WHERE RowNum = @CurrentRow;



		--set @Account = '40807810300000001373'

		-- Подготовка команды curl

		SET @CurlCommand = 'curl --location "https://api.openapi.raiffeisen.ru/api/v1/statement/transactions/intraday?account=' + @Account + '&statementDate=' + @StatementDate + '&fields=ContractorInn,CreditDocument,Debet,Credit,DocumentNumber,Account,Organizat
ionName,Purpose,ValuationDate,ContractorName,OperationDate,OperationType,StatementDate,StatementType,Avisetype,ContractorAccount,ContractorBankName,AccountCurrency,Uip,IntradayOperationId" ' + '--header "Id-Token: ' + @IdToken + '" ' + '--header "Authoriz
ation: Bearer ' + @AccessToken + '" ' + '--header "Accept: application/json" ' + '--output "C:\Temp\api_response.json"';



		PRINT @CurlCommand;--return



		BEGIN TRY

			-- Выполнение команды curl

			INSERT INTO #Curloutput_TEST (OUTPUT)

			EXEC xp_cmdshell @CurlCommand;



			-- Построение команды PowerShell для преобразования кодировки

			DECLARE @InputFilePath NVARCHAR(255) = 'C:\Temp\api_response.json';

			DECLARE @OutputFilePath NVARCHAR(255) = 'C:\Temp\api_response_converted.json';

			DECLARE @PowerShellCommand NVARCHAR(4000);



			-- Команда PowerShell для конвертации файла в кодировку Windows-1251 через .NET

			SET @PowerShellCommand = 'powershell -Command "[System.IO.File]::WriteAllText(''' + @OutputFilePath + ''', [System.IO.File]::ReadAllText(''' + @InputFilePath + '''), [System.Text.Encoding]::GetEncoding(1251))"';



			-- Выполнение команды через xp_cmdshell

			EXEC xp_cmdshell @PowerShellCommand;



			-- Выполнение команды через xp_cmdshell

			DECLARE @Cmd NVARCHAR(4000);



			SET @Cmd = 'cmd.exe /c ' + @PowerShellCommand;



			-- Выполнение команды и вывод результата

			EXEC xp_cmdshell @Cmd;



			DECLARE @JsonContent NVARCHAR(MAX);



			SELECT @JsonContent = BulkColumn

			FROM OPENROWSET(BULK 'C:\Temp\api_response_converted.json', SINGLE_CLOB) AS JsonFile;



			DECLARE @LogFilePath NVARCHAR(255) = 'C:\Temp\api_response_log_' + @StatementDate + '.json';

			DECLARE @Cmdlog NVARCHAR(4000);

			DECLARE @PowerShellCommandlog NVARCHAR(4000);



			SET @PowerShellCommandlog = 'powershell -Command "Add-Content -Path ''' + @LogFilePath + ''' -Value (''Timestamp: '' + (Get-Date).ToString(''yyyy-MM-dd HH:mm:ss'') + ''`n'' + [System.IO.File]::ReadAllText(''C:\Temp\api_response.json'') + ''`n'')"';

			-- Выполнение команды через xp_cmdshell

			SET @Cmdlog = 'cmd.exe /c ' + @PowerShellCommandlog;



			EXEC xp_cmdshell @Cmdlog;



			-- Теперь можно работать с данными

			PRINT @JsonContent;



			-- Очистка результата от всего перед первым символом '['

			SET @JsonContent = SUBSTRING(@JsonContent, CHARINDEX('[', @JsonContent), LEN(@JsonContent));



			-- Проверка правильности JSON и вывод на экран

			PRINT @JsonContent;



			-- Проверка правильности JSON

			IF ISJSON(@JsonContent) = 1

			BEGIN

				PRINT 'JSON is valid';



				-- Вставка распарсенных данных в таблицу #ParsedResults

				INSERT INTO #ParsedResults (

					ContractorInn

					,CreditDocument

					,Debet

					,Credit

					,DocumentNumber

					,Account

					,OrganizationName

					,Purpose

					,ValuationDate

					,ContractorName

					,OperationDate

					,OperationType

					,StatementDate

					,StatementType

					,Avisetype

					,ContractorAccount

					,ContractorBankName

					,AccountCurrency

					,Uip

					,IntradayOperationId

					,ErrorMessage

					,DATE

					)

				SELECT JSON_VALUE(jsonData.value, '$.contractorInn') AS ContractorInn

					,JSON_VALUE(jsonData.value, '$.creditDocument') AS CreditDocument

					,JSON_VALUE(jsonData.value, '$.debet') AS Debet

					,JSON_VALUE(jsonData.value, '$.credit') AS Credit

					,JSON_VALUE(jsonData.value, '$.documentNumber') AS DocumentNumber

					,JSON_VALUE(jsonData.value, '$.account') AS Account

					,CONVERT(NVARCHAR(MAX), JSON_VALUE(jsonData.value, '$.organizationName'), 1) AS OrganizationName

					,JSON_VALUE(jsonData.value, '$.purpose') AS Purpose

					,JSON_VALUE(jsonData.value, '$.valuationDate') AS ValuationDate

					,JSON_VALUE(jsonData.value, '$.contractorName') AS ContractorName

					,JSON_VALUE(jsonData.value, '$.operationDate') AS OperationDate

					,JSON_VALUE(jsonData.value, '$.operationType') AS OperationType

					,JSON_VALUE(jsonData.value, '$.statementDate') AS StatementDate

					,JSON_VALUE(jsonData.value, '$.statementType') AS StatementType

					,JSON_VALUE(jsonData.value, '$.avisetype') AS Avisetype

					,JSON_VALUE(jsonData.value, '$.contractorAccount') AS ContractorAccount

					,JSON_VALUE(jsonData.value, '$.contractorBankName') AS ContractorBankName

					,JSON_VALUE(jsonData.value, '$.accountCurrency') AS AccountCurrency

					,JSON_VALUE(jsonData.value, '$.uip') AS Uip

					,JSON_VALUE(jsonData.value, '$.intradayOperationId') AS IntradayOperationId

					,NULL AS ErrorMessage

					,@todayInt AS DATE

				FROM OPENJSON(@JsonContent) AS jsonData;

			END

			ELSE

			BEGIN

				-- Если JSON некорректен, добавляем запись с сообщением об ошибке

				INSERT INTO #ParsedResults (

					Account

					,ErrorMessage

					)

				VALUES (

					@Account

					,'Некорректный JSON: ' + LEFT(@JsonResult, 1000)

					);

			END;

		END TRY



		BEGIN CATCH

			-- Обработка ошибок

			SET @ErrorMessage = ERROR_MESSAGE();



			INSERT INTO #ParsedResults (

				Account

				,ErrorMessage

				)

			VALUES (

				@Account

				,@ErrorMessage

				);

		END CATCH;



		-- Обновляем текущий ряд для следующей итерации

		SET @CurrentRow = @CurrentRow + 1;



		-- Очищаем временную таблицу перед следующим запросом

		DELETE

		FROM #Curloutput_TEST;

	END;



	-- Выводим результаты парсинга

	SELECT *

	FROM #ParsedResults

	--/*

	DELETE

	FROM #ParsedResults

	WHERE (IntradayOperationId IN (

			SELECT par.IntradayOperationId

			FROM QORT_ARM_SUPPORT.dbo.IntradayOperationId par

			))

			OR

			(LEFT(Purpose,6) = 'Резерв');

--*/

	INSERT INTO QORT_ARM_SUPPORT.dbo.IntradayOperationId (IntradayOperationId)

	SELECT distinct IntradayOperationId

	FROM #ParsedResults par1

	WHERE NOT EXISTS (

			SELECT IntradayOperationId

			FROM QORT_ARM_SUPPORT.dbo.IntradayOperationId

			WHERE par1.IntradayOperationId = IntradayOperationId

			);



	SELECT *

	FROM #ParsedResults -- return



	ALTER TABLE #ParsedResults ADD RowNumber INT;



	-- Заполняем новый столбец порядковым номером строки, отсортированным по BackId

	WITH RowNumberCTE

	AS (

		SELECT IntradayOperationId

			,ROW_NUMBER() OVER (

				ORDER BY IntradayOperationId

				) AS RowNum

		FROM #ParsedResults

		)

	UPDATE pr

	SET pr.RowNumber = cte.RowNum

	FROM #ParsedResults pr

	JOIN RowNumberCTE cte ON pr.IntradayOperationId = cte.IntradayOperationId;



	ALTER TABLE #ParsedResults ADD SubAcc NVARCHAR(255)



	UPDATE #ParsedResults

	SET SubAcc = (

			SELECT CASE 

				WHEN PATINDEX('%AS[0-9]%', Purpose) > 0

						THEN (

								SELECT TOP 1 SubAccCode

								FROM QORT_BACK_DB..Subaccs sub

								WHERE sub.SubAccCode = SUBSTRING(Purpose, PATINDEX('%AS[0-9]%', Purpose), CASE 

											-- Ищем первую нецифру после 'AS' и цифр

											WHEN PATINDEX('%[^0-9]%', SUBSTRING(Purpose, PATINDEX('%AS[0-9]%', Purpose) + 2, LEN(Purpose) - PATINDEX('%AS[0-9]%', Purpose))) > 0

												THEN PATINDEX('%[^0-9]%', SUBSTRING(Purpose, PATINDEX('%AS[0-9]%', Purpose) + 2, LEN(Purpose) - PATINDEX('%AS[0-9]%', Purpose))) + 1

											ELSE LEN(Purpose) - PATINDEX('%AS[0-9]%', Purpose) + 1

											END) COLLATE Cyrillic_General_CI_AS

								)

				

					WHEN PATINDEX('%[А-ЯA-Z][А-ЯA-Z][0-9][0-9][0-9][0-9][0-9][0-9]/[0-9][0-9]%', Purpose) > 0

						THEN (

								SELECT TOP 1 SubAccCode

								FROM QORT_BACK_DB.dbo.ClientAgrees cla

								LEFT OUTER JOIN QORT_BACK_DB..Subaccs sub ON sub.id = cla.SubAcc_ID

								WHERE right(cla.Num,9) = SUBSTRING(Purpose, PATINDEX('%[0-9][0-9][0-9][0-9][0-9][0-9]/[0-9][0-9]%', Purpose), 9) collate Cyrillic_General_CI_AS

								)

					WHEN PATINDEX('%AB[0-9][0-9][0-9][0-9][0-9]%', Purpose) > 0

						THEN (

								SELECT TOP 1 SubAccCode

								FROM QORT_BACK_DB.dbo.ClientAgrees cla

								LEFT OUTER JOIN QORT_BACK_DB..Subaccs sub ON sub.id = cla.SubAcc_ID

								WHERE cla.Num = SUBSTRING(Purpose, PATINDEX('%AB[0-9][0-9][0-9][0-9][0-9]%', Purpose), 7) collate Cyrillic_General_CI_AS

								)

					WHEN PATINDEX('%IC[0-9][0-9][0-9][0-9][0-9][0-9]/[0-9][0-9]%', Purpose) > 0

						THEN (

								SELECT TOP 1 SubAccCode

								FROM QORT_BACK_DB..Subaccs sub

								WHERE sub.ConstitutorCode = SUBSTRING(Purpose, PATINDEX('%IC[0-9][0-9][0-9][0-9][0-9][0-9]/[0-9][0-9]%', Purpose), 11) collate Cyrillic_General_CI_AS

								)

		

					ELSE NULL

					END

			)



	IF OBJECT_ID('tempdb..#tload', 'U') IS NOT NULL

		DROP TABLE #tload;



	SELECT 1 AS IsProcessed

		,2 AS ET_Const

		,6 AS CT_Const

		,REPLACE(CONVERT(VARCHAR, GETDATE(), 108), ':', '') + '000' AS TIME

		,IntradayOperationId AS BackID

		,@todayInt AS RegistrationDate

		,@todayInt AS EventDate

		,@todayInt AS DATE

		,@todayInt AS PlanDate

		,DocumentNumber AS InfoSource

		,'Armbrok_Mn_Client' AS Account_ExportCode

		,SubAcc AS SubAcc_Code

		,iif(AccountCurrency = 'RUR', 'RUB', AccountCurrency) AS Asset

		,Credit AS Size

		,'841103' AS BONum

		,'Account fulfillment' Comment

		,Purpose Comment2

	INTO #tload

	FROM #ParsedResults

	WHERE PATINDEX('%АРМБРОК%', ContractorName) = 0

		AND PATINDEX('%Райффайзенбанк%', ContractorName) = 0

		AND CreditDocument = 'true'

		AND Debet = 0

		AND Credit > 0

		--and OperationType = '0'

		AND SubAcc IS NOT NULL



	SELECT *

	FROM #ParsedResults



	SELECT *

	FROM #tload

	--/*

	INSERT INTO QORT_BACK_TDB.dbo.CorrectPositions (

		IsProcessed

		,ET_Const

		,CT_Const

		,TIME

		,BackID

		,RegistrationDate

		,EventDate

		,DATE

		,PlanDate

		,InfoSource

		,Account_ExportCode

		,Subacc_Code

		,Asset

		,Size

		,BONum

		--, LinkedTrade_TradeNum

		,Comment

		,Comment2

		)

	--, GetSubacc_Code

	--, GetAccount_ExportCode

	--, IsInternal

	--, CPCorrectPos_ID

	--, AddSATFlags

	--*/

	SELECT *

	FROM #tload

	--return

	SET @WaitCount = 1200 -------------------- задержка, не продолжаем пока не подгрузили бумаги----------------------



	WHILE (

			@WaitCount > 0

			AND EXISTS (

				SELECT TOP 1 1

				FROM QORT_BACK_TDB.dbo.CorrectPositions q WITH (NOLOCK)

				WHERE q.IsProcessed IN (

						1

						,2

						)

				)

			)

	BEGIN

		WAITFOR DELAY '00:00:03'



		SET @WaitCount = @WaitCount - 1

	END



	SELECT *

	FROM #ParsedResults



	SET @SendMail = 0



	IF EXISTS (

			SELECT IntradayOperationId

			FROM #ParsedResults

			)

	BEGIN

		SET @SendMail = 1

	END



	IF @SendMail = 1

	BEGIN

		--set	@NotifyEmail = 'accounting@armbrok.am;QORT@armbrok.am;samvel.sahakyan@armbrok.am'

		-- блок формирования уведомления корректировках зачисления денег на счет клиента---

		DECLARE @result TABLE (

			DATE VARCHAR(32)

			,SubAccCode VARCHAR(32)

			,Client_Name VARCHAR(150)

			,Type_Qort VARCHAR(32)

			,Type VARCHAR(256)

			,Size VARCHAR(256)

			,Sales VARCHAR(250)

			,Correct_ID INT

			,/*Comment2  varchar(256),*/ User_Created VARCHAR(32)

			,salesID INT

			,IntradayOperationId VARCHAR(50)

			)



		INSERT INTO @result (

			DATE

			,SubAccCode

			,Client_Name

			,Type_Qort

			,Type

			,Size

			,Sales

			,Correct_ID

			,/*Comment2,*/ User_Created

			,salesID

			,IntradayOperationId

			)

		SELECT QORT_ARM_SUPPORT.dbo.fIntToDateVarchar(corr.DATE) DATE

			,sub.SubAccCode SubAccCode

			,sub.SubaccName Client_Name

			,cast((

					CASE 

						WHEN CT_Const = 6

							THEN 'Cash deposit'

						ELSE ''

						END

					) AS VARCHAR(32)) Type_Qort

			,corr.Comment Type

			,cast(cast(QORT_ARM_SUPPORT.dbo.fFloatToMoney2Varchar(corr.Size) AS VARCHAR(32)) + CAST(ass.Name AS VARCHAR(32)) AS VARCHAR(32)) Size

			,isnull(firS.Name, 'Unknow') Sales

			,corr.id Correct_ID

			--, corr.Comment2 Comment2

			,isnull(cast(users.first_name + users.last_name AS VARCHAR(32)), '') User_Created

			,IIF(sub.SubAccCode IN ('AS1474','AS1529'), 77777 ,IIF(ISNULL(fir.Sales_ID, 1) < 0, 1, ISNULL(fir.Sales_ID, 1))) salesID

			,pars.IntradayOperationId AS IntradayOperationId

		FROM #ParsedResults pars

		LEFT OUTER JOIN QORT_BACK_DB..CorrectPositions corr ON corr.BackID = pars.IntradayOperationId

			AND corr.IsCanceled = 'n'

		LEFT OUTER JOIN QORT_BACK_DB..Subaccs sub ON sub.id = corr.Subacc_ID

		LEFT OUTER JOIN QORT_BACK_DB..Assets ass ON ass.id = corr.Asset_ID

		LEFT OUTER JOIN QORT_BACK_DB..Firms fir ON fir.id = sub.OwnerFirm_ID

		LEFT OUTER JOIN QORT_BACK_DB..Firms firS ON firS.id = fir.Sales_ID

		LEFT OUTER JOIN QORT_BACK_DB..Users users ON users.id = iif(corr.CorrectedUser_ID < 0, 13, corr.CorrectedUser_ID)



		SELECT *

		FROM @result



		SET @SendMail1 = 0



		IF EXISTS (

				SELECT Correct_ID

				FROM @result

				)

		BEGIN

			SET @SendMail1 = 1

		END



		--	if @SendMail = 1 begin

		SELECT DISTINCT ROW_NUMBER() OVER (

				ORDER BY k.SalesID ASC

				) AS Num

			,k.SalesID

		INTO #tk

		FROM (

			SELECT DISTINCT salesID

			FROM @result

			WHERE salesID > 0

			) k



		--select * from #tk 

		DECLARE @n INT = cast((

					SELECT max(num)

					FROM #tk

					) AS INT)

		DECLARE @salesID INT

		DECLARE @salesName VARCHAR(250)



		PRINT @n



		WHILE @n > 0

		BEGIN

			SET @salesID = CAST((

						SELECT salesID

						FROM #tk

						WHERE num = @n

						) AS INT)

			SET @NotifyEmail = 'accounting@armbrok.am;QORT@armbrok.am;samvel.sahakyan@armbrok.am;'



			IF (

					(

						SELECT TOP 1 Correct_ID

						FROM @result

						WHERE salesID = @salesID

						) IS NOT NULL

					)

			BEGIN

				SET @salesName = ISNULL(CAST((

							SELECT name

							FROM QORT_BACK_DB.dbo.Firms

							WHERE id = @salesID

							) AS VARCHAR(250)), 'Tigran Gevorgyan/Elena Voronova')

				SET @NotifyEmail1 = cast(isnull((

								SELECT email

								FROM QORT_BACK_DB.dbo.FirmContacts

								WHERE Contact_ID = @salesID

									AND firm_ID = 2

									AND fct_const = 2

								), 'tigran.gevorgyan@armbrok.am;elena.voronova@armbrok.am') AS VARCHAR(1024)) + ';backoffice@armbrok.am;accounting@armbrok.am;QORT@armbrok.am;'

				SET @NotifyMessage1 = cast((

							SELECT '//1\\' + isnull(tt.DATE, '') + '//2\\' + cast(tt.SubAccCode AS VARCHAR)

								--+ '//4\\' + 'BGColor="'+QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50 - 100 / @MaxDaysPercent, 4) +'"//5\\'+ cast(DaysDelayed as varchar)

								--+ '//2\\' + cast(cast(cast(t.PutPlannedDate as varchar) as date) as varchar) --PlannedDelivery

								--+ '//2\\' + cast(cast(cast(t.TradeDate as varchar) as date) as varchar) --TradeDate

								+ '//2\\' + isnull(tt.Client_Name, '') -- collate Cyrillic_General_CI_AS

								+ '//2\\' + isnull(tt.Type_Qort, '') --collate Cyrillic_General_CI_AS 

								+ '//2\\' + isnull(tt.Type, '') -- collate Cyrillic_General_CI_AS 

								+ '//2\\' + isnull(tt.Size, '') -- collate Cyrillic_General_CI_AS 

								+ '//2\\' + isnull(tt.Sales, '') -- collate Cyrillic_General_CI_AS --PriceCurrency

								+ '//2\\' + cast(isnull(tt.Correct_ID, '') AS VARCHAR(32)) -- collate Cyrillic_General_CI_AS

								--+ '//2\\' + isnull(tt.Comment2, '') --collate Cyrillic_General_CI_AS

								+ '//2\\' + isnull(tt.User_Created, '')

							--+ '//2\\' + isnull(fCP.FirmShortName, '') collate Cyrillic_General_CI_AS --CounterParty

							--+ '//2\\' + cast(@ReportDate as varchar) --ReportDate

							--+ '//2\\' + DelayPercent

							--+ '//2\\' + QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50, 4) BGColor

							--	+ '//3\\'

							-- exec QORT_ARM_SUPPORT.dbo.CheckTradeAssetsSanction

							FROM @result tt

							WHERE salesID = @salesID

							FOR XML path('')

							) AS VARCHAR(max))

				--set @fileReport = @FilePath + @fileReport

				SET @NotifyMessage1 = replace(@NotifyMessage1, '//1\\', '<tr><td>')

				SET @NotifyMessage1 = replace(@NotifyMessage1, '//2\\', '</td><td>')

				SET @NotifyMessage1 = replace(@NotifyMessage1, '//3\\', '</td></tr>')

				SET @NotifyMessage1 = replace(@NotifyMessage1, '//4\\', '</td><td ')

				SET @NotifyMessage1 = replace(@NotifyMessage1, '//5\\', '>')

				SET @NotifyMessage1 = 'Client account in QORT have just been credited with new transactions:

		<br><br><table border="1"><tr BGColor="#CCCCCC"><font color="black"/>' + '<td>Date' + '</td><td>SubAccCode' + '</td><td>ClientName' + '</td><td>Type_Qort' + '</td><td>Description' + '</td><td>Volume' + '</td><td>Sales' + '</td><td>ID_Correction'

					--	+ '</td><td>Comment'

					+ '</td><td>CorrectedUser'

					/*+ '</td><td>Volume'

			+ '</td><td>SubaccName'

			+ '</td><td>Operation'

			+ '</td><td>CounterParty'

			+ '</td><td>ReportDate' */

					+ '</tr>' + @NotifyMessage1 + '</table><br><br><br>'



				PRINT @SALESID

			END

			ELSE

			BEGIN

				SET @NotifyMessage1 = ''

				SET @NotifyEmail1 = ''

			END



			SET @NotifyMessage = cast((

						SELECT '//1\\' + isnull(tt.ContractorInn, '') + '//2\\' + dbo.fFloatToMoney2Varchar(isnull(tt.Debet, 0))

							--+ '//4\\' + 'BGColor="'+QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50 - 100 / @MaxDaysPercent, 4) +'"//5\\'+ cast(DaysDelayed as varchar)

							+ '//2\\' + dbo.fFloatToMoney2Varchar(isnull(tt.Credit, 0)) + '//2\\' + isnull(tt.AccountCurrency, '') + '//2\\' + isnull(tt.ContractorName, '') + '//2\\' + isnull(tt.DocumentNumber, '') -- collate Cyrillic_General_CI_AS

							+ '//2\\' + isnull(tt.Account, '') --collate Cyrillic_General_CI_AS 

							+ '//2\\' + isnull(tt.OrganizationName, '') -- collate Cyrillic_General_CI_AS 

							+ '//2\\' + isnull(tt.Purpose, '') -- collate Cyrillic_General_CI_AS 

							+ '//2\\' + isnull(tt.ValuationDate, '') -- collate Cyrillic_General_CI_AS --PriceCurrency

							+ '//2\\' + isnull(tt.OperationDate, '') -- collate Cyrillic_General_CI_AS

							+ '//2\\' + isnull(tt.OperationType, '') --collate Cyrillic_General_CI_AS

							+ '//2\\' + isnull(tt.StatementDate, '') + '//2\\' + isnull(tt.ContractorAccount, '') + '//2\\' + isnull(tt.ContractorBankName, '')

						--+ '//2\\' + QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50, 4) BGColor

						--	+ '//3\\'

						-- exec QORT_ARM_SUPPORT.dbo.CheckTradeAssetsSanction

						FROM @result rr

						LEFT OUTER JOIN #ParsedResults tt ON tt.IntradayOperationId = rr.IntradayOperationId

						WHERE rr.salesID = @salesID

						FOR XML path('')

						) AS VARCHAR(max))

			--set @fileReport = @FilePath + @fileReport

			SET @NotifyMessage = replace(@NotifyMessage, '//1\\', '<tr><td>')

			SET @NotifyMessage = replace(@NotifyMessage, '//2\\', '</td><td>')

			SET @NotifyMessage = replace(@NotifyMessage, '//3\\', '</td></tr>')

			SET @NotifyMessage = replace(@NotifyMessage, '//4\\', '</td><td ')

			SET @NotifyMessage = replace(@NotifyMessage, '//5\\', '>')

			SET @NotifyMessage = 'Account in RAIFFEISENBANK have just been replenished:

		<br><br><table border="1"><tr BGColor="#CCCCCC"><font color="black"/>' + '<td>ContractorInn' + '</td><td>Debet' + '</td><td>Credit' + '</td><td>AccountCurrency' + '</td><td>ContractorName' + '</td><td>DocumentNumber' + '</td><td>Account' + '</td><td>Org
anizationName' + '</td><td>Purpose' + '</td><td>ValuationDate' + '</td><td>OperationDate' + '</td><td>OperationType' + '</td><td>StatementDate' + '</td><td>ContractorAccount' + '</td><td>ContractorBankName'

				--+ '</td><td>ReportDate' 

				+ '</tr>' + @NotifyMessage + '</table>'

			SET @NotifyMessage = @NotifyMessage1 + @NotifyMessage

			SET @NotifyEmail = @NotifyEmail + @NotifyEmail1

			SET @NotifyTitle = 'Raiffeisen Account Alert: Account Changes Noticed'

			PRINT @NotifyEmail

--/*

			EXEC msdb.dbo.sp_send_dbmail @profile_name = 'qort-sql-mail' --'qort-test-sql'--

				,@recipients = @NotifyEmail

				,@subject = @NotifyTitle

				,@BODY_FORMAT = 'HTML'

				,@body = @NotifyMessage



			--, @file_attachments = @fileReport

			--*/

			SET @n = @n - 1

		END -- конец блока отправки сообщения

	END

END

