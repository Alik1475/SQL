
-- exec QORT_ARM_SUPPORT_TEST..TestFlaskRequest_TEST

CREATE PROCEDURE [dbo].[TestFlaskRequest_TEST]

AS

BEGIN

    -- Проверка и создание временных таблиц

    IF OBJECT_ID('tempdb..#Curloutput_TEST') IS NOT NULL DROP TABLE #Curloutput_TEST;

    IF OBJECT_ID('tempdb..#Curloutput') IS NOT NULL DROP TABLE #Curloutput;

    IF OBJECT_ID('tempdb..#ParsedResults') IS NOT NULL DROP TABLE #ParsedResults;

	IF OBJECT_ID('tempdb..#FactCode') IS NOT NULL DROP TABLE #FactCode;

	



    DECLARE @Message VARCHAR(1024) -- для уведомлений об ошибках

    DECLARE @todayDate DATE = GETDATE()

    DECLARE @todayInt INT = CAST(CONVERT(VARCHAR, @todayDate, 112) AS INT)

	DECLARE @StatementDate NVARCHAR(50) = '2024-10-24' --CONVERT(NVARCHAR, @todayDate, 23); -- Дата в формате yyyy-MM-dd

    CREATE TABLE #Curloutput_TEST (output NVARCHAR(MAX));

    CREATE TABLE #ParsedResults (

        ContractorInn NVARCHAR(50),

        CreditDocument NVARCHAR(255),

        Debet FLOAT,

        Credit FLOAT,

        DocumentNumber NVARCHAR(50),

        Account NVARCHAR(50),

        OrganizationName NVARCHAR(255),

        Purpose NVARCHAR(255),

        ValuationDate NVARCHAR(50),

        ContractorName NVARCHAR(255),

        OperationDate NVARCHAR(50),

        OperationType NVARCHAR(50),

        StatementDate NVARCHAR(50),

        StatementType NVARCHAR(50),

        Avisetype NVARCHAR(50),

        ContractorAccount NVARCHAR(50),

        ContractorBankName NVARCHAR(255),

        AccountCurrency NVARCHAR(10),

        Uip NVARCHAR(50),

		IntradayOperationId NVARCHAR(50),

        ErrorMessage NVARCHAR(MAX),

        Date INT

    );



    -- Заполнение таблицы #Curloutput данными

   -- EXEC QORT_ARM_SUPPORT_TEST..Draft;



    DECLARE @TotalRows INT;

    DECLARE @CurrentRow INT = 1;

    DECLARE @Account NVARCHAR(50);

    DECLARE @CurlCommand NVARCHAR(4000);

    DECLARE @JsonResult NVARCHAR(MAX);

    DECLARE @ErrorMessage NVARCHAR(MAX);

  	declare @NotifyMessage varchar(max)

	declare @NotifyMessage1 varchar(max)

	declare @NotifyTitle varchar(1024) = null

	declare @NotifyEmail varchar(1024)

	declare @NotifyEmail1 varchar(1024)

    declare @SendMail int = 1

	declare @SendMail1 int = 1

	DECLARE @WaitCount INT

	-- Получаем токены 

    DECLARE @IdToken NVARCHAR(MAX);

    DECLARE @AccessToken NVARCHAR(MAX);



	-- Запрос для получения значений
		SELECT TOP 1 
			@IdToken = [IdToken],
			@AccessToken = [AccessToken]
			--, @RefreshToken = [RefreshToken]
		FROM [QORT_ARM_SUPPORT_TEST].[dbo].[TokenHistory]
		ORDER BY [RetrievedAt] DESC;

		-- Печатаем значения для
 проверки
		PRINT 'IdToken: ' + ISNULL(@IdToken, 'NULL');
		PRINT 'AccessToken: ' + ISNULL(@AccessToken, 'NULL');
		--PRINT 'RefreshToken: ' + ISNULL(@RefreshToken, 'NULL');



	select FactCode 

	into #FactCode

	from QORT_BACK_DB_UAT..Accounts 

	

	where Enabled = 0

	  AND DepoFirm_ID = 827 -- Raiffeisen

	  and FactCode <> ''







    -- Получаем общее количество строк

    SELECT @TotalRows = COUNT(*) FROM #FactCode;



    -- Цикл для обработки данных по одному аккаунту за раз

   WHILE @CurrentRow <= @TotalRows

   BEGIN

        -- Получаем один аккаунт для обработки

        SELECT @Account = FactCode 

        FROM (

            SELECT ROW_NUMBER() OVER (ORDER BY (SELECT NULL)) AS RowNum, FactCode 

            FROM #FactCode

        ) AS OrderedData

        WHERE RowNum = @CurrentRow;



		--set @Account = '40807810300000001373'



        -- Подготовка команды curl

        SET @CurlCommand = 'curl --location "https://api.openapi.raiffeisen.ru/api/v1/statement/transactions?account=' + @Account + '&statementDate=' + @StatementDate + '&fields=ContractorInn,CreditDocument,Debet,Credit,DocumentNumber,Account,Organization
Name,Purpose,ValuationDate,ContractorName,OperationDate,OperationType,StatementDate,StatementType,Avisetype,ContractorAccount,ContractorBankName,AccountCurrency,Uip" ' +

                           '--header "Id-Token: ' + @IdToken + '" ' +

                        '--header "Authorization: Bearer ' + @AccessToken + '" ' +

                           '--header "Accept: application/json" '

						    + '--output "C:\Temp\api_response.json"';

        







        PRINT @CurlCommand; --return

        BEGIN TRY

            -- Выполнение команды curl

            INSERT INTO #Curloutput_TEST (output)

            EXEC xp_cmdshell @CurlCommand;



				-- Построение команды PowerShell для преобразования кодировки
				DECLARE @InputFilePath NVARCHAR(255) = 'C:\Temp\api_response.json';
				DECLARE @OutputFilePath NVARCHAR(255) = 'C:\Temp\api_response_converted.json';
				DECLARE @PowerShellCommand NVA
RCHAR(4000);

				-- Команда PowerShell для конвертации файла в кодировку Windows-1251 через .NET
				SET @PowerShellCommand = 'powershell -Command "[System.IO.File]::WriteAllText(''' + @OutputFilePath + ''', [System.IO.File]::ReadAllText(''' + @InputFile
Path + '''), [System.Text.Encoding]::GetEncoding(1251))"';

				-- Выполнение команды через xp_cmdshell
				EXEC xp_cmdshell @PowerShellCommand;

				-- Выполнение команды через xp_cmdshell
				DECLARE @Cmd NVARCHAR(4000);
				SET @Cmd = 'cmd.exe /c ' + @
PowerShellCommand;

				-- Выполнение команды и вывод результата
				EXEC xp_cmdshell @Cmd;

						DECLARE @JsonContent NVARCHAR(MAX);
				SELECT @JsonContent = BulkColumn
				FROM OPENROWSET(BULK 'C:\Temp\api_response_converted.json', SINGLE_CLOB) AS JsonFile;

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

                    ContractorInn, CreditDocument, Debet, Credit, DocumentNumber, Account, OrganizationName, 

                    Purpose, ValuationDate, ContractorName, OperationDate, OperationType, StatementDate, 

                    StatementType, Avisetype, ContractorAccount, ContractorBankName, AccountCurrency, Uip, IntradayOperationId,

                    ErrorMessage, Date)

                SELECT 

                    JSON_VALUE(jsonData.value, '$.contractorInn') AS ContractorInn,

                    JSON_VALUE(jsonData.value, '$.creditDocument') AS CreditDocument,

                    JSON_VALUE(jsonData.value, '$.debet') AS Debet,

                    JSON_VALUE(jsonData.value, '$.credit') AS Credit,

                    JSON_VALUE(jsonData.value, '$.documentNumber') AS DocumentNumber,

                    JSON_VALUE(jsonData.value, '$.account') AS Account,

                    CONVERT(NVARCHAR(MAX), JSON_VALUE(jsonData.value, '$.organizationName'), 1) AS OrganizationName,

                    JSON_VALUE(jsonData.value, '$.purpose') AS Purpose,

                    JSON_VALUE(jsonData.value, '$.valuationDate') AS ValuationDate,

                    JSON_VALUE(jsonData.value, '$.contractorName') AS ContractorName,

                    JSON_VALUE(jsonData.value, '$.operationDate') AS OperationDate,

                    JSON_VALUE(jsonData.value, '$.operationType') AS OperationType,

                    JSON_VALUE(jsonData.value, '$.statementDate') AS StatementDate,

                    JSON_VALUE(jsonData.value, '$.statementType') AS StatementType,

                    JSON_VALUE(jsonData.value, '$.avisetype') AS Avisetype,

                    JSON_VALUE(jsonData.value, '$.contractorAccount') AS ContractorAccount,

                    JSON_VALUE(jsonData.value, '$.contractorBankName') AS ContractorBankName,

                    JSON_VALUE(jsonData.value, '$.accountCurrency') AS AccountCurrency,				

                    JSON_VALUE(jsonData.value, '$.uip') AS Uip,

					'12345'+ cast(ABS(CHECKSUM(NEWID())) % 100 + 1 as varchar(16)) + cast(ABS(CHECKSUM(NEWID())) % 100 + 1 as varchar(16)) + cast(ABS(CHECKSUM(NEWID())) % 100 + 1 as varchar(16)) + cast(ABS(CHECKSUM(NEWID())) % 100 + 1 as varchar(16)) /*JSON_VALUE(jsonDa
ta.value, '$.intradayOperationId')*/ AS IntradayOperationId,

                    NULL AS ErrorMessage,

                    @todayInt AS Date

                FROM OPENJSON(@JsonContent) AS jsonData

				--where  JSON_VALUE(jsonData.value, '$.documentNumber') = '393162';

            END

            ELSE

            BEGIN

                -- Если JSON некорректен, добавляем запись с сообщением об ошибке

                INSERT INTO #ParsedResults (Account, ErrorMessage)

                VALUES (@Account, 'Некорректный JSON: ' + LEFT(@JsonResult, 1000));

            END;



        END TRY

        BEGIN CATCH

            -- Обработка ошибок

            SET @ErrorMessage = ERROR_MESSAGE();

            INSERT INTO #ParsedResults (Account, ErrorMessage)

            VALUES (@Account, @ErrorMessage);

        END CATCH;



        -- Обновляем текущий ряд для следующей итерации

       SET @CurrentRow = @CurrentRow + 1;



        -- Очищаем временную таблицу перед следующим запросом

        DELETE FROM #Curloutput_TEST;

    END;



    -- Выводим результаты парсинга

				ALTER TABLE #ParsedResults
			ADD RowNumber INT;

			-- Заполняем новый столбец порядковым номером строки, отсортированным по BackId
			WITH RowNumberCTE AS (
				SELECT 
				IntradayOperationId,
					ROW_NUMBER() OVER (ORDER BY IntradayOperationId) A
S RowNum
				FROM #ParsedResults
			)
			UPDATE pr
			SET pr.RowNumber = cte.RowNum
			FROM #ParsedResults pr
			JOIN RowNumberCTE cte ON pr.IntradayOperationId = cte.IntradayOperationId;



	ALTER TABLE #ParsedResults
	ADD SubAcc NVARCHAR(255)



	 UPDATE #ParsedResults
		SET SubAcc = (SELECT CASE 
                WHEN PATINDEX('%[А-ЯA-Z][А-ЯA-Z][0-9][0-9][0-9][0-9][0-9][0-9]/[0-9][0-9]%', Purpose) > 0 THEN (
				
						select top 1 SubAccCode
						 FROM QORT_BACK_DB_UAT.dbo.ClientAgrees cla
				
		 left outer join QORT_BACK_DB_UAT..Subaccs sub on sub.id = cla.SubAcc_ID
						 where cla.Num = SUBSTRING(Purpose, PATINDEX('%[А-ЯA-Z][А-ЯA-Z][0-9][0-9][0-9][0-9][0-9][0-9]/[0-9][0-9]%', Purpose), 11) collate Cyrillic_General_CI_AS
						 )
            
        
                WHEN PATINDEX('%IC[0-9][0-9][0-9][0-9][0-9][0-9]/[0-9][0-9]%', Purpose) > 0 THEN (

						select top 1 SubAccCode
						FROM QORT_BACK_DB_UAT..Subaccs sub
						where sub.ConstitutorCode  = SUBSTRING(Purpose, PATINDEX('%IC[0-9][0-
9][0-9][0-9][0-9][0-9]/[0-9][0-9]%', Purpose), 11) collate Cyrillic_General_CI_AS
							)

              WHEN PATINDEX('%AS[0-9]%', Purpose) > 0 THEN (
    SELECT TOP 1 SubAccCode
    FROM QORT_BACK_DB_UAT..Subaccs sub
    WHERE sub.SubAccCode = 
       
 SUBSTRING(
            Purpose,
            PATINDEX('%AS[0-9]%', Purpose), 
            CASE 
                -- Ищем первую нецифру после 'AS' и цифр
                WHEN PATINDEX('%[^0-9]%', SUBSTRING(Purpose, PATINDEX('%AS[0-9]%', Purpose) + 2, LEN(P
urpose) - PATINDEX('%AS[0-9]%', Purpose))) > 0
                THEN PATINDEX('%[^0-9]%', SUBSTRING(Purpose, PATINDEX('%AS[0-9]%', Purpose) + 2, LEN(Purpose) - PATINDEX('%AS[0-9]%', Purpose))) + 1
                ELSE LEN(Purpose) - PATINDEX('%AS[0-9]%', P
urpose) + 1
             END
        ) COLLATE Cyrillic_General_CI_AS)



                ELSE
                    NULL
					
              END)

			  IF OBJECT_ID('tempdb..#tload', 'U') IS NOT NULL DROP TABLE #tload;



				      SELECT 1 AS IsProcessed

                     , 2 AS ET_Const

					 , 6 AS CT_Const 

                     , REPLACE(CONVERT(VARCHAR, GETDATE(), 108), ':', '') + '000' AS Time

                     , IntradayOperationId as BackID

                     , @todayInt AS RegistrationDate

                     , @todayInt AS EventDate

					 , @todayInt AS Date

					 , @todayInt AS PlanDate

					 , DocumentNumber as InfoSource

                     , 'Armbrok_Mn_Client' AS Account_ExportCode

                     , SubAcc AS SubAcc_Code

                     , iif(AccountCurrency = 'RUR', 'RUB', AccountCurrency)  as Asset

                     , Credit as Size

					 , '841103'AS BONum

					 , 'Account fulfillment' Comment

					 , Purpose Comment2

				into #tload

                FROM #ParsedResults

				WHERE PATINDEX('%АРМБРОК%', ContractorName) = 0

					and PATINDEX('%Райффайзенбанк%', ContractorName) = 0

					and CreditDocument = 'true'

					and Debet = 0

					and Credit > 0

					--and OperationType = '0'

					and SubAcc is not null





	select * from #ParsedResults

	select *  FROM #tload

	insert into QORT_BACK_TDB_UAT.dbo.CorrectPositions( 

				IsProcessed

					, ET_Const

					, CT_Const

					, Time

					, BackID

					, RegistrationDate

					, EventDate

					, date

					, PlanDate

					, InfoSource

					, Account_ExportCode

					, Subacc_Code

					, Asset

					, Size

					, BONum

					--, LinkedTrade_TradeNum

					, Comment

					, Comment2

					--, GetSubacc_Code

					--, GetAccount_ExportCode

					--, IsInternal

					--, CPCorrectPos_ID

					--, AddSATFlags

					)

		--*/

				select * from #tload

		set @WaitCount = 1200 -------------------- задержка, не продолжаем пока не подгрузили бумаги----------------------

		while (@WaitCount > 0 and exists (select top 1 1 from QORT_BACK_TDB_UAT.dbo.CorrectPositions q with (nolock) where q.IsProcessed in (1,2)))

		begin

			waitfor delay '00:00:03'

			set @WaitCount = @WaitCount - 1

		end

   /* delete

	FROM #ParsedResults

	where EXISTS (

				select IntradayOperationId

				from QORT_ARM_SUPPORT_TEST.dbo.IntradayOperationId par

				where par.IntradayOperationId = IntradayOperationId

			)



INSERT INTO QORT_ARM_SUPPORT_TEST.dbo.IntradayOperationId (IntradayOperationId)

SELECT IntradayOperationId

FROM #ParsedResults par1

	where NOT EXISTS (

				select IntradayOperationId 

				from QORT_ARM_SUPPORT_TEST.dbo.IntradayOperationId 

				where par1.IntradayOperationId = IntradayOperationId

			);

select * from #ParsedResults*/



	/*if exists (select IntradayOperationId FROM #ParsedResults		

			) begin set @SendMail = 1 end*/

	

	if @SendMail = 1 begin

		

	



	



			-- блок формирования уведомления корректировках зачисления денег на счет клиента---

	declare @result table (Date varchar(32), SubAccCode varchar (32), Client_Name varchar (150), Type_Qort varchar(32), Type varchar(256), Size varchar (256), Sales varchar (250)

	, Correct_ID int, /*Comment2  varchar(256),*/ User_Created varchar(32), salesID int, IntradayOperationId varchar(50))

	insert into @result (Date, SubAccCode, Client_Name, Type_Qort, Type, Size, Sales

	, Correct_ID, /*Comment2,*/ User_Created, salesID, IntradayOperationId)

select QORT_ARM_SUPPORT_TEST.dbo.fIntToDateVarchar(corr.Date) Date

		, sub.SubAccCode SubAccCode

		, sub.SubaccName Client_Name

		, cast ((case when CT_Const = 6

				then 'Cash deposit'

				else '' 

				end) 

				as varchar (32)) Type_Qort

		, corr.Comment Type 

		, cast(cast(QORT_ARM_SUPPORT_TEST.dbo.fFloatToMoney2Varchar (corr.Size) as varchar(32))+CAST(ass.Name as varchar(32)) as varchar(32)) Size

		, isnull(firS.Name, 'Unknow') Sales

		, corr.id Correct_ID

		--, corr.Comment2 Comment2

		, isnull(cast(users.first_name+users.last_name as varchar (32)), '') User_Created

		, IIF (ISNULL(fir.Sales_ID, 1) < 0, 1, ISNULL(fir.Sales_ID, 1))  salesID 

		, pars.IntradayOperationId as IntradayOperationId

from #ParsedResults pars

left outer join QORT_BACK_DB_UAT..CorrectPositions corr on corr.BackID = pars.IntradayOperationId

left outer join QORT_BACK_DB_UAT..Subaccs sub on sub.id = corr.Subacc_ID

left outer join QORT_BACK_DB_UAT..Assets ass on ass.id = corr.Asset_ID

left outer join QORT_BACK_DB_UAT..Firms fir on fir.id = sub.OwnerFirm_ID

left outer join QORT_BACK_DB_UAT..Firms firS on firS.id = fir.Sales_ID

left outer join QORT_BACK_DB_UAT..Users users on users.id = iif(corr.CorrectedUser_ID < 0, 13, corr.CorrectedUser_ID)



select * from @result

	

	set @SendMail1 = 0

	if exists (select Correct_ID from @result) begin set @SendMail1 = 1 end



--	if @SendMail = 1 begin

	Select distinct ROW_NUMBER () over (order by k.SalesID asc) as Num, 

	k.SalesID

	 into #tk 

	 from (select distinct salesID from @result where salesID > 0) k

			--select * from #tk 

	declare @n int = cast ((select max (num) from #tk) as int)

	declare @salesID int

	declare @salesName varchar (250)

	print @n



while @n > 0



		begin

		set @salesID = CAST ((select salesID from #tk where num = @n) as int)

		set	@NotifyEmail = 'aleksandr.mironov@armbrok.am;'

	

		if((select top 1 Correct_ID from @result where salesID = @salesID) is not null)

			begin

	

	set @salesName = CAST ((select name from QORT_BACK_DB_UAT.dbo.Firms where id = @salesID) as varchar (250))

	set	@NotifyEmail1 = 'aleksandr.mironov@armbrok.am'

	/*cast (isnull((select email from QORT_BACK_DB_UAT.dbo.FirmContacts 

			where Contact_ID = @salesID and firm_ID = 2 and fct_const = 2),'') as varchar (1024))--+';backoffice@armbrok.am;accounting@armbrok.am;QORT@armbrok.am;'*/

	set @NotifyMessage1 = cast(

		(

			select '//1\\' + isnull(tt.Date, '')

				+ '//2\\' + cast(tt.SubAccCode as varchar)

				--+ '//4\\' + 'BGColor="'+QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50 - 100 / @MaxDaysPercent, 4) +'"//5\\'+ cast(DaysDelayed as varchar)

				--+ '//2\\' + cast(cast(cast(t.PutPlannedDate as varchar) as date) as varchar) --PlannedDelivery

				--+ '//2\\' + cast(cast(cast(t.TradeDate as varchar) as date) as varchar) --TradeDate

				+ '//2\\' + isnull(tt.Client_Name, '')-- collate Cyrillic_General_CI_AS

				+ '//2\\' + isnull(tt.Type_Qort, '') --collate Cyrillic_General_CI_AS 

				+ '//2\\' + isnull(tt.Type, '') -- collate Cyrillic_General_CI_AS 

				+ '//2\\' + isnull(tt.Size, '') -- collate Cyrillic_General_CI_AS 

				+ '//2\\' + isnull(tt.Sales, '') -- collate Cyrillic_General_CI_AS --PriceCurrency

				+ '//2\\' + cast(isnull(tt.Correct_ID, '') as varchar (32)) -- collate Cyrillic_General_CI_AS

				--+ '//2\\' + isnull(tt.Comment2, '') --collate Cyrillic_General_CI_AS

				+ '//2\\' + isnull (tt.User_Created, '') 

				--+ '//2\\' + isnull(fCP.FirmShortName, '') collate Cyrillic_General_CI_AS --CounterParty

				--+ '//2\\' + cast(@ReportDate as varchar) --ReportDate

				--+ '//2\\' + DelayPercent

				--+ '//2\\' + QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50, 4) BGColor

			--	+ '//3\\'

			-- exec QORT_ARM_SUPPORT.dbo.CheckTradeAssetsSanction

			from @result tt

			where salesID = @salesID

			for xml path('')

		) as varchar(max))

	--set @fileReport = @FilePath + @fileReport



	set @NotifyMessage1 = replace(@NotifyMessage1, '//1\\', '<tr><td>')

		set @NotifyMessage1 = replace(@NotifyMessage1, '//2\\', '</td><td>')

		set @NotifyMessage1 = replace(@NotifyMessage1, '//3\\', '</td></tr>')

		set @NotifyMessage1 = replace(@NotifyMessage1, '//4\\', '</td><td ')

		set @NotifyMessage1 = replace(@NotifyMessage1, '//5\\', '>')



		set @NotifyMessage1 = 'Client account in QORT have just been credited with new transactions:

		<br><br><table border="1"><tr BGColor="#CCCCCC"><font color="black"/>'

			+ '<td>Date'

			+ '</td><td>SubAccCode'

			+ '</td><td>ClientName'

			+ '</td><td>Type_Qort'

			+ '</td><td>Description'

			+ '</td><td>Volume'

			+ '</td><td>Sales'

			+ '</td><td>ID_Correction'

		--	+ '</td><td>Comment'

			+ '</td><td>CorrectedUser'

			/*+ '</td><td>Volume'

			+ '</td><td>SubaccName'

			+ '</td><td>Operation'

			+ '</td><td>CounterParty'

			+ '</td><td>ReportDate' */

			+ '</tr>' + @NotifyMessage1  + '</table><br><br><br>'

			

			PRINT @SALESID

			end

			else begin

			set @NotifyMessage1 = ''

			SET @NotifyEmail1 = ''

			

			end





	set @NotifyMessage = cast(

		(

			select '//1\\' + isnull(tt.ContractorInn, '')

				+ '//2\\' + dbo.fFloatToMoney2Varchar(isnull(tt.Debet, 0))

				--+ '//4\\' + 'BGColor="'+QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50 - 100 / @MaxDaysPercent, 4) +'"//5\\'+ cast(DaysDelayed as varchar)

				+ '//2\\' + dbo.fFloatToMoney2Varchar(isnull(tt.Credit, 0)) 

				+ '//2\\' + isnull(tt.AccountCurrency, '') 

				+ '//2\\' + isnull(tt.ContractorName, '') 

				+ '//2\\' + isnull(tt.DocumentNumber, '')-- collate Cyrillic_General_CI_AS

				+ '//2\\' + isnull(tt.Account, '') --collate Cyrillic_General_CI_AS 

				+ '//2\\' + isnull(tt.OrganizationName, '') -- collate Cyrillic_General_CI_AS 

				+ '//2\\' + isnull(tt.Purpose, '') -- collate Cyrillic_General_CI_AS 

				+ '//2\\' + isnull(tt.ValuationDate, '') -- collate Cyrillic_General_CI_AS --PriceCurrency

				+ '//2\\' + isnull(tt.OperationDate, '')  -- collate Cyrillic_General_CI_AS

				+ '//2\\' + isnull(tt.OperationType, '') --collate Cyrillic_General_CI_AS

				+ '//2\\' + isnull (tt.StatementDate, '') 

				+ '//2\\' + isnull(tt.ContractorAccount, '') 

				+ '//2\\' + isnull(tt.ContractorBankName, '') 

				

				--+ '//2\\' + QORT_ARM_SUPPORT.dbo.fColorGradient(DelayPercent, 50, 4) BGColor

			--	+ '//3\\'

			-- exec QORT_ARM_SUPPORT.dbo.CheckTradeAssetsSanction

			FROM @result rr

			left outer join #ParsedResults tt on tt.IntradayOperationId = rr.IntradayOperationId

			where rr.salesID = @salesID



			for xml path('')

		) as varchar(max))

	--set @fileReport = @FilePath + @fileReport



	set @NotifyMessage = replace(@NotifyMessage, '//1\\', '<tr><td>')

		set @NotifyMessage = replace(@NotifyMessage, '//2\\', '</td><td>')

		set @NotifyMessage = replace(@NotifyMessage, '//3\\', '</td></tr>')

		set @NotifyMessage = replace(@NotifyMessage, '//4\\', '</td><td ')

		set @NotifyMessage = replace(@NotifyMessage, '//5\\', '>')



		set @NotifyMessage = 'Account in RAIFFEISENBANK have just been replenished:

		<br><br><table border="1"><tr BGColor="#CCCCCC"><font color="black"/>'

			+ '<td>ContractorInn'

			+ '</td><td>Debet'

			+ '</td><td>Credit'

			+ '</td><td>AccountCurrency'

			+ '</td><td>ContractorName' 

			+ '</td><td>DocumentNumber'

			+ '</td><td>Account'

			+ '</td><td>OrganizationName'

			+ '</td><td>Purpose'

			+ '</td><td>ValuationDate'

			+ '</td><td>OperationDate'

			+ '</td><td>OperationType'

			+ '</td><td>StatementDate'

			+ '</td><td>ContractorAccount'

			+ '</td><td>ContractorBankName'

	

			--+ '</td><td>ReportDate' 

			+ '</tr>' + @NotifyMessage + '</table>' 



			SET @NotifyMessage =  @NotifyMessage1 + @NotifyMessage

			SET @NotifyEmail = @NotifyEmail + @NotifyEmail1

	set @NotifyTitle = 'Raiffeisen Account Alert: Account Changes Noticed'

		EXEC msdb.dbo.sp_send_dbmail

			@profile_name = 'qort-test-sql'--'qort-sql-mail'--

			, @recipients = @NotifyEmail

			, @subject = @NotifyTitle

			, @BODY_FORMAT = 'HTML'

			, @body = @NotifyMessage

			--, @file_attachments = @fileReport

			

	set @n = @n - 1

	

	end -- конец блока отправки сообщения

	

	

	end 

END

