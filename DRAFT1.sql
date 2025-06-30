



-- exec QORT_ARM_SUPPORT.dbo.DRAFT1 



CREATE PROCEDURE [dbo].[DRAFT1]

	

AS



BEGIN
	BEGIN TRY

		DECLARE @todayDate DATE = GETDATE()
		DECLARE @todayInt INT = CAST(CONVERT(VARCHAR, @todayDate, 112) AS INT)
		DECLARE @Message VARCHAR(1024)

		DECLARE @FirmID INT


		SELECT
		FIR.BOCode,
			Sub.SubAccCode as SubAccCode,
			firP.Name
U AS BPName,
			iif( fir.IsFirm = 'y', fir.RegistrNum, fir.IDocNum) as DocNum,
			isnull(couTAX.CodeISO_1,'-') as TaxResidentCountry,
			isnull(cou.CodeISO_1,'-') as Country,
			isnull(couR.CodeISO_1,'-') as CountryR


		FROM QORT_BACK_DB.dbo.Subaccs sub 
WITH (NOLOCK)
		left outer join QORT_BACK_DB.dbo.Firms fir on fir.id = iif(sub.SubAccCode = 'Onderka Eduard', 940, sub.OwnerFirm_ID)
		left outer join QORT_BACK_DB.dbo.FirmProperties firP on firP.Firm_ID = fir.id 
		left outer join QORT_BACK_DB.dbo.Countr
ies couTAX on couTAX.ID = firp.TaxResidentCountry_ID 
		left outer join QORT_BACK_DB.dbo.Countries cou on cou.ID = fir.Country_ID 
		left outer join QORT_BACK_DB.dbo.Regions reg on reg.id = fir.AddrJuRegion_ID
		left outer join QORT_BACK_DB.dbo.Countries 
couR on couR.ID = reg.Country_ID 

		OUTER APPLY (SELECT TOP 1 FlagName FROM dbo.FTGetIncludedFlags(fir.FT_Flags) WHERE FlagName = 'FT_CLIENT') fClient
		OUTER APPLY (SELECT TOP 1 tar.Name as Tariff
		FROM QORT_BACK_DB.dbo.ClientTariffs ClTariff 
		left o
uter join QORT_BACK_DB.dbo.Tariffs tar on tar.id = ClTariff.Tariff_ID
		WHERE ClTariff.Firm_ID = fir.id 
		and sub.Enabled = 0
	
									
		) ClTariff

		WHERE sub.Enabled = 0
		and left(sub.SubAccCode,2) not in ('AA', 'AB', 'AR')

		ORDER BY SubAccCode


	END TRY
	BEGIN CATCH
		WHILE @@TRANCOUNT > 0 ROLLBACK TRANSACTION
		SET @Message = 'ERROR: ' + ERROR_MESSAGE()
		INSERT INTO QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) VALUES (@Message, 1001)
		PRINT @Message
		SELECT @Message AS Result, 'r
ed' AS ResultColor
	END CATCH
END

