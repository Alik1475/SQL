









-- exec QORT_ARM_SUPPORT.dbo.Tariff_For_Anait



CREATE PROCEDURE [dbo].[Tariff_For_Anait]

	

AS



BEGIN
	BEGIN TRY

		DECLARE @todayDate DATE = GETDATE()
		DECLARE @todayInt INT = CAST(CONVERT(VARCHAR, @todayDate, 112) AS INT)
		DECLARE @Message VARCHAR(1024)

		DECLARE @FirmID INT


		SELECT
			fir.BOCode as BOCode,
			fir.Name AS BPName,
		    fir.E
mail as Email ,
			sales.name as Sales, 
			isnull(ClTariff.tariff, '-') as Tariff
		FROM QORT_BACK_DB.dbo.Firms fir WITH (NOLOCK)
		left outer join QORT_BACK_DB.dbo.Firms sales on sales.id = fir.Sales_ID
		OUTER APPLY (SELECT TOP 1 FlagName FROM dbo.FTGe
tIncludedFlags(fir.FT_Flags) WHERE FlagName = 'FT_CLIENT') fClient
		OUTER APPLY (SELECT TOP 1 tar.Name as Tariff
		FROM QORT_BACK_DB.dbo.ClientTariffs ClTariff 
		left outer join QORT_BACK_DB.dbo.Tariffs tar on tar.id = ClTariff.Tariff_ID
		WHERE ClTarif
f.Firm_ID = fir.id 
		and ClTariff.Enabled = 0
		and tar.IsAgent = 'n'
									
		) ClTariff

		WHERE fir.Enabled = 0
		  AND fir.ID NOT IN (2)
		  AND fClient.FlagName = 'FT_CLIENT'
		  and fir.STAT_Const in(5)
		ORDER BY BPName

	END TRY
	BEGIN CATCH
	
	WHILE @@TRANCOUNT > 0 ROLLBACK TRANSACTION
		SET @Message = 'ERROR: ' + ERROR_MESSAGE()
		INSERT INTO QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) VALUES (@Message, 1001)
		PRINT @Message
		SELECT @Message AS Result, 'red' AS ResultColor
	END 
CATCH
END

