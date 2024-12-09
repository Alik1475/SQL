﻿









-- exec QORT_ARM_SUPPORT.dbo.LoadSecurDepolite @ISINCode = 'XS1791937441'





CREATE PROCEDURE [dbo].[LoadSecurDepolite]

	

   @ISINCode varchar(16)



AS



BEGIN

EXECUTE AS LOGIN = 'aleksandr.mironov';

	begin try



		declare @todayDate date = getdate()

		declare @todayInt int = cast(convert(varchar, @todayDate, 112) as int)

		declare @Message varchar(1024) -- для уведомлений об ошибках



IF not EXISTS (

    SELECT 1

    FROM [192.168.13.8].[Depositary].[dbo].[SECURKIND] g

    WHERE g.NUM = @ISINCode

)

BEGIN

return



/*

		INSERT INTO [192.168.13.8].[Depositary].[dbo].[SECURKIND] (

    EXTNUM, PERSON, TRUSTED, IsBENEFIC, IsBROKER,

    ISDEPOS, RESIDENCE, SECTOR, NAME_A, SNAME_A, FNAME_A,

    NAME_E, NAME_R, SEX, BIRTHDAY, BIRTHPLACE, COUNTRY,

    REGION, ADDRESS_A, ADDRESS_E, ADDRESS_R, SADDRESS_A,

    SADDRESS_E, SOCCART, TAXPAYER, REGNUM, ORGTYPE, ORGNAME,

    DOCSRC, DOCDATE, DOCUMENT, DOCISSUDT, DrLicNum, DrClass,

    DrLicOflssue, DrLicExpire, Experience, ODOCSRC, ODOCUMENT,

    ODOCDATE, ODOCISSUDT, PHONE, MOBILE, FAX, ZIP, EMAIL,

    WORKPLACE, WORKER, WORKER_E, WORKER_R, WORKPOST, WORKPOST_E,

    WORKPOST_R, LICENCEDATE, LICENCENUM, OPENDATE, BRANCH,

    FULLKIND, KINDNUM, REGNUM2, TSOWNER, TSUSER, TSTIME,

    BROKER, PASWORD, SNAME_E, FNAME_E, WEBSIT, CITY, Build,

    AptNum, SREGION, SCITY, SBuild, SAptNum, CONTDATE,

    CONTNUM, DROPEN, PAYKIND, DEDTIME, DEDNUM

)

--*//*

SELECT 

    '' as EXTNUM

	, iif(f.isfirm = 'y', 2 , 3) as  PERSON

	,0 as TRUSTED

	, 1 as IsBENEFIC

	, 0 as IsBROKER

	, 0 as ISDEPOS

	, iif(f.IsResident = 'y', 1, 0) as RESIDENCE

	, 99 SECTOR

	, f.name NAME_A

	, '' SNAME_A

	, '' FNAME_A

	, f.name NAME_E

	, '' NAME_R

	, IIF(f.isfirm = 'y', 0, IIF(f.sex = 'n', 1 , 2))  SEX

	, null BIRTHDAY

	, null BIRTHPLACE

	, c.Code_Alfa_3 COUNTRY

	, 'NN' REGION

	,ISNULL( pro.AddrJuSettlementU, '') as ADDRESS_A

	, f.LatAddrJu as ADDRESS_E

	,'' ADDRESS_R

	, f.LatAddrJu SADDRESS_A

	, f.LatAddrJu SADDRESS_E

	, null SOCCART

	, null TAXPAYER

	, f.IDocNum REGNUM

	, null ORGTYPE

	, '' ORGNAME

	, null DOCSRC

	, null DOCDATE

	, null DOCUMENT

	, null DOCISSUDT

	, null DrLicNum

	, null DrClass

	, 0 DrLicOflssue

	, 0 DrLicExpire

	, null Experience

	, null ODOCSRC

	, null ODOCUMENT

	, null ODOCDATE

	, null ODOCISSUDT

	, null PHONE

	, null MOBILE

	, null FAX

	, null ZIP

	, null EMAIL

	, null WORKPLACE

	, null WORKER

	, null WORKER_E

	, null WORKER_R

	, null WORKPOST

	, null WORKPOST_E

	, null WORKPOST_R

	, null LICENCEDATE

	, null LICENCENUM

	, null OPENDATE

	, 00 BRANCH

	, 1 FULLKIND

	, '' as KINDNUM

	, null REGNUM2

	, null TSOWNER

	, 'qort' TSUSER

	, @todayDate TSTIME

	, null BROKER

	, null PASWORD

	, null SNAME_E

	, null FNAME_E

	, null WEBSIT

	, null CITY

	, null Build

	, null AptNum

	, null SREGION

	, null SCITY

	, null SBuild

	, null SAptNum

	, null CONTDATE

	, null CONTNUM

	, null DROPEN

	, 0 PAYKIND

	, null DEDTIME

	, @BOCode DEDNUM

FROM QORT_BACK_DB.dbo.Firms f

left outer join QORT_BACK_DB.dbo.FirmProperties pro on pro.Firm_ID = f.id

left outer join QORT_BACK_DB.dbo.Countries c on c.ID = f.Country_ID

WHERE f.BOCode = @BOCode

and not EXISTS (

    SELECT 1

    FROM [192.168.13.8].[Depositary].[dbo].[CUSTOMER]  g

    WHERE g.DEDNUM = @BOCode

);



WAITFOR DELAY '00:00:01'; -- Пауза на 1 секунду



INSERT INTO [192.168.13.8].[Depositary].[dbo].[CUSTOPTION] ( CUST, CHARID, ISOPTION, BDATE, EDATE)

select

customer as CUST

,'IsBENEFIC' as CHARID

,  1 as ISOPTION

, null BDATE

, null EDATE

from [192.168.13.8].[Depositary].[dbo].[CUSTOMER] 

where DEDNUM = @BOCode

and not EXISTS (

    SELECT 1

    FROM [192.168.13.8].[Depositary].[dbo].[CUSTOPTION]  g

    WHERE g.ID = customer 

	and g.CHARID = 'IsBENEFIC'

);





insert into QORT_BACK_TDB..Firms (ET_Const, IsProcessed, BOCode, EmitCode)



select 4 as ET_Const, 1 as IsProcessed, @BOCode, customer as EmitCode

from [192.168.13.8].[Depositary].[dbo].[CUSTOMER] 

where DEDNUM = @BOCode

--*/

end

else begin





/*UPDATE c

SET 

*/

				select



						 (case WHEN R.COUNTRY COLLATE SQL_Latin1_General_CP1_CI_AS NOT IN ('Armenia') THEN 4 

							WHEN r.AssetClass_Const IN (6)   THEN  2

								              

								  ELSE 3

								  END) KIND

					,  (case  WHEN  r.AssetClass_Const IN (18) THEN 5

					WHEN r.AssetClass_Const IN (16) THEN 6

	                WHEN (r.AssetClass_Const IN (6, 7, 9) and r.IsCouponed = 'n') THEN 1

      

                    WHEN  (r.AssetClass_Const IN (6, 7, 9) and r.IsCouponed = 'y') THEN 2

               

                    WHEN (r.AssetClass_Const IN (8,5) and r.AssetSort_Const IN (1)) THEN 3

                    

                    WHEN  (r.AssetClass_Const IN (8,5) and r.AssetSort_Const IN (2)) THEN 4      

                 

				    WHEN r.AssetClass_Const IN (16) THEN 6

					else 8

					end) type

					

	,  r.BaseValue MINAMNT

	, fi.Name scur 







FROM [192.168.13.8].[Depositary].[dbo].[SECURKIND] c

JOIN QORT_BACK_DB.dbo.Assets r

ON c.num = r.ISIN COLLATE SQL_Latin1_General_CP1_CI_AS and Enabled = 0

left outer join QORT_BACK_DB.dbo.firms fi on fi.id = r.BaseCurrencyAsset_ID

WHERE c.NUM = @ISINCode

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
