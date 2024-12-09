
-- exec QORT_ARM_SUPPORT..Asset_insert @IsinCodes = 'US00212E1038 EQUITY'

CREATE PROCEDURE [dbo].[Asset_insert]
@IP VARCHAR(16)= '192.168.13.80',
@IsinCodes NVARCHAR(MAX)



AS



BEGIN





		begin try



		exec QORT_ARM_SUPPORT..BDP_FlaskRequest @IP, @IsinCode = @IsinCodes



		declare @TodayDate date = getdate()

		declare @TodayDateInt int = cast(convert(varchar, @TodayDate, 112) as int)

		declare @Message varchar(1024)

		declare  @WaitCount int = 1200

		while (@WaitCount > 0 and not exists (select top 1 1 from QORT_ARM_SUPPORT.dbo.BloombergData where Code = @IsinCodes))

		begin

			waitfor delay '00:00:03'

			set @WaitCount = @WaitCount - 1

		end

		-----добавление эмитента если нет-----------------------

		IF(NOT EXISTS (
				select 1 
				from QORT_BACK_DB.dbo.firms a
				left outer join QORT_ARM_SUPPORT.dbo.BloombergData blm on blm.Issuer_Bulk = a.CBR_ShortName COLLATE SQL_Latin1_General_CP1_CI_AS
				where blm.code = @IsinCodes and a.Enabled = 0 
				a
nd DATE = @TodayDateInt
			))

			begin



				 insert into QORT_BACK_TDB.dbo.Firms (ET_Const, IsProcessed, BOCode, CBR_ShortName, name, FirmShortName,EngName,EngShortName,FT_Flags,IsResident, isfirm)

				  select distinct 2 as ET_Const, 1 as IsProcessed

				  , '0'+ CAST(isnull(BOCodeMax.BOC, '7000') AS varchar(12)) as BOCode

				  , bl.Issuer_Bulk as CBR_ShortName 

				  , bl.Issuer_Bulk as name

				  , bl.Issuer_Bulk as FirmShortName

				  , bl.Issuer_Bulk as EngName

				  , bl.Issuer_Bulk as EngShortName

				  , 128 as FT_Flags -- issue

				  , iif(bl.DS497 = 'ARMENIA', 'y', 'n')  as IsResident

				  , 'y' as isfirm

				  --, fir.CBR_ShortName, ass.ISIN, * 

				  FROM QORT_ARM_SUPPORT.dbo.BloombergData bl

				outer apply (
					SELECT (MAX(CAST((BOCode) AS INT)) + 1) AS BOC
					FROM QORT_BACK_DB.dbo.Firms
					WHERE 
						ISNUMERIC(BOCode) = 1 -- Проверяем, что значение является числовым
						AND TRY_CAST(BOCode AS INT) >= 7000 -- Проверяем, что значени
е больше 7000
						AND TRY_CAST(BOCode AS INT) < 8000 -- Проверяем, что значение меньше 8000
				) BOCodeMax

				where DATE = @TodayDateInt and Code = @IsinCodes



  end --RETURN

  				 -------------------- задержка----------------------

		while (@WaitCount > 0 and exists (select top 1 1 from QORT_BACK_TDB.dbo.Firms t with (nolock) where t.IsProcessed in (1,2)))

		begin

			waitfor delay '00:00:03'

			set @WaitCount = @WaitCount - 1

		end







		--/*

		insert into QORT_BACK_TDB.dbo.Assets(

			IsProcessed, ET_Const

			, Name, ISIN, AssetClass_Const

			, AssetSort_Const, AssetType_Const, BaseValue, CancelDate, Country

			, ShortName, ViewName, IsInSanctionList, IsCouponed

			, EmitDate

			, PricingTSSectionName

			, BaseValueOrigin

			, BaseCurrencyAsset

			, CouponsPerYear

			, Marking

			, CouponScale

			, IsTrading

			, Scale

			, EmitentBOCode

		) 

	--	*/

		SELECT TOP 1 1 as IsProcessed, 2 as ET_Const,

			 BL.name NAME

			 , LEFT(BL.Code,12) ISIN



			 , CASE WHEN BL.DS122 = 'Equity' AND (BL.DS674 = 'Common Stock' OR BL.DS674 = 'Preference')

				THEN 5 -- Equity RF(AC_SEC)

				WHEN BL.DS122 = 'Equity' AND BL.DS674 = 'Mutual Fund'

				THEN 18 --ETF(AC_ETF)

				WHEN BL.DS122 = 'Corp' OR BL.DS122 = 'Govt' 

				THEN 6 --	RF gov. bonds(AC_SNSEC)

				WHEN BL.DS122 = 'Equity' and BL.DS674 = 'Depositary Receipt'

				THEN 16 --	RDR(ADR)(AC_RDR)

				ELSE 0

				END

							AssetClass_Const

			 ,  CASE WHEN BL.DS122 = 'Equity' AND BL.DS674 = 'Common Stock' 

				THEN 1 -- 	Common/Ordinary shares(AS_SEC_BASIC)

				WHEN BL.DS122 = 'Equity' AND BL.DS674 = 'Preference'

				THEN 78 -- 	Preferred/Preference shares(AS_PREF)

				WHEN BL.DS122 = 'Equity' AND BL.DS674 = 'Depositary Receipt'

				THEN 32 -- 		RDR(AS_RDR)

				WHEN BL.DS122 = 'Equity' AND BL.DS674 = 'Mutual Fund'

				THEN 84 --ETF(AC_ETF)

				WHEN BL.DS122 = 'Govt' 

				THEN 3 --	Federal loan bonds(AS_OFZ)

				WHEN BL.DS122 = 'Corp'  

				THEN 6 --	Corporate bonds(AS_CORP)

				ELSE 0

				END

							 AssetSort_Const

			 , 1 -- Securities

							 AssetType_Const

			 , ISNULL(BL.Par_Amt,0)

						BaseValue

			 , TRY_CONVERT(VARCHAR(8), DATEADD(MINUTE, CAST(Maturity AS bigint)/60000, '1970-01-01'), 112) AS CancelDate

			 , CASE WHEN BL.DS497 = 'UNITED STATES' 

					THEN 'USA'

					ELSE BL.DS497

					END

						Country

			, CASE WHEN BL.DS122 = 'Equity'

					THEN BL.DX657

					ELSE BL.Security_Name

					END

				ShortName

			, CASE WHEN BL.DS122 = 'Equity'

					THEN BL.DX657

					ELSE BL.Security_Name

					END

			

				ViewName

			, IIF(BL.Sectoral_Sanctioned_Security = 'y' OR BL.OFAC_Sanctioned_Security = 'y'  OR BL.EU_SAnctioned_Security = 'y' OR BL.UK_Sanctioned_Security = 'y', 'y', 'n') 

			IsInSanctionList

			, IIF(BL.CPN IS NULL, 'n', 'y') IsCouponed

			, TRY_CONVERT(VARCHAR(8), DATEADD(MINUTE, CAST(Issue_dt AS bigint)/60000, '1970-01-01'), 112) AS EmitDate
			--, TRY_CONVERT(VARCHAR(8), DATEADD(MINUTE, CAST(Nxt_Cpn_Dt AS bigint)/60000, '1970-01-01'), 112) AS Nxt_Cpn_Dt

			, 'OTC_Securities' PricingTSSectionName

			, ISNULL(BL.Par_Amt,0) BaseValueOrigin

			, ISNULL(BL.EQY_Prim_Security_Crncy, ISNULL(bl.CRNCY,0)) BaseCurrencyAsset

			, isnull(BL.CPN_FREQ, 0) CouponsPerYear

			, LEFT(BL.Code,12) Marking

			, 10 as CouponScale

			, 'y' IsTrading

			, 8 Scale

			, BOCO.BOC as EmitentBOCode

			--into #t

		 FROM QORT_ARM_SUPPORT.dbo.BloombergData BL

		 outer apply
					(select top 1 BOCode as BOC
							from QORT_BACK_DB.dbo.firms a
							where bl.Issuer_Bulk = a.CBR_ShortName

					) BOCO

		 WHERE BL.Code = @IsinCodes AND BL.Found = 1

		 and NOT EXISTS (
				select 1 
				from QORT_BACK_DB.dbo.Assets a
				where a.ISIN = LEFT(@IsinCodes,12) and a.Enabled = 0
			)





		--left outer join QORT_BACK_DB_TEST.dbo.Assets ass with (nolock) on ass.ISIN = s.ISIN and ass.AssetClass_Const <> 2 

		--left outer join QORT_BACK_DB_UAT.dbo.Assets b on s.ISIN = b.ISIN and b.Enabled <> b.id and b.AssetClass_Const <> 2 



		--where s.Enabled <> s.id and b.isin is null --and s.ISIN = 'US8716071076'

		-- return





				 -------------------- задержка----------------------

		while (@WaitCount > 0 and exists (select top 1 1 from QORT_BACK_TDB.dbo.Assets t with (nolock) where t.IsProcessed in (1,2)))

		begin

			waitfor delay '00:00:03'

			set @WaitCount = @WaitCount - 1

		end

		--/*

		insert into QORT_BACK_TDB.dbo.Securities (

			IsProcessed, ET_Const, ShortName

			, Name, TSSection_Name, SecCode

			, Asset_ShortName, QuoteList, IsProcent

			, LotSize, IsTrading, Lot_multiplicity

			, Scale

			, CurrPriceAsset_ShortName

		) 

		--*/

		SELECT 1 as IsProcessed, 2 as ET_Const

			, s.shortname

			, s.ISIN Name

			, 'OTC_Securities' as TSSection_Name

			, s.ISIN  secCode

			, s.ShortName Asset_ShortName

			, 1 QuoteList

			, iif(s.AssetSort_Const in (6,3), 'y', NULL) IsProcent

			, 1 LotSize

			, 'y' IsTrading

			, 1 lot_multiplicity

			, 8 Scale

			, (SELECT TOP 1 crncy from QORT_ARM_SUPPORT.dbo.BloombergData where Code = @IsinCodes) CurrPriceAsset_ShortName

		FROM QORT_BACK_DB.dbo.Assets s

		--left outer join QORT_BACK_DB_UAT.dbo.Assets ass with (nolock) on ass.id = s.Asset_ID and 

		--left join QORT_BACK_DB_UAT.dbo.Securities b on a.ISIN = b.ISIN and b.Enabled = 0 and 



		where s.Enabled = 0 and s.ISIN = LEFT(@IsinCodes,12)

		 and NOT EXISTS (
				select 1 
				from QORT_BACK_DB.dbo.Securities a
				where a.ShortName = s.ShortName and a.Enabled = 0
			)

	/*declare @t table(code varchar(36))

	insert into @t(code)

	select top 1 Code 

	from QORT_ARM_SUPPORT.dbo.BloombergData 

	where Code = @IsinCodes

	select * from @t

	*/

	--------------------запуск добавления котировки и купона-----------------------------

	exec QORT_ARM_SUPPORT.dbo.upload_MarketInfo @IP, @IsinCode = @IsinCodes

	--------------------------------------------------------------------------------

	



	



	end try

	begin catch

		while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE() + ISNULL(', ' , '');  

		if @message not like '%12345 Cannot initialize the data source%' insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		print @Message

	end catch



END
