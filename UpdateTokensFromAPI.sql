-- exec QORT_ARM_SUPPORT..UpdateTokensFromAPI




CREATE PROCEDURE [dbo].[UpdateTokensFromAPI]

AS

BEGIN

    SET NOCOUNT ON;



    -- Объявляем переменные

    DECLARE @TokenFilePath NVARCHAR(255) = 'C:\Path\To\TokenFilePath.json';

    DECLARE @TokenHistoryPath NVARCHAR(255) = 'C:\Path\To\TokenHistoryPath.json';

    DECLARE @CurlCommand NVARCHAR(4000);

    DECLARE @JsonResponse NVARCHAR(MAX);

	DECLARE @RefreshToken NVARCHAR(MAX);

    DECLARE @PowerShellCommand NVARCHAR(4000);

	declare @CurrentDate NVARCHAR(10) = CONVERT(NVARCHAR, GETDATE(), 23)

	DECLARE @LogFilePath NVARCHAR(255) = 'C:\Path\To\TokenFilePath_log_' + @CurrentDate + '.json'

	DECLARE @Cmdlog NVARCHAR(4000);
	DECLARE @PowerShellCommandlog NVARCHAR(4000);

	-- Запрос для получения значений
		SELECT TOP 1 
			--@IdToken = [IdToken],
			--@AccessToken = [AccessToken]
			 @RefreshToken = [RefreshToken]
		FROM [QORT_ARM_SUPPORT].[dbo].[TokenHistory]
		ORDER BY [RetrievedAt] DESC;





		print @JsonResponse

    -- Команда curl для получения токенов

    SET @CurlCommand = 'curl --location "https://sso.rbo.raiffeisen.ru/token" ' +

                       '--header "Content-Type: application/x-www-form-urlencoded" ' +

                       '--header "Authorization: Basic MjFlYWIyYjctYWIxYy00ZjhiLWI4ODktYTUwOGVmMGE1YzFmOk5hbGJhbmR5YW5zb25hMTgwNjE5OTIhMjIxMDIwMjQ=" ' +

                       '--data-urlencode "grant_type=refresh_token" ' +

                       '--data-urlencode "client_id=21eab2b7-ab1c-4f8b-b889-a508ef0a5c1f" ' +

                       '--data-urlencode "refresh_token=' + @RefreshToken + '" ' +

                       '--output "' + @TokenFilePath + '"' ;

print @CurlCommand

    -- Выполняем команду curl через xp_cmdshell

   EXEC xp_cmdshell @CurlCommand;



   -- Чтение JSON файла и сохранение в переменную

   SET @JsonResponse = (SELECT BulkColumn 

                        FROM OPENROWSET(BULK 'C:\Path\To\TokenFilePath.json', SINGLE_CLOB) AS JsonFile);


			

			SET @PowerShellCommandlog = 'powershell -Command "Add-Content -Path ''' + @LogFilePath + ''' -Value (''Timestamp: '' + (Get-Date).ToString(''yyyy-MM-dd HH:mm:ss'') + ''`n'' + [System.IO.File]::ReadAllText(''C:\Path\To\TokenFilePath.json'') + ''`n'')"';


			-- Выполнение команды через xp_cmdshell
			SET @Cmdlog = 'cmd.exe /c ' + @PowerShellCommandlog;
			EXEC xp_cmdshell @Cmdlog;

    -- Печатаем JSON для отладки

    PRINT 'Полученный JSON: ' + @JsonResponse;





    -- Извлечение токенов из JSON и запись в таблицу

  

  INSERT INTO QORT_ARM_SUPPORT.dbo.TokenHistory (AccessToken, RefreshToken, IdToken, TokenType, RetrievedAt)

    SELECT 

        JSON_VALUE(@JsonResponse, '$.access_token') AS AccessToken,

        JSON_VALUE(@JsonResponse, '$.refresh_token') AS RefreshToken,

        JSON_VALUE(@JsonResponse, '$.id_token') AS IdToken,

        JSON_VALUE(@JsonResponse, '$.token_type') AS TokenType,

        GETDATE() AS RetrievedAt;

END;

