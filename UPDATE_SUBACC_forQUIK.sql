
-- exec QORT_ARM_SUPPORT.dbo.UPDATE_SUBACC_forQUIK

CREATE PROCEDURE [dbo].[UPDATE_SUBACC_forQUIK]
  
AS
BEGIN
    SET NOCOUNT ON;

    BEGIN TRY

        -- Объявление переменных
        
        DECLARE @todayDate DATE = GETDATE()
        DECLARE @toda
yInt INT = CAST(CONVERT(VARCHAR, @todayDate, 112) AS INT)
        declare @Message varchar(1024)
        



		insert into QORT_BACK_TDB.dbo.Subaccs (ET_Const, IsProcessed, Code, IsQUIK, FirmCode, TradeCode, MarketFirmCode)

		SELECT 4 as ET_Const, 1 as IsProcessed

				, sub.SubAccCode as code	

				, isnull(sub1.IsQuik, 'n') as IsQuik

				, iif(sub1.IsQuikC is null, '', 'T0,T2,Tx') as FirmCode

				, iif(sub1.IsQuikC is null, '', sub.SubAccCode) as TradeCode

				, iif(sub1.IsQuikC is null, '', 'ARMBROK') as MarketFirmCode

				--, *



        FROM QORT_BACK_DB.dbo.Subaccs sub

		outer apply (select 'y' as IsQuik, sub1.IsQuik as IsQuikC from QORT_BACK_DB.dbo.Subaccs sub1

						WHERE  sub1.id = sub.id

							and sub.ACSTAT_Const = 5 --Active

						   and sub.Enabled = 0

						   and LEFT(sub.subAccCode,2) in ('AS', 'AR')) as sub1

	
		where sub.Enabled = 0 and sub.IsAnalytic = 'n' 
		and Iif(sub1.IsQuikC is null, 'n', 'y') <> sub.IsQUIK
		--and sub.SubAccCode = 'AS1388'

    END TRY
    BEGIN CATCH
        -- Обработка исключений
        WHILE @@TRANCOUNT > 0 ROLLBACK TRAN
        
SET @Message = 'ERROR: ' + ERROR_MESSAGE(); 
        -- Вставка сообщения об ошибке в таблицу uploadLogs
        INSERT INTO QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) VALUES (@Message, 1001);
        -- Возвращаем сообщение об ошибке
       
 SELECT @Message AS result, 'STATUS' AS defaultTask, 'red' AS color;
    END CATCH

END
