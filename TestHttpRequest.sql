



create PROCEDURE [dbo].[TestHttpRequest]

AS

BEGIN



    DECLARE @IsinCode NVARCHAR(50) = 'XS1936100483 CORP';

    DECLARE @Url NVARCHAR(MAX) = 'http://192.168.13.59:5001/get_data';

    DECLARE @JsonBody NVARCHAR(MAX);

    DECLARE @ResponseText NVARCHAR(MAX);

    DECLARE @Object INT;



    -- Подготовка JSON-запроса

    SET @JsonBody = '{"isin_codes": ["' + @IsinCode + '"], "fields": ["PX_LAST"]}';



    -- Создание объекта WinHttp.WinHttpRequest

  

    EXEC sp_OACreate 'WinHttp.WinHttpRequest.5.1', @Object OUT;

	EXEC sp_OAMethod @Object, 'SetRequestHeader', NULL, 'Content-Type', 'application/json';

	EXEC sp_OAMethod @Object, 'ResponseText', @ResponseText OUTPUT;

	print @Object --return

    EXEC sp_OAMethod @Object, 'Open', NULL, 'POST', @Url, 'false';

    EXEC sp_OAMethod @Object, 'Send', NULL, @JsonBody;



	print @ResponseText

	print @JsonBody

    -- Проверка правильности JSON и вывод результата

    IF ISJSON(@ResponseText) = 1

    BEGIN

        PRINT 'JSON is valid';

        DECLARE @Px_Last FLOAT;



        -- Извлечение значения PX_LAST

        SET @Px_Last = JSON_VALUE(@ResponseText, '$[0].PX_LAST');



        PRINT 'PX_LAST: ' + CAST(@Px_Last AS NVARCHAR(50));

    END

    ELSE

    BEGIN

        PRINT 'Invalid JSON: ' + @ResponseText;

    END;



    -- Очистка объекта

    EXEC sp_OADestroy @Object;

END;

