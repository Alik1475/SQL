









-- exec QORT_ARM_SUPPORT.dbo.ReportBondsLida

CREATE PROCEDURE [dbo].[ReportBondsLida]



AS



BEGIN
	BEGIN TRY

		DECLARE @todayDate DATE = GETDATE()
		DECLARE @todayInt INT = CAST(CONVERT(VARCHAR, @todayDate, 112) AS INT)
		DECLARE @Message VARCHAR(1024)



		SELECT
			ass.ISIN as ISIN
			, ass.ShortName as Ticker
			, Firm.BOCode as BOCode
			, 
isnull(Firm.Name, '') as Issuer
			, isnull(FirmP.NameU, '') as Issuer_ARM
			, isnull(FirmP.GenNameU,'') as Issuer_ANSI
			, ass.Country as Country
			, isnull(countR.Name, '') as Country_of_registration_as_a_tax_resident
			, isnull(countR.NameU, '') as
 Country_of_registration_as_a_tax_resident_ARM
			, isnull(countA.Name, '') as EmitCountry
			, isnull(countA.NameU, '') as EmitCountryU
			, dbo.fIntToDateVarchar(ass.created_date) as created_date
			, dbo.fIntToDateVarchar(ass.EmitDate) as Issue_date
		
	, dbo.fIntToDateVarchar(ass.CancelDate) as Maturity_date
			, case 
					when ass.AssetSort_Const in (3,11) then 'Soveregn_Bond'
					when ass.AssetSort_Const = 6 then 'Corporate_Bond'
					when ass.AssetSort_Const = 85 then 'Note'
					when ass.AssetSor
t_Const = 1 then '	Common/Ordinary shares'
					when ass.AssetSort_Const in (2,78) then 'Preferred/Preference shares'
					when ass.AssetSort_Const in (4) then 'Fonds'
					when ass.AssetSort_Const in (32) then 'ADR'
					when ass.AssetSort_Const in (84) 
then 'ETF'
					when ass.AssetSort_Const in (84) then 'Convertible bonds'
					else 'Other' end 
						as Type
			, ass.IsCouponed as IsCouponed
			, AssCur.Name as Currency
			, ass.CouponsPerYear as CouponsPerYear
			, isnull(CAST(Coupon.Procent AS VARC
HAR(8)) + '%', '-') AS CurrentCouponRate 
			, CASE 

				WHEN ass.AssetClass_Const IN (6, 19) THEN 

					CASE ass.TBT_Const

						WHEN 1  THEN 'ACT_360'

						WHEN 2  THEN 'ACT_364'

						WHEN 3  THEN 'ACT_365'

						WHEN 4  THEN 'EURO_30_360'

						WHEN 5  THEN 'NASD_30_360'

						WHEN 6  THEN 'YEAR'

						WHEN 7  THEN 'ACT_366'

						WHEN 8  THEN 'ACT_ACT'

						WHEN 9  THEN 'ACT_ACT_ISMA'

						WHEN 10 THEN 'ACT_N_ACT'

						WHEN 11 THEN 'ISDA_30E_360'

						WHEN 12 THEN 'ISDA_30_360'

						WHEN 13 THEN 'EURO_PLUS_30_360'

						ELSE 'UNKNOWN'

					END

				ELSE '-'

			END AS BasisName
						
			

		FROM QORT_BACK_DB.dbo.Assets ass WITH (NOLOCK)
		LEFT JOIN QORT_BACK_DB.dbo.Firms Firm ON Firm.ID = ass.EmitentFirm_ID
		LEFT JOIN QORT_BACK_DB.dbo.FirmProperties FirmP ON FirmP.Firm_ID = Firm.ID
		LEFT JOIN QORT_BACK_DB.
dbo.Countries countR ON countR.ID = FirmP.TaxResidentCountry_ID
		LEFT JOIN QORT_BACK_DB.dbo.Countries countA ON countA.ID = Firm.Country_ID
		LEFT JOIN QORT_BACK_DB.dbo.Assets AssCur ON AssCur.ID = ass.BaseCurrencyAsset_ID
		outer apply (select top 1 Pro
cent from QORT_BACK_DB.dbo.Coupons 
				where @todayInt >= EndDate 
					AND BeginDate < @todayInt
					and Asset_ID = ass.id
				
				) as Coupon


		WHERE ass.Enabled = 0
		 AND ass.AssetClass_Const IN (5, 6, 11, 16, 18, 19)
		  and ass.IsTrading = 'y'



	END TRY
	BEGIN CATCH
		WHILE @@TRANCOUNT > 0 ROLLBACK TRANSACTION
		SET @Message = 'ERROR: ' + ERROR_MESSAGE()
		INSERT INTO QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) VALUES (@Message, 1001)
		PRINT @Message
		SELECT @Message AS Result, '
red' AS ResultColor
	END CATCH
END

