



-- exec QORT_ARM_SUPPORT.dbo.Clients_Statics_CBA



CREATE PROCEDURE [dbo].[Clients_Statics_CBA]

	

AS



BEGIN
	BEGIN TRY

		DECLARE @todayDate DATE = GETDATE()
		DECLARE @todayInt INT = CAST(CONVERT(VARCHAR, @todayDate, 112) AS INT)
		DECLARE @Message VARCHAR(1024)
		DECLARE @DateTo INT = 20231231
		DECLARE @FirmID INT


		SELECT
		FIR.BOCode,
			Sub.SubAcc
Code as SubAccCode_A,
			firP.NameU AS BPName_B,
			iif( fir.IsFirm = 'y', fir.RegistrName, fir.IDocNum) as DocNum_C,
			'' as TypeBP_D,
			isnull(couTAX.CodeISO_1,'-') as TaxResidentCountry_E,
			isnull(cou.CodeISO_1,'-') as Country_F,
			'' as CountryD_
G,
			CASE 
				WHEN COALESCE(fh.RiskLevel, fir.RiskLevel) = 2 THEN 'Medium'
				WHEN COALESCE(fh.RiskLevel, fir.RiskLevel) = 3 THEN 'Low'
				WHEN COALESCE(fh.RiskLevel, fir.RiskLevel) = 4 THEN 'High'
				WHEN COALESCE(fh.RiskLevel, fir.RiskLevel) = 5 TH
EN 'Medium Low'
				WHEN COALESCE(fh.RiskLevel, fir.RiskLevel) = 6 THEN 'Automatic High'
				WHEN COALESCE(fh.RiskLevel, fir.RiskLevel) = 7 THEN 'Extreme'
				WHEN COALESCE(fh.RiskLevel, fir.RiskLevel) = 8 THEN 'Initial'
				ELSE 'N/A'
			END 
		--	+ '  '
 + CONVERT(VARCHAR(10), CAST(CONVERT(CHAR(8), @DateTo) AS DATE), 104) 
			AS RiskLevel_H,
			
			isnull(Catheg.Name, '-') as ClientCathegory_I,
			case when ClAgrees.DateSign IS null then 'No_Agree'
				when ClAgrees.DateSign = 0 then 'No_Date'
				else d
bo.fIntToDateVarchar_dd_MMM_yyyy(ClAgrees.DateSign) 
				end
																as DateSign_J,

		case 

				when ClAgrees.DateEnd IS null then 'No_Agree'

				when ClAgrees.DateEnd = 0 and sub.ACSTAT_Const = 7 then 

					cast('No_Date(Terminated ' + dbo.fIntToDateVarchar_dd_MMM_yyyy(sub.StatusChangeDate) + ')' as varchar(100))

				else dbo.fIntToDateVarchar_dd_MMM_yyyy(ClAgrees.DateEnd) 

			end as DateEnd_K,		
			--2023
			iif(Mon_Out.RegistrationDate < 20240101, dbo.fFloatToMoney2Varchar(Mon_Out.vol) + 'AMD', '') as MON_OUT_L,
			'' as MON_OUT_M,
			iif(Mon_IN.RegistrationDate < 20240101, dbo.fFloatToMoney2Varchar(Mon_IN.vol) + 'AMD', ''
) as MON_IN_N,
			'' as MON_IN_O,
			iif(Sec_Out.RegistrationDate < 20240101, dbo.fFloatToMoney2Varchar(Sec_Out.vol) + 'AMD', '') as Sec_Out_P,
			iif(Sec_Out.RegistrationDate < 20240101 and sec_out.Country <> 'Armenia' , dbo.fFloatToMoney2Varchar(Sec_Out
.vol) + 'AMD', '') as Sec_Out_Q,
			iif(Sec_IN.RegistrationDate < 20240101, dbo.fFloatToMoney2Varchar(Sec_In.vol) + 'AMD', '') as Sec_IN_R,
			iif(Sec_IN.RegistrationDate < 20240101 and sec_in.Country <> 'Armenia', dbo.fFloatToMoney2Varchar(Sec_In.vol) + 
'AMD', '') as Sec_In_S,
			--2024
			iif(Mon_Out.RegistrationDate >= 20240101 and Mon_Out.RegistrationDate < 20250101, dbo.fFloatToMoney2Varchar(Mon_Out.vol) + 'AMD', '') as MON_OUT_T,
			'' as MON_OUT_U,
			iif(Mon_IN.RegistrationDate >= 20240101 and Mon
_IN.RegistrationDate < 20250101 , dbo.fFloatToMoney2Varchar(Mon_IN.vol) + 'AMD', '') as MON_IN_V,
			'' as MON_IN_W,
			iif(Sec_Out.RegistrationDate >= 20240101 and Sec_Out.RegistrationDate < 20250101, dbo.fFloatToMoney2Varchar(Sec_Out.vol) + 'AMD', '') a
s Sec_Out_X,
			iif(Sec_Out.RegistrationDate >= 20240101 and Sec_Out.RegistrationDate < 20250101 and sec_out.Country <> 'Armenia', dbo.fFloatToMoney2Varchar(Sec_Out.vol) + 'AMD', '')  as Sec_Out_Y,
			iif(Sec_IN.RegistrationDate >= 20240101 and Sec_In.Reg
istrationDate < 20250101, dbo.fFloatToMoney2Varchar(Sec_In.vol) + 'AMD', '') as Sec_IN_Z,
			iif(Sec_IN.RegistrationDate >= 20240101 and Sec_In.RegistrationDate < 20250101 and sec_in.Country <> 'Armenia', dbo.fFloatToMoney2Varchar(Sec_In.vol) + 'AMD', '')
 as Sec_In_AA 
			, /*iif(pha.dateBefore < 20240101, dbo.fFloatToMoney2Varchar(pha.Qtybefore) + 'AMD', '')*/'' as OwnTurn_AB
			, /*iif(pha.dateBefore >= 20240101 and pha.dateBefore < 20250101, dbo.fFloatToMoney2Varchar(pha.Qtybefore) + 'AMD', '')*/ '' as
 OwnTurn_AC
			, isnull(cor.ID, 0) as ID_Operation
			, isnull(cor.Comment,'') as Comment
			, isnull(cor.Comment2, '') as Comment2
			, isnull(cor.Size, 0) as Origin_Size
			, isnull(ass.ShortName, '') as Origin_Assets
			, fir.IsFirm as is_firm
			, '' 
as Counterparty





		FROM QORT_BACK_DB.dbo.Subaccs sub WITH (NOLOCK)
		left outer join QORT_BACK_DB.dbo.Firms fir on fir.id = iif(sub.SubAccCode = 'Onderka Eduard', 940, sub.OwnerFirm_ID)
		left outer join QORT_BACK_DB.dbo.FirmProperties firP on firP.Fi
rm_ID = fir.id 
		left outer join QORT_BACK_DB.dbo.Countries couTAX on couTAX.ID = firp.TaxResidentCountry_ID 
		left outer join QORT_BACK_DB.dbo.Countries cou on cou.ID = fir.Country_ID 
		left outer join QORT_BACK_DB.dbo.Regions reg on reg.id = firP.id

		left outer join QORT_BACK_DB.dbo.Countries couR on couR.ID = reg.Country_ID 
		left outer join QORT_BACK_DB.dbo.OrgCathegories Catheg on Catheg.ID = fir.OrgCathegoriy_ID
		left outer join QORT_BACK_DB.dbo.CorrectPositions cor on cor.Subacc_ID = sub.id a
nd cor.Enabled = 0 and cor.IsCanceled = 'n' and cor.RegistrationDate < 20250101 and cor.CT_Const in (4,5,6,7)
		left outer join QORT_BACK_DB.dbo.Assets ass on ass.id = cor.Asset_ID
		--left outer join QORT_BACK_DB.dbo.Phases Pha on Pha.Subacc_ID = sub.id 
and Pha.Enabled = 0 and Pha.IsCanceled = 'n' and Pha.PC_Const in (4,5) and sub.SubAccCode in ('AS1031','AS1035','AS1053')
		OUTER APPLY (SELECT TOP 1 FlagName FROM dbo.FTGetIncludedFlags(fir.FT_Flags) WHERE FlagName = 'FT_CLIENT') fClient
		OUTER APPLY (S
ELECT TOP 1 fh.RiskLevel, fh.CRS_Const, fh.IsTaxResident, fh.IsResident FROM QORT_BACK_DB.dbo.FirmsHist fh WITH (NOLOCK) WHERE fh.Founder_ID = fir.ID AND fh.Founder_Date <= @todayInt ORDER BY fh.Founder_Date DESC) fh

		OUTER APPLY (SELECT top 1  ClAgrees.DateSign  as DateSign,

					ClAgrees.DateEnd as DateEnd

		FROM QORT_BACK_DB.dbo.ClientAgrees ClAgrees

		WHERE ClAgrees.Enabled = 0	

		and ClAgrees.ClientAgreeType_ID in (22,20 ,68 ) --(4. AGREEMENT FOR PROVISION OF BROKERAGE SERVICES - Individual , 5. AGREEMENT FOR PROVISION OF BROKERAGE SERVICES -  Legal)

		AND (

		ClAgrees.SubAcc_ID = sub.id

		OR (

			ClAgrees.SubAcc_ID <> sub.id

			AND ClAgrees.OwnerFirm_ID = fir.id

					)

				)				

			) ClAgrees
--/*
		outer apply (select cor.Size * dbo.fn_Quote_AMD(cor.Asset_ID, cor.RegistrationDate) as vol , cor.RegistrationDate as RegistrationDate 
		from QORT_BACK_DB.dbo.CorrectPositions cor7
		left outer join QORT_BACK_DB.dbo.Assets ass on ass.
id = cor.Asset_ID
		where
		cor7.id = cor.id
		and cor.Enabled = 0
		and cor.IsCanceled = 'n'
		and ass.AssetClass_Const in (2) -- Cash
		and cor.Size < 0
		) as Mon_Out
--*/
--/*
		outer apply (select cor.Size * dbo.fn_Quote_AMD(cor.Asset_ID, cor.Registr
ationDate) as vol, cor.RegistrationDate as RegistrationDate 
		from QORT_BACK_DB.dbo.CorrectPositions cor6
		left outer join QORT_BACK_DB.dbo.Assets ass on ass.id = cor.Asset_ID
		where
		cor6.id = cor.id
		and cor.Enabled = 0
		and cor.IsCanceled = 'n'
	
	and ass.AssetClass_Const in (2) -- Cash
		and cor.Size > 0
		) as Mon_IN
--*/
--/*
		outer apply (select cor.Size * dbo.fn_Quote_AMD(cor.Asset_ID, cor.RegistrationDate) as vol, cor.RegistrationDate as RegistrationDate,
					ass.Country as Country
		
		fr
om QORT_BACK_DB.dbo.CorrectPositions cor5
		left outer join QORT_BACK_DB.dbo.Assets ass on ass.id = cor.Asset_ID
		where
		cor5.id = cor.id
		and cor.Enabled = 0
		and cor.IsCanceled = 'n'
		and ass.AssetClass_Const not in (2) -- excluding Cash
		and cor.
Size < 0
		) as Sec_Out
--*/
--/*
		outer apply (select cor.Size * dbo.fn_Quote_AMD(cor.Asset_ID, cor.RegistrationDate) as vol , cor.RegistrationDate as RegistrationDate,
					ass.Country as Country
		from QORT_BACK_DB.dbo.CorrectPositions cor4
				left o
uter join QORT_BACK_DB.dbo.Assets ass on ass.id = cor.Asset_ID
		where
		cor4.id = cor.id
		and cor.Enabled = 0
		and cor.IsCanceled = 'n'
		and ass.AssetClass_Const not in (2) -- excluding Cash
		and cor.Size > 0
		) as Sec_In
--*/

		WHERE sub.Enabled =
 0
		and left(sub.SubAccCode,2) not in ('AA', 'AB', 'AR')
	UNION ALL



		SELECT -- вторая часть: только фазы

					FIR1.BOCode as BOCode,
			Sub.SubAccCode as SubAccCode_A,
			firP1.NameU AS BPName_B,
			iif( fir1.IsFirm = 'y', fir1.RegistrNum, fir1.IDocNum) as DocNum_C,
			'' as TypeBP_D,
			isnull(couTAX.CodeISO_1,'-') as TaxResidentCountry_E,
			isnull(cou.Cod
eISO_1,'-') as Country_F,
			'' as CountryD_G,
			CASE 
				WHEN COALESCE(fh.RiskLevel, fir1.RiskLevel) = 2 THEN 'Medium'
				WHEN COALESCE(fh.RiskLevel, fir1.RiskLevel) = 3 THEN 'Low'
				WHEN COALESCE(fh.RiskLevel, fir1.RiskLevel) = 4 THEN 'High'
				WH
EN COALESCE(fh.RiskLevel, fir1.RiskLevel) = 5 THEN 'Medium Low'
				WHEN COALESCE(fh.RiskLevel, fir1.RiskLevel) = 6 THEN 'Automatic High'
				WHEN COALESCE(fh.RiskLevel, fir1.RiskLevel) = 7 THEN 'Extreme'
				WHEN COALESCE(fh.RiskLevel, fir1.RiskLevel) = 
8 THEN 'Initial'
				ELSE 'N/A'
			END 
		--	+ '  ' + CONVERT(VARCHAR(10), CAST(CONVERT(CHAR(8), @DateTo) AS DATE), 104) 
			AS RiskLevel_H,
			
			isnull(Catheg.Name, '-') as ClientCathegory_I,
			case when ClAgrees.DateSign IS null then 'No_Agree'
				w
hen ClAgrees.DateSign = 0 then 'No_Date'
				else dbo.fIntToDateVarchar_dd_MMM_yyyy(ClAgrees.DateSign) 
				end
																as DateSign_J,

		case 

				when ClAgrees.DateEnd IS null then 'No_Agree'

				when ClAgrees.DateEnd = 0 and sub.ACSTAT_Const = 7 then 

					cast('No_Date(Terminated ' + dbo.fIntToDateVarchar_dd_MMM_yyyy(sub.StatusChangeDate) + ')' as varchar(100))

				else dbo.fIntToDateVarchar_dd_MMM_yyyy(ClAgrees.DateEnd) 

			end as DateEnd_K,	

	--2023
			iif(Mon_Out.RegistrationDate < 20240101, dbo.fFloatToMoney2Varchar(Mon_Out.vol) + 'AMD', '') as MON_OUT_L,
			'' as MON_OUT_M,
			iif(Mon_IN.RegistrationDate < 20240101, dbo.fFloatToMoney2Varchar(Mon_IN.vol) + 'AMD', '') as MON_IN_N,
			'' as M
ON_IN_O,
			iif(Sec_Out.RegistrationDate < 20240101, dbo.fFloatToMoney2Varchar(Sec_Out.vol) + 'AMD', '') as Sec_Out_P,
			iif(Sec_Out.RegistrationDate < 20240101 and sec_out.Country <> 'Armenia' , dbo.fFloatToMoney2Varchar(Sec_Out.vol) + 'AMD', '') as Sec
_Out_Q,
			iif(Sec_IN.RegistrationDate < 20240101, dbo.fFloatToMoney2Varchar(Sec_In.vol) + 'AMD', '') as Sec_IN_R,
			iif(Sec_IN.RegistrationDate < 20240101 and sec_in.Country <> 'Armenia', dbo.fFloatToMoney2Varchar(Sec_In.vol) + 'AMD', '') as Sec_In_S,
	
		--2024
			iif(Mon_Out.RegistrationDate >= 20240101 and Mon_Out.RegistrationDate < 20250101, dbo.fFloatToMoney2Varchar(Mon_Out.vol) + 'AMD', '') as MON_OUT_T,
			'' as MON_OUT_U,
			iif(Mon_IN.RegistrationDate >= 20240101 and Mon_IN.RegistrationDate < 20
250101 , dbo.fFloatToMoney2Varchar(Mon_IN.vol) + 'AMD', '') as MON_IN_V,
			'' as MON_IN_W,
			iif(Sec_Out.RegistrationDate >= 20240101 and Sec_Out.RegistrationDate < 20250101, dbo.fFloatToMoney2Varchar(Sec_Out.vol) + 'AMD', '') as Sec_Out_X,
			iif(Sec_O
ut.RegistrationDate >= 20240101 and Sec_Out.RegistrationDate < 20250101 and sec_out.Country <> 'Armenia', dbo.fFloatToMoney2Varchar(Sec_Out.vol) + 'AMD', '')  as Sec_Out_Y,
			iif(Sec_IN.RegistrationDate >= 20240101 and Sec_In.RegistrationDate < 20250101,
 dbo.fFloatToMoney2Varchar(Sec_In.vol) + 'AMD', '') as Sec_IN_Z,
			iif(Sec_IN.RegistrationDate >= 20240101 and Sec_In.RegistrationDate < 20250101 and sec_in.Country <> 'Armenia', dbo.fFloatToMoney2Varchar(Sec_In.vol) + 'AMD', '') as Sec_In_AA ,

			iif(pha1.PhaseDate < 20240101, dbo.fFloatToMoney2Varchar(pha1.QtyBefore * dbo.fn_Quote_AMD(pha1.PhaseAsset_ID, pha1.PhaseDate)) + 'AMD', '' )  as OwnTurn_AB,

			iif (pha1.PhaseDate < 20250101 and pha1.PhaseDate >= 20240101, dbo.fFloatToMoney2Varchar(pha1.QtyBefore * dbo.fn_Quote_AMD(pha1.PhaseAsset_ID, pha1.PhaseDate)) + 'AMD' , '' )  as OwnTurn_AC,

			Isnull (pha.id, 0) as ID_Operation,

			CASE pha.PC_Const

					WHEN 2 THEN 'Conclusion of agreement'

					WHEN 3 THEN 'Partial delivery'

					WHEN 4 THEN 'Full delivery'

					WHEN 5 THEN 'Partial payment (loan repayment)'

					WHEN 6 THEN 'Interest payment'

					WHEN 7 THEN 'Full payment (loan repayment)'

					WHEN 8 THEN 'Payment of exchange commissions'

					WHEN 9 THEN 'Payment of brokerage commissions'

					WHEN 10 THEN 'Payment of depository commissions'

					WHEN 11 THEN 'Payment of third persons commissions'

					WHEN 12 THEN 'Payment of penalty'

					WHEN 13 THEN 'Payment rescheduling'

					WHEN 14 THEN 'Securities (currency) delivery rescheduling'

					WHEN 15 THEN 'Change the size'

					WHEN 16 THEN 'Prolongation by generating new affiliated trade'

					WHEN 17 THEN 'Trade cancellation'

					WHEN 18 THEN 'Trade closing'

					WHEN 20 THEN 'Termination of trade'

					WHEN 21 THEN 'Margin call in cash'

					WHEN 22 THEN 'Margin call in securities'

					WHEN 23 THEN 'Payment of external broker commissions'

					WHEN 24 THEN 'Payment of tax'

					WHEN 25 THEN 'Corp. payment'

					WHEN 26 THEN 'External payment'

					WHEN 27 THEN 'External delivery'

					WHEN 28 THEN 'Accrual of payments'

					WHEN 29 THEN 'Agreement termination'

					WHEN 30 THEN 'Cash flow'

					WHEN 31 THEN 'Asset recovery'

					WHEN 32 THEN 'Termination fee payment'

					WHEN 33 THEN 'Settlement tolerance'

					WHEN 34 THEN 'Contract exercise'

					WHEN 35 THEN 'Contract closing'

					ELSE 'Unknown'

				END AS Comment,

			'' as Comment2,

			pha.QtyBefore  as  Origin_Size,

			ass1.ShortName as Origin_Assets

			, fir1.IsFirm as is_firm

			, isnull(Tra.CP, '-') as Counterparty

		FROM QORT_BACK_DB.dbo.Subaccs sub

		left outer join QORT_BACK_DB.dbo.Firms fir1 on fir1.id = iif(sub.SubAccCode = 'Onderka Eduard', 940, sub.OwnerFirm_ID)
		left outer join QORT_BACK_DB.dbo.FirmProperties firP1 on firP1.Firm_ID = fir1.id

			left outer join QORT_BACK_DB.dbo.Countries couTAX on couTAX.ID = firp1.TaxResidentCountry_ID 
		left outer join QORT_BACK_DB.dbo.Countries cou on cou.ID = fir1.Country_ID 
		left outer join QORT_BACK_DB.dbo.Regions reg on reg.id = firP1.id
		left outer
 join QORT_BACK_DB.dbo.Countries couR on couR.ID = reg.Country_ID 
		left outer join QORT_BACK_DB.dbo.OrgCathegories Catheg on Catheg.ID = fir1.OrgCathegoriy_ID
		--left outer join QORT_BACK_DB.dbo.Phases Pha on Pha.Subacc_ID = sub.id and Pha.Enabled = 0 
and Pha.IsCanceled = 'n' and Pha.PC_Const in (4,5) and sub.SubAccCode in ('AS1031','AS1035','AS1053')
		OUTER APPLY (SELECT TOP 1 FlagName FROM dbo.FTGetIncludedFlags(fir1.FT_Flags) WHERE FlagName = 'FT_CLIENT') fClient
		OUTER APPLY (SELECT TOP 1 fh.Risk
Level, fh.CRS_Const, fh.IsTaxResident, fh.IsResident FROM QORT_BACK_DB.dbo.FirmsHist fh WITH (NOLOCK) WHERE fh.Founder_ID = fir1.ID AND fh.Founder_Date <= @todayInt ORDER BY fh.Founder_Date DESC) fh

		OUTER APPLY (SELECT top 1  ClAgrees.DateSign  as DateSign,

					ClAgrees.DateEnd as DateEnd

		FROM QORT_BACK_DB.dbo.ClientAgrees ClAgrees

		WHERE ClAgrees.Enabled = 0	

		and ClAgrees.ClientAgreeType_ID in (22,20 ,68 ) --(4. AGREEMENT FOR PROVISION OF BROKERAGE SERVICES - Individual , 5. AGREEMENT FOR PROVISION OF BROKERAGE SERVICES -  Legal)

		AND (

		ClAgrees.SubAcc_ID = sub.id

		OR (

			ClAgrees.SubAcc_ID <> sub.id

			AND ClAgrees.OwnerFirm_ID = fir1.id

					)

				)				

			) ClAgrees

		left outer JOIN QORT_BACK_DB.dbo.Phases pha on pha.SubAcc_ID = sub.id and pha.PhaseDate < 20250101

		left outer JOIN QORT_BACK_DB.dbo.Assets ass1 on ass1.id = pha.PhaseAsset_ID



		outer apply (select * from QORT_BACK_DB.dbo.Phases pha1 

				where pha1.ID = pha.id 		 AND (

          EXISTS (

              SELECT 1 FROM QORT_ARM_SUPPORT.dbo.FTGetIncludedFlags(fir1.FT_Flags) fl

              WHERE fl.FlagName = 'FT_BENEFICIARY'

          )

          OR EXISTS (

              SELECT 1 FROM QORT_ARM_SUPPORT.dbo.FTGetIncludedFlags(fir1.FT_Flags) fl

              WHERE fl.FlagName = 'FT_DIRECTOR'

          )

      )) as pha1

		





		--/*
		outer apply (select pha.QtyBefore * pha.QtyAfter * dbo.fn_Quote_AMD(pha.PhaseAsset_ID, pha.PhaseDate) as vol , pha.PhaseDate as RegistrationDate 
		from QORT_BACK_DB.dbo.Phases pha7
		left outer join QORT_BACK_DB.dbo.Assets ass on ass.id = pha.Ph
aseAsset_ID
		where
		pha7.id = pha.id
		and pha.Enabled = 0
		and pha.IsCanceled = 'n'
		and ass.AssetClass_Const in (2) -- Cash
		and pha.QtyBefore * pha.QtyAfter < 0
		) as Mon_Out
--*/
--/*
		outer apply (select pha.QtyBefore * pha.QtyAfter * dbo.fn_Q
uote_AMD(pha.PhaseAsset_ID, pha.PhaseDate) as vol , pha.PhaseDate as RegistrationDate 
		from QORT_BACK_DB.dbo.Phases Pha6
		left outer join QORT_BACK_DB.dbo.Assets ass on ass.id = pha.PhaseAsset_ID
		where
		Pha6.id = pha.id
		and pha.Enabled = 0
		and p
ha.IsCanceled = 'n'
		and ass.AssetClass_Const in (2) -- Cash
		and pha.QtyBefore * pha.QtyAfter > 0
		) as Mon_IN
--*/
--/*
		outer apply (select pha.QtyBefore * pha.QtyAfter * dbo.fn_Quote_AMD(pha.PhaseAsset_ID, pha.PhaseDate) as vol , pha.PhaseDate as 
RegistrationDate ,
					ass.Country as Country
		
		from QORT_BACK_DB.dbo.Phases Pha5
		left outer join QORT_BACK_DB.dbo.Assets ass on ass.id = pha.PhaseAsset_ID
		where
		Pha5.id = pha.id
		and pha.Enabled = 0
		and pha.IsCanceled = 'n'
		and ass.AssetCl
ass_Const not in (2) -- excluding Cash
		and pha.QtyBefore * pha.QtyAfter < 0
		) as Sec_Out
--*/
--/*
		outer apply (select pha.QtyBefore * pha.QtyAfter * dbo.fn_Quote_AMD(pha.PhaseAsset_ID, pha.PhaseDate) as vol , pha.PhaseDate as RegistrationDate ,
			
		ass.Country as Country
		from QORT_BACK_DB.dbo.Phases Pha4
				left outer join QORT_BACK_DB.dbo.Assets ass on ass.id = pha.PhaseAsset_ID
		where
		Pha4.id = pha.id
		and pha.Enabled = 0
		and pha.IsCanceled = 'n'
		and ass.AssetClass_Const not in (2) --
 excluding Cash
		and pha.QtyBefore * pha.QtyAfter > 0
		) as Sec_In
--*/

--/*
		outer apply (select frm.Name as CP
		from QORT_BACK_DB.dbo.Trades tra 
		left outer join QORT_BACK_DB.dbo.Firms frm on frm.id = tra.CpFirm_ID
		where tra.id = pha.Trade_ID
		) as Tra
--*/

		WHERE pha.Enabled = 0 AND pha.IsCanceled = 'n' AND pha.PC_Const IN (3,4,5,6,7,8,9,10,11,12,23,24) 

		AND sub.Enabled = 0 and left(sub.SubAccCode,2) not in ('AA', 'AB', 'AR')


		ORDER BY SubAccCode_A

	END TRY
	BEGIN CATCH
		WHILE @@TRANCOUNT > 0 ROLLBACK TRANSACTION
		SET @Message = 'ERROR: ' + ERROR_MESSAGE()
		INSERT INTO QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) VALUES (@Message, 1001)
		PRINT @Message
		SELE
CT @Message AS Result, 'red' AS ResultColor
	END CATCH
END

