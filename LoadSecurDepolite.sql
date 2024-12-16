









-- exec QORT_ARM_SUPPORT.dbo.LoadSecurDepolite @ISINCode = 'NL0009805522'





CREATE PROCEDURE [dbo].[LoadSecurDepolite]

	

   @ISINCode varchar(16)



AS



BEGIN

EXECUTE AS LOGIN = 'aleksandr.mironov';

	begin try



		declare @todayDate date = getdate()

		declare @todayInt int = cast(convert(varchar, @todayDate, 112) as int)

		declare @Message varchar(1024) -- для уведомлений об ошибках

		declare @OWNER bigint

		declare @BOCode varchar(32)

		declare @WaitCount int = 1200

		set @ISINCode = LEFT(@ISINCode,12)



IF not EXISTS (

    SELECT 1

    FROM [192.168.13.8].[Depositary].[dbo].[SECURKIND] g

    WHERE g.NUM = @ISINCode

)

BEGIN





SET @BOCode = (
    SELECT TOP 1 firms.BOCode
    FROM QORT_BACK_DB.dbo.Assets asss
	left outer join QORT_BACK_DB.dbo.Firms firms on firms.id = asss.EmitentFirm_ID
    WHERE asss.ISIN = @ISINCode and asss.Enabled = 0 and asss.IsTrading = 'y'
)	



if (@BOCode is null) begin print 'Problem Issue' return end





SET @OWNER = (
    SELECT TOP 1 customer
    FROM [192.168.13.8].[Depositary].[dbo].[CUSTOMER] g
    WHERE g.DEDNUM = @BOCode
)



if (@OWNER is null) 

begin 

print 'load issue'

exec QORT_ARM_SUPPORT.dbo.LoadFirmDepolite @BOCode = @BOCode

end



while (@WaitCount > 0 and @OWNER is null)

		begin



		set @OWNER = (select top 1 CUSTOMER from [192.168.13.8].[Depositary].[dbo].[CUSTOMER] where DEDNUM = @BOCode)

			waitfor delay '00:00:03'

			set @WaitCount = @WaitCount - 1

		end





if (@OWNER is null) begin print 'Problem OWNER' return end







--/*

					INSERT INTO [192.168.13.8].[Depositary].[dbo].[SECURKIND] (
				SECUR,
				KIND,
				TYPE,
				RERATE,
				MINAMNT,
				OPENDATE,
				CLOSEDATE,
				PERIOD,
				NOTE,
				YRATE,
				STATE,
				TSTIME,
				OWNER,
				FIRSTDATE,
				NUM,
				REGNUM,
		
		SCUR
			)
--*/
			SELECT 
				left(ass.Name + ' ' + ass.ISIN + ' ' + fir.Name,49) AS SECUR, -- SECUR
				CASE 
					WHEN ass.COUNTRY COLLATE SQL_Latin1_General_CP1_CI_AS NOT IN ('Armenia') THEN 4 -- KIND
					WHEN ass.AssetClass_Const IN (6) AND ass.Ass
etSort_Const IN (3) THEN 2 -- Depolie(MinFin)
					WHEN ass.AssetClass_Const IN (6) AND ass.AssetSort_Const NOT IN (3) THEN 3 -- Depolie(CorpBonds)
					ELSE 5 -- Depolite (other)
				END AS KIND,
				CASE 
					WHEN ass.AssetClass_Const IN (18) THEN 5 --
 TYPE
					WHEN ass.AssetClass_Const IN (16) THEN 6
					WHEN ass.AssetClass_Const IN (6, 7, 9) AND ass.IsCouponed = 'n' THEN 1
					WHEN ass.AssetClass_Const IN (6, 7, 9) AND ass.IsCouponed = 'y' THEN 2
					WHEN ass.AssetClass_Const IN (8, 5) AND ass.As
setSort_Const IN (1) THEN 3
					WHEN ass.AssetClass_Const IN (8, 5) AND ass.AssetSort_Const IN (2, 78) THEN 4
					ELSE 8
				END AS TYPE,
				1 AS RERATE, -- RERATE
				ass.BaseValue AS MINAMNT, -- MINAMNT
				CONVERT(DATETIME, CONVERT(VARCHAR(8), IIF(a
ss.EmitDate = 0, null, ass.EmitDate), 112)) AS OPENDATE, -- OPENDATE
				CONVERT(DATETIME, CONVERT(VARCHAR(8), IIF(ass.CancelDate = 0, null, ass.CancelDate), 112)) AS CLOSEDATE, -- CLOSEDATE
				0 AS PERIOD, -- PERIOD
				NULL AS NOTE, -- NOTE
				isnull(
cp.cpn,0) AS YRATE, -- YRATE
				1 AS STATE, -- STATE
				@todayDate AS TSTIME, -- TSTIME
				@OWNER AS OWNER, -- OWNER
				NULL AS FIRSTDATE, -- FIRSTDATE
				@ISINCode AS NUM, -- NUM
				NULL AS REGNUM, -- REGNUM
				assC.Name AS SCUR -- SCUR
			FROM QO
RT_BACK_DB.dbo.Assets ass
			LEFT OUTER JOIN QORT_BACK_DB.dbo.Assets assC 
				ON assC.id = ass.BaseCurrencyAsset_ID
			LEFT OUTER JOIN QORT_BACK_DB.dbo.Firms fir 
				ON fir.ID = ass.EmitentFirm_ID
			OUTER APPLY (
				SELECT TOP 1 Cpn AS cpn 
				FROM Q
ORT_ARM_SUPPORT.dbo.BloombergData 
				WHERE LEFT(code, 12) = @ISINCode
				ORDER BY DATE DESC
			) AS Cp
			WHERE ass.isin = @ISINCode 
			  AND ass.Enabled = 0 
			  AND ass.IsTrading = 'y'
			  AND NOT EXISTS (
				  SELECT 1
				  FROM [192.168.13.8].
[Depositary].[dbo].[SECURKIND] g
				  WHERE g.num = @ISINCode
			  );

			  

WAITFOR DELAY '00:00:01'; -- Пауза на 1 секунду











end

else 

begin





UPDATE c

SET 

    KIND = ISNULL(

        CASE 

            WHEN R.COUNTRY COLLATE SQL_Latin1_General_CP1_CI_AS NOT IN ('Armenia') THEN 4  -- depolite(not Armenia securities)

            WHEN r.AssetClass_Const IN (6) AND r.AssetSort_Const IN (3) THEN 2 -- Depolie(MinFin)

            WHEN r.AssetClass_Const IN (6) AND r.AssetSort_Const NOT IN (3) THEN 3 -- Depolie(CorpBonds)

            ELSE 5 -- Depolite (other)

        END, 

        c.KIND

    ),

    TYPE = ISNULL(

        CASE 

            WHEN r.AssetClass_Const IN (18) THEN 5

            WHEN r.AssetClass_Const IN (16) THEN 6

            WHEN r.AssetClass_Const IN (6, 7, 9) AND r.IsCouponed = 'n' THEN 1

            WHEN r.AssetClass_Const IN (6, 7, 9) AND r.IsCouponed = 'y' THEN 2

            WHEN r.AssetClass_Const IN (8, 5) AND r.AssetSort_Const IN (1) THEN 3

            WHEN r.AssetClass_Const IN (8, 5) AND r.AssetSort_Const IN (2, 78) THEN 4

            ELSE 8

        END, 

        c.TYPE

    ),

    MINAMNT = ISNULL(r.BaseValue, c.MINAMNT),

    SCUR = ISNULL(fi.Name, c.scur),

		OPENDATE = ISNULL(
			CONVERT(DATETIME, CONVERT(VARCHAR(8), IIF(r.EmitDate = 0, '19000101', r.EmitDate), 112)), 
			c.OPENDATE
		),
		CLOSEDATE = ISNULL(
			CONVERT(DATETIME, CONVERT(VARCHAR(8), IIF(r.CancelDate = 0, '19000101', r.CancelDate), 112)), 
	
		c.CLOSEDATE
		),

    YRATE = ISNULL(cou.Procent, c.YRATE)

FROM [192.168.13.8].[Depositary].[dbo].[SECURKIND] c

JOIN QORT_BACK_DB.dbo.Assets r

    ON c.num = r.ISIN COLLATE SQL_Latin1_General_CP1_CI_AS 

    AND r.Enabled = 0 

    AND r.IsTrading = 'y'

LEFT OUTER JOIN QORT_BACK_DB.dbo.Assets fi 

    ON fi.id = r.BaseCurrencyAsset_ID

LEFT OUTER JOIN QORT_BACK_DB.dbo.Coupons cou 

    ON cou.Asset_ID = r.ID 

    AND cou.id <> cou.Enabled 

    AND cou.IsCanceled = 'n' 

    AND cou.BeginDate <= @todayInt 

    AND cou.EndDate > @todayInt

WHERE c.NUM = @ISINCode;



--and r.EmitCode = 1;















end

	end try

	begin catch

		while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		print @Message

		select @Message Result, 'red' ResultColor

	end catch

	REVERT;

END;
