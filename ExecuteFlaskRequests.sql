CREATE PROCEDURE [dbo].[ExecuteFlaskRequests]
AS
BEGIN
    DECLARE @Object INT;
    DECLARE @ResponseText1 NVARCHAR(MAX);
    DECLARE @ResponseText2 NVARCHAR(MAX);
    DECLARE @URL1 NVARCHAR(500);
    DECLARE @URL2 NVARCHAR(500);
    DECLARE @PostData NVA
RCHAR(MAX);

 --   SET @URL1 = 'http://192.168.13.59:5000/get_data'; -- Первый сервер на порту 5000
    SET @URL2 = 'http://192.168.13.59:5001/get_data'; -- Второй сервер на порту 5001
    SET @PostData = '{ "isin_codes": ["NL0000235190 EQUITY", "XS238770
3866 CORP"] }'; -- Пример данных JSON

 /*   -- Запрос к первому серверу
    EXEC sp_OACreate 'MSXML2.ServerXMLHTTP', @Object OUT;
    EXEC sp_OAMethod @Object, 'open', NULL, 'POST', @URL1, 'false';
    EXEC sp_OAMethod @Object, 'setRequestHeader', NULL, 
'Content-Type', 'application/json';
    EXEC sp_OAMethod @Object, 'send', NULL, @PostData;
    EXEC sp_OAMethod @Object, 'responseText', @ResponseText1 OUTPUT;
    EXEC sp_OADestroy @Object;
	*/
    -- Запрос ко второму серверу
    EXEC sp_OACreate 'MSXML
2.ServerXMLHTTP', @Object OUT;
	PRINT @Object;
    EXEC sp_OAMethod @Object, 'open', NULL, 'POST', @URL2, 'false';
	DECLARE @Status INT;
EXEC sp_OAMethod @Object, 'status', @Status OUTPUT;
PRINT @Status;
    EXEC sp_OAMethod @Object, 'setRequestHeader', N
ULL, 'Content-Type', 'application/json';
	EXEC sp_OAMethod @Object, 'status', @status OUTPUT;

PRINT @status;




    EXEC sp_OAMethod @Object, 'send', NULL, @PostData;
	EXEC sp_OAMethod @Object, 'status', @status OUTPUT;

PRINT @status;


    EXEC sp_OAMethod @Object, 'responseText', @ResponseText2 OUTPUT;
	PRINT @ResponseText2;
	EXEC sp_OAMethod @Object, 'status', @status OUTPUT;

PRINT @status;


    EXEC sp_OADestroy @Object;
	EXEC sp_OAMethod @Object, 'status', @status OUTPUT;

PRINT @status;


	PRINT @ResponseText2;
	EXEC sp_OAMethod @Object, 'status', @Status OUTPUT;
PRINT @Status;
    -- Вывод ответов от обоих серверов
--    SELECT 'Response from Server 1' AS Server, @ResponseText1 AS Response
 --   UNION ALL
    SELECT 'Response from Server
 2', @ResponseText2;

END;
