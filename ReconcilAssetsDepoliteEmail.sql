







-- exec QORT_ARM_SUPPORT.dbo.ReconcilAssetsDepoliteEmail

CREATE PROCEDURE [dbo].[ReconcilAssetsDepoliteEmail]



AS



BEGIN

 EXECUTE AS LOGIN = 'aleksandr.mironov';

	begin try

		

		declare @todayDate date = getdate()

		declare @todayInt int = cast(convert(varchar, @todayDate, 112) as int)



		declare @Message varchar(1024)

		declare @SendMail bit = 0

		declare @Result varchar(128) 

		declare @NotifyEmail varchar(1024) = 'aleksandr.mironov@armbrok.am;sona.nalbandyan@armbrok.am;armine.khachatryan@armbrok.am;armine.khachatryan@armbrok.am;dianna.petrosyan@armbrok.am;anahit.titanyan@armbrok.am'		

		declare @sql varchar(1024)

		declare @n int = 2 -- for double running

		declare @ISIN varchar(128)

		declare @n1 int 

		 if OBJECT_ID('tempdb..##resultDepoliteAssets', 'U') is not null drop table ##resultDepoliteAssets

		if OBJECT_ID('tempdb..##f', 'U') is not null drop table ##f

		if OBJECT_ID('tempdb..#t', 'U') is not null drop table #t



while (@n > 0)

begin

if OBJECT_ID('tempdb..##resultDepoliteAssets', 'U') is not null drop table ##resultDepoliteAssets

if OBJECT_ID('tempdb..#t', 'U') is not null drop table #t

print @n

    select  kind.NAME_ARM as NAMEKIND_ARM, kind.NAME_ENG as NAMEKIND_ENG , type.NAME_ARM as NAMETYPE_ARM, type.NAME_ENG as NAMETYPE_ENG 

	 , assCur.Name as curAss

	, sec.secur

	, sec.num

	, ass.ISIN

	, ass.Name NameQ

	, s2.StatusTXT

	, CUSTOM.NAME_ARM CUSTOMER_NAME_ARM

	, CUSTOM.NAME_ENG CUSTOMER_NAME_ENG

	, CUSTOM.CUSTOMER id_CUSTOMER

	, FIR.Name emname

	, FIRp.NameU

	, FIR.BOCode BOCode

	, FIR.EmitCode EmitCode

	, custom.DEDNUM DEDNUM

	, sec.closedate closedate

	--,* 

	into ##resultDepoliteAssets

	from [192.168.13.8].[Depositary].[dbo].[SECURKIND] sec

  outer apply(select top 1 NAME_A as NAME_ARM, NAME_E as NAME_ENG from [192.168.13.8].[Depositary].[dbo].[DICTION_S] where NUMID = sec.KIND and CCOLUMN = 'KIND' and CTABLE = 'SECUR') KIND

  outer apply(select top 1 NAME_A as NAME_ARM, NAME_E as NAME_ENG from [192.168.13.8].[Depositary].[dbo].[DICTION_S] where NUMID = sec.TYPE and CCOLUMN = 'TYPE' AND CTABLE = 'SECUR') TYPE

  outer apply(select top 1 NAME_A as NAME_ARM, NAME_E as NAME_ENG, CUSTOMER AS  CUSTOMER, DEDNUM as DEDNUM from [192.168.13.8].[Depositary].[dbo].[CUSTOMER] where CUSTOMER = sec.OWNER) CUSTOM

  full outer join [QORT_BACK_DB].[dbo].[Assets] ass 
    on ass.ISIN = Sec.num COLLATE SQL_Latin1_General_CP1_CI_AS
    and ass.Enabled = 0
    --and (ass.CancelDate > @todayInt or ass.CancelDate < 20001231)
    and ass.AssetClass_Const in (5,6,11,16,18)

    and ass.IsTrading = 'y'

	

	

	left outer join QORT_BACK_DB.dbo.Assets assCur on assCur.id =  ass.BaseCurrencyAsset_ID

	left outer join QORT_BACK_DB.dbo.Firms FIR on FIR.id =  ass.EmitentFirm_ID

	left outer join QORT_BACK_DB.dbo.FirmProperties FIRP ON FIRP.Firm_ID = FIR.id

		outer apply (

SELECT 

    CASE 

        WHEN sec.num IS NULL and (ass.CancelDate > @todayInt or ass.CancelDate < 20001231) and ass.AssetClass_Const in (5,6,11,16,18) and ass.IsTrading = 'y' and ass.Enabled = 0 THEN 

            'Missed In Depolite ' + ass.ISIN COLLATE SQL_Latin1_General_CP1_CI_AS

        WHEN ass.ISIN IS NULL and sec.closedate > @todayDate and (ass.CancelDate > @todayInt or ass.CancelDate < 20001231) and ass.IsTrading = 'y' and ass.AssetClass_Const in (5,6,11,16,18) THEN 

            'Missed In Qort ' + sec.num COLLATE SQL_Latin1_General_CP1_CI_AS

        ELSE 

            ''

            + CASE 

              -- причина - тип минфин не работает в деполайт WHEN sec.kind = 2 and sec.closedate > @todayDate AND ass.AssetClass_Const NOT IN (6)  and ass.AssetSort_Const not IN (3) and ass.COUNTRY COLLATE SQL_Latin1_General_CP1_CI_AS not IN ('Armenia') T
HEN 

		       WHEN sec.kind not in (5) AND ass.AssetClass_Const IN (6)  and ass.AssetSort_Const IN (3) and ass.COUNTRY COLLATE SQL_Latin1_General_CP1_CI_AS IN ('Armenia') THEN 

             ', KIND: ' + sec.num + type.NAME_ARM COLLATE SQL_Latin1_General_CP1_CI_AS + ' '

                ELSE ''

              END

            + CASE 

                WHEN sec.scur COLLATE SQL_Latin1_General_CP1_CI_AS <> assCur.Name COLLATE SQL_Latin1_General_CP1_CI_AS and sec.closedate > @todayDate THEN 

                    ', CURRENCY: ' + sec.scur COLLATE SQL_Latin1_General_CP1_CI_AS + ' depolite/qort ' + assCur.Name COLLATE SQL_Latin1_General_CP1_CI_AS

                ELSE ''

              END

            + CASE 

                WHEN sec.MINAMNT <> ass.BaseValue and sec.closedate > @todayDate THEN 

                    ', NOMINAL: ' + CAST(sec.MINAMNT AS VARCHAR(12)) + ' depolite/qort ' + CAST(ass.BaseValue AS VARCHAR(12))

                ELSE ''

              END

				+ CASE 

					WHEN isnull(custom.DEDNUM,'') COLLATE SQL_Latin1_General_CP1_CI_AS <> isnull(FIR.BOCode,' ') COLLATE SQL_Latin1_General_CP1_CI_AS and sec.closedate > @todayDate THEN 

						', ISSUE: ' + CAST(isnull(custom.NAME_ARM,'') COLLATE SQL_Latin1_General_CP1_CI_AS AS VARCHAR(12)) 

						+ ' depolite/qort ' 

						+ CAST(isnull(FIR.Name,'') COLLATE SQL_Latin1_General_CP1_CI_AS AS VARCHAR(12))

					ELSE ''

				  END

            + CASE 

                WHEN sec.kind = 4 AND ass.COUNTRY COLLATE SQL_Latin1_General_CP1_CI_AS IN ('Armenia') THEN 

                    ', KIND: ' + sec.num + '_'+ KIND.NAME_ARM COLLATE SQL_Latin1_General_CP1_CI_AS + ' DEPOLITE/Qort-Armenia'

                WHEN sec.kind = 3 AND ass.COUNTRY COLLATE SQL_Latin1_General_CP1_CI_AS NOT IN ('Armenia') THEN 

                    ', KIND: ' + sec.num + '_'+ KIND.NAME_ARM COLLATE SQL_Latin1_General_CP1_CI_AS + ' DEPOLITE/Qort-notArmenia'

                WHEN sec.kind IN (1) AND (ass.AssetClass_Const IN (6) and ass.COUNTRY COLLATE SQL_Latin1_General_CP1_CI_AS not IN ('Armenia')) THEN 

                    ', KIND: ' + sec.num + '_'+ KIND.NAME_ARM COLLATE SQL_Latin1_General_CP1_CI_AS + ' DEPOLITE/Qort-notOther'

					WHEN sec.kind IN (5) AND (ass.AssetClass_Const not IN (11) and ass.COUNTRY COLLATE SQL_Latin1_General_CP1_CI_AS not IN ('Armenia')) THEN 

                    ', KIND: ' + sec.num + '_'+ KIND.NAME_ARM COLLATE SQL_Latin1_General_CP1_CI_AS + ' DEPOLITE/Qort-notOther'

					

                ELSE ''

              END

            + CASE 

                WHEN sec.type = 1 AND ((ass.AssetClass_Const NOT IN (6, 7, 9) and ass.IsCouponed = 'y')) THEN 

                    ', TYPE: ' + sec.num +'_'+ type.NAME_ARM COLLATE SQL_Latin1_General_CP1_CI_AS + ' DEPOLITE/Qort-withCoupon'

                WHEN sec.type = 2 AND ((ass.AssetClass_Const NOT IN (6, 7, 9) and ass.IsCouponed = 'n')) THEN 

                    ', TYPE: ' + sec.num + '_'+ type.NAME_ARM COLLATE SQL_Latin1_General_CP1_CI_AS + ' DEPOLITE/Qort-notCoupon'

                WHEN sec.type IN (3, 7) AND ((ass.AssetClass_Const NOT IN (8,5) and ass.AssetSort_Const NOT IN (1))) THEN 

                    ', TYPE: ' + sec.num + '_'+ type.NAME_ARM COLLATE SQL_Latin1_General_CP1_CI_AS + ' DEPOLITE/Qort-NOTcommon'

				WHEN sec.type IN (8) AND ((ass.AssetClass_Const NOT IN (8,5,11) and ass.AssetSort_Const NOT IN (1, 14))) THEN 

                    ', TYPE: ' + sec.num + '_'+ type.NAME_ARM COLLATE SQL_Latin1_General_CP1_CI_AS + ' DEPOLITE/Qort-NOTcommon'

                WHEN sec.type IN (4) AND ((ass.AssetClass_Const NOT IN (8,5) and ass.AssetSort_Const NOT IN (2,78))) THEN 

                    ', TYPE: ' + sec.num + '_'+ type.NAME_ARM COLLATE SQL_Latin1_General_CP1_CI_AS + ' DEPOLITE/Qort-NOTpreferred'

                WHEN sec.type IN (5) AND ass.AssetClass_Const NOT IN (18) THEN 

                    ', TYPE: ' + sec.num + '_'+ type.NAME_ARM COLLATE SQL_Latin1_General_CP1_CI_AS + ' DEPOLITE/Qort-notETF'

                WHEN sec.type IN (6) AND ass.AssetClass_Const NOT IN (16) THEN 

                    ', TYPE: ' + sec.num + '_'+ type.NAME_ARM COLLATE SQL_Latin1_General_CP1_CI_AS + ' DEPOLITE/Qort-notADR'

                ELSE ''

              END



				end StatusTXT

		) s1

		outer apply (

			select case when left(s1.StatusTXT, 2) = ', ' then 'Mismatched: ' + right(StatusTXT, len(StatusTXT) - 2)

						when StatusTXT = '' then 'OK'

						else StatusTXT end StatusTXT

		) s2

		outer apply (select iif(s2.StatusTXT = 'OK', 'green', 'red') ResultColor) s3

	

 where NOT (isnull(Sec.num, '') = '' and isnull(ass.ISIN, '') = '')

 select * from ##resultDepoliteAssets



		SELECT DISTINCT ROW_NUMBER() OVER (ORDER BY ISIN) AS RowNumber
			, ISIN
			--, StatusTXT
		into #t	
		FROM ##resultDepoliteAssets
		WHERE StatusTXT NOT IN ('OK');

		--return

		set @n1 = (select MAX (rowNumber) from #t)



		while @n1 > 0

		begin

		set @ISIN = (select top 1 ISIN from #t where RowNumber = @n1)

		print @ISIN

		exec QORT_ARM_SUPPORT.dbo.LoadSecurDepolite @ISINCode = @ISIN

		set @n1 = @n1 - 1

		end 











 set @n = @n - 1

 end





	select * from ##resultDepoliteAssets --order by BOCode



	

	end try

	begin catch

		while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		print @Message

		select @Message Result, 'red' ResultColor

	end catch

	REVERT;

END

