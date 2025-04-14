









-- exec QORT_ARM_SUPPORT.dbo.DRAFT1 @DateFromD = '2023-04-03', @DateToD ='2023-04-03', @BOCode = null '00028'

CREATE PROCEDURE [dbo].[ReportTurnOverAMD]

	  @DateFromD date,

      @DateToD date,

	  @BOCode varchar(32)

AS



BEGIN
	BEGIN TRY

		DECLARE @todayDate DATE = GETDATE()
		DECLARE @todayInt INT = CAST(CONVERT(VARCHAR, @todayDate, 112) AS INT)
		DECLARE @Message VARCHAR(1024)
		DECLARE @DateFrom INT = CAST(CONVERT(VARCHAR, @DateFromD, 112) AS INT)
		DECLARE @DateTo IN
T = CAST(CONVERT(VARCHAR, @DateToD, 112) AS INT)
		DECLARE @FirmID INT

		-- Найти фирму по BOCode
		SELECT TOP 1 @FirmID = ID
		FROM QORT_BACK_DB.dbo.Firms WITH (NOLOCK)
		WHERE BOCode = @BOCode

		-- Защита от ошибки ввода BOCode
		IF (@BOCode IS NOT NU
LL AND @FirmID IS NULL) RETURN

		SELECT
			fir.BOCode as BOCode,
			fir.Name AS BPName,
			ISNULL(QORT_ARM_SUPPORT.dbo.fIntToDateVarchar_dd_MMM_yyyy(cl.DateSign), '-') AS DateSign,
			ISNULL(QORT_ARM_SUPPORT.dbo.fIntToDateVarchar_dd_MMM_yyyy(cl.DateCreat
e), '-') AS DateCreate,
			CASE WHEN sub.SubAccCode IS NULL THEN 'Counterparty' ELSE sub.SubAccCode COLLATE Cyrillic_General_CI_AS END AS SubAccCode,
			CASE 
				WHEN sub.ACSTAT_Const = 1 THEN 'New'
				WHEN sub.ACSTAT_Const = 2 THEN 'Documents for signa
ture/registration'
				WHEN sub.ACSTAT_Const = 3 THEN 'Signed documents'
				WHEN sub.ACSTAT_Const = 4 THEN 'Conditionally active'
				WHEN sub.ACSTAT_Const = 5 THEN 'Active'
				WHEN sub.ACSTAT_Const = 6 THEN 'Blocked'
				WHEN sub.ACSTAT_Const = 7 THEN 
'Terminated'
				WHEN sub.ACSTAT_Const = 8 THEN 'Reserved'
				WHEN sub.ACSTAT_Const = 9 THEN 'On registration'
				WHEN sub.ACSTAT_Const = 10 THEN 'Dormant'
				WHEN sub.ACSTAT_Const = 11 THEN 'Denial'
				WHEN sub.ACSTAT_Const = 12 THEN 'In the process 
of terminating'
				ELSE 'Unknown'
			END AS StatusDescription,
			ISNULL(QORT_ARM_SUPPORT.dbo.fIntToDateVarchar_dd_MMM_yyyy(sub.StatusChangeDate), '-') AS StatusChangeDate,
			fir.IsFirm AS IsLegal_y,
			ISNULL(countR.Name, 'Unfilled') AS Resident,
			IS
NULL(countA.Name, 'Unfilled') AS ResidentDoc,
			ISNULL(org.Name, 'Unfilled') AS Russian_nonrussian,
			IIF(fClient.FlagName IS NULL, 'NO', 'YES') AS IsClient,
			IIF(fPEP.FlagName IS NULL, 'no', 'YES') AS PEP,
			CASE 
				WHEN COALESCE(fh.CRS_Const, fir
.CRS_Const) = 1 THEN 'Financial Institution'
				WHEN COALESCE(fh.CRS_Const, fir.CRS_Const) = 2 THEN 'Active NonFinancial Entity'
				WHEN COALESCE(fh.CRS_Const, fir.CRS_Const) = 3 THEN 'Passive NonFinancial Entity'
				ELSE 'Not chosen'
			END AS CRS_sta
tus,
			CASE 
				WHEN COALESCE(fh.RiskLevel, fir.RiskLevel) = 2 THEN 'Medium'
				WHEN COALESCE(fh.RiskLevel, fir.RiskLevel) = 3 THEN 'Low'
				WHEN COALESCE(fh.RiskLevel, fir.RiskLevel) = 4 THEN 'High'
				WHEN COALESCE(fh.RiskLevel, fir.RiskLevel) = 5 
THEN 'Medium Low'
				WHEN COALESCE(fh.RiskLevel, fir.RiskLevel) = 6 THEN 'Automatic High'
				WHEN COALESCE(fh.RiskLevel, fir.RiskLevel) = 7 THEN 'Extreme'
				WHEN COALESCE(fh.RiskLevel, fir.RiskLevel) = 8 THEN 'Initial'
				ELSE 'N/A'
			END AS RiskLev
el,
			IIF(ISNULL(ass.ISIN, '') = '', isnull(ass.ShortName, '-'), ass.ISIN) AS ISIN,
			ISNULL(t.Turnover_Trade_deliveries, 0) AS Turnover_Trade_deliveries,
			ISNULL(t.Turnover_Trade_payments, 0) AS Turnover_Trade_payments,
			ISNULL(t.Turnover_NONTrade,
 0) AS Turnover_NONTrade,
			ISNULL(t.Total_Client_value, 0) AS Total_Client_value,
			t.Armbrok_Mn_Client,
			t.ARMBR_MONEY_BLOCK,
			t.CLIENT_CDA_Own,
			t.CLIENT_CDA_Own_Frozen,
			t.ARMBR_DEPO_BTA,
			t.ARMBR_DEPO_MAREX,
			t.ARMBR_DEPO,
			t.ARMBR_DE
PO_GTN,
			t.ARMBR_DEPO_MAD,
			t.ARMBR_DEPO_AIX,
			t.ARMBR_DEPO_RON,
			t.ARMBR_DEPO_MTD,
			t.ARMBR_DEPO_HFN,
			t.ARMBR_DEPO_GPP,
			t.ARMBR_DEPO_ALOR_PLUS,
			t.ARMBR_DEPO_RAI,
			t.ARMBR_DEPO_TFI,
			ISNULL(t.OTHER, 0) AS OTHER
		FROM QORT_BACK_DB.d
bo.Firms fir WITH (NOLOCK)
		OUTER APPLY (SELECT TOP 1 fh.RiskLevel, fh.CRS_Const FROM QORT_BACK_DB.dbo.FirmsHist fh WITH (NOLOCK) WHERE fh.Founder_ID = fir.ID AND fh.Founder_Date <= @DateTo ORDER BY fh.Founder_Date DESC) fh
		OUTER APPLY (SELECT TOP 1 Fl
agName FROM dbo.FTGetIncludedFlags(fir.FT_Flags) WHERE FlagName = 'FT_CLIENT') fClient
		OUTER APPLY (SELECT TOP 1 FlagName FROM dbo.FFGetIncludedFlags(fir.FF_Flags) WHERE FlagName = 'FF_PEP') fPEP
		LEFT JOIN QORT_BACK_DB.dbo.FirmProperties FirmP ON Firm
P.Firm_ID = fir.ID
		LEFT JOIN QORT_BACK_DB.dbo.Countries countR ON countR.ID = FirmP.TaxResidentCountry_ID
		LEFT JOIN QORT_BACK_DB.dbo.Countries countA ON countA.ID = fir.Country_ID
		LEFT JOIN QORT_BACK_DB.dbo.OrgCathegories org ON org.ID = fir.OrgCath
egoriy_ID
		CROSS APPLY (SELECT * FROM QORT_ARM_SUPPORT.dbo.fn_Trade_FirmID(fir.ID, @DateFrom, @DateTo)) f
		CROSS APPLY (SELECT * FROM QORT_ARM_SUPPORT.dbo.fn_Turnover_AMD(fir.ID, f.AssetID, @DateFrom, @DateTo)) t
		OUTER APPLY (SELECT TOP 1 sub.SubAccCo
de, sub.OwnerFirm_ID, sub.ACSTAT_Const, sub.StatusChangeDate FROM QORT_BACK_DB.dbo.Subaccs sub WITH (NOLOCK) WHERE sub.ID = t.SubAccID AND sub.Enabled = 0 AND LEFT(ISNULL(sub.SubAccCode, '2'), 2) NOT IN ('AA', 'AB', '00', 'AR') AND ISNULL(sub.OwnerFirm_ID
, 0) NOT IN (3,5)) sub
		OUTER APPLY (SELECT TOP 1 cl.DateSign, cl.DateCreate FROM QORT_BACK_DB.dbo.ClientAgrees cl WITH (NOLOCK) WHERE cl.SubAcc_ID = t.SubAccID AND cl.Enabled = 0 AND cl.ClientAgreeType_ID IN (68,20,22) AND ISNULL(cl.DateSign, 0) <> 0) c
l

		LEFT JOIN QORT_BACK_DB.dbo.Assets ass ON ass.ID = f.AssetID
		WHERE fir.Enabled = 0
		  AND fir.ID NOT IN (2)
		  AND (@FirmID IS NULL OR fir.ID = @FirmID)
		ORDER BY BPName

	END TRY
	BEGIN CATCH
		WHILE @@TRANCOUNT > 0 ROLLBACK TRANSACTION
		SET @M
essage = 'ERROR: ' + ERROR_MESSAGE()
		INSERT INTO QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) VALUES (@Message, 1001)
		PRINT @Message
		SELECT @Message AS Result, 'red' AS ResultColor
	END CATCH
END

