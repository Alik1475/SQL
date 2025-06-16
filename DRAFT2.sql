









-- exec QORT_ARM_SUPPORT.dbo.DRAFT2

CREATE PROCEDURE [dbo].[DRAFT2]



AS



BEGIN
	BEGIN TRY

		DECLARE @todayDate DATE = GETDATE()
		DECLARE @todayInt INT = CAST(CONVERT(VARCHAR, @todayDate, 112) AS INT)
		DECLARE @Message VARCHAR(1024)



		SELECT
			ass.ISIN as ISIN
			, Firm.BOCode as BOCode
			, isnull(Firm.Name, '') as Emit
Name
			, isnull(FirmP.NameU, '') as EmitNameU
			, isnull(FirmP.GenNameU,'') as EmitNameGen
			, ass.Country as Assets_Country
			, isnull(countR.Name, '') as TaxResidentCountry
			, isnull(countR.NameU, '') as TaxResidentCountryU
			, isnull(countA.Name
, '') as EmitCountry
			, isnull(countA.NameU, '') as EmitCountryU
			, dbo.fIntToDateVarchar(ass.created_date) as created_date
			, dbo.fIntToDateVarchar(ass.EmitDate) as EmitDate
			, dbo.fIntToDateVarchar(ass.CancelDate) as CancelDate
			, case 
					w
hen ass.AssetSort_Const in (3,11) then 'Soveregn_Bond'
					when ass.AssetSort_Const = 6 then 'Corporate_Bond'
					when ass.AssetSort_Const = 85 then 'Note'
					else 'Other_Bond' end 
						as Type
			, ass.IsCouponed as IsCouponed
			, AssCur.Name as C
urrency
			, ass.CouponsPerYear as CouponsPerYear
			, isnull(CAST(Coupon.Procent AS VARCHAR(8)) + '%', '-') AS CurrentCouponRate 

						
			

		FROM QORT_BACK_DB.dbo.Assets ass WITH (NOLOCK)
		LEFT JOIN QORT_BACK_DB.dbo.Firms Firm ON Firm.ID = ass.Emite
ntFirm_ID
		LEFT JOIN QORT_BACK_DB.dbo.FirmProperties FirmP ON FirmP.Firm_ID = Firm.ID
		LEFT JOIN QORT_BACK_DB.dbo.Countries countR ON countR.ID = FirmP.TaxResidentCountry_ID
		LEFT JOIN QORT_BACK_DB.dbo.Countries countA ON countA.ID = Firm.Country_ID
		
LEFT JOIN QORT_BACK_DB.dbo.Assets AssCur ON AssCur.ID = ass.BaseCurrencyAsset_ID
		outer apply (select top 1 Procent from QORT_BACK_DB.dbo.Coupons 
				where @todayInt >= EndDate 
					AND BeginDate < @todayInt
					and Asset_ID = ass.id
				
				) as Cou
pon


		WHERE ass.Enabled = 0
		  AND ass.AssetClass_Const IN (6,19)
		  and ass.IsTrading = 'y'


	END TRY
	BEGIN CATCH
		WHILE @@TRANCOUNT > 0 ROLLBACK TRANSACTION
		SET @Message = 'ERROR: ' + ERROR_MESSAGE()
		INSERT INTO QORT_ARM_SUPPORT.dbo.uploadLog
s(logMessage, errorLevel) VALUES (@Message, 1001)
		PRINT @Message
		SELECT @Message AS Result, 'red' AS ResultColor
	END CATCH
END

