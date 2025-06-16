









-- exec QORT_ARM_SUPPORT.dbo.FirmsFullReport



CREATE PROCEDURE [dbo].[FirmsFullReport]



AS



BEGIN

		DECLARE @todayDate DATE = GETDATE()
		DECLARE @todayInt INT = CAST(CONVERT(VARCHAR, @todayDate, 112) AS INT)
		DECLARE @Message VARCHAR(1024)



		SELECT
			fir.BOCode as BOCode,
			fir.Name AS BPName,
			fir.IsFirm AS IsLegal_y,
			ISNULL(countR
.Name, 'Unfilled') AS Resident,
			ISNULL(countA.Name, 'Unfilled') AS ResidentDoc,
			ISNULL(org.Name, 'Unfilled') AS Russian_nonrussian,
			fRole.FlagNames AS Role,
			CASE 
				WHEN COALESCE(fh.CRS_Const, fir.CRS_Const) = 1 THEN 'Financial Institution'

				WHEN COALESCE(fh.CRS_Const, fir.CRS_Const) = 2 THEN 'Active NonFinancial Entity'
				WHEN COALESCE(fh.CRS_Const, fir.CRS_Const) = 3 THEN 'Passive NonFinancial Entity'
				ELSE 'Not chosen'
			END AS CRS_status,
			CASE 
				WHEN COALESCE(fh.RiskLevel,
 fir.RiskLevel) = 2 THEN 'Medium'
				WHEN COALESCE(fh.RiskLevel, fir.RiskLevel) = 3 THEN 'Low'
				WHEN COALESCE(fh.RiskLevel, fir.RiskLevel) = 4 THEN 'High'
				WHEN COALESCE(fh.RiskLevel, fir.RiskLevel) = 5 THEN 'Medium Low'
				WHEN COALESCE(fh.RiskLe
vel, fir.RiskLevel) = 6 THEN 'Automatic High'
				WHEN COALESCE(fh.RiskLevel, fir.RiskLevel) = 7 THEN 'Extreme'
				WHEN COALESCE(fh.RiskLevel, fir.RiskLevel) = 8 THEN 'Initial'
				ELSE 'N/A'
			END AS RiskLevel
		, *
		
		FROM QORT_BACK_DB.dbo.Firms fir
 WITH (NOLOCK)
		OUTER APPLY (SELECT TOP 1 fh.RiskLevel, fh.CRS_Const FROM QORT_BACK_DB.dbo.FirmsHist fh WITH (NOLOCK) WHERE fh.Founder_ID = fir.ID AND fh.Founder_Date <= @todayInt ORDER BY fh.Founder_Date DESC) fh
		OUTER APPLY (

				SELECT STRING_AGG(FlagName, ', ') AS FlagNames

				FROM dbo.FTGetIncludedFlags(fir.FT_Flags)

			) fRole
		LEFT JOIN QORT_BACK_DB.dbo.FirmProperties FirmP ON FirmP.Firm_ID = fir.ID
		LEFT JOIN QORT_BACK_DB.dbo.Countries countR ON countR.ID = FirmP.TaxResidentCountry_ID
		LEFT JOIN QORT_BACK_DB.dbo.Countries countA ON countA.ID = fir.Country_ID
		L
EFT JOIN QORT_BACK_DB.dbo.OrgCathegories org ON org.ID = fir.OrgCathegoriy_ID
		WHERE fir.Enabled = 0
		  AND fir.ID NOT IN (2)
		ORDER BY BPName

END

