
-- exec QORT_ARM_SUPPORT.dbo.FATCA_EXPORT_XML

CREATE PROCEDURE [dbo].[FATCA_EXPORT_XML]

AS

BEGIN

    SET NOCOUNT ON;



    BEGIN TRY



        -- Объявление переменных



	declare @Message varchar(1024) = ''

	-- Создание таблицы

/*	





  IF OBJECT_ID('QORT_ARM_SUPPORT.dbo.Clients', 'U') IS NOT NULL

    DROP TABLE QORT_ARM_SUPPORT.dbo.Clients;



  

  select s.id as ClientID,
  iif(firm.isfirm = 'n', LEFT(firm.name, CHARINDEX(' ', firm.name + ' ') - 1), '') AS LastName,
    iif(firm.isfirm = 'n', STUFF(firm.name, 1, CHARINDEX(' ', firm.name + ' '), ''), '') AS FirstName

	, iif(firm.isfirm = 'y', firm.name, '') AS CompanyName

	, firm.Country as Country

	, firm.ITN as TIN

	, firm.street as street

	, firm.BuildingIdentifier as BuildingIdentifier

	, firm.PostCode as PostCode

	, firm.nameC City

	, firm.CountrySubentity CountrySubentity

	, s.SubAccCode AccountNumber

	, 0 as AccountBalance

	, 0 as PaymentAmount

	, firm.isFirm IsFirm



  into QORT_ARM_SUPPORT.dbo.Clients

  from QORT_BACK_DB.dbo.Subaccs s

  left outer join QORT_BACK_DB.dbo.ClientAgrees ag on ag.SubAcc_ID = s.id and ag.Enabled = 0

  outer apply (select f.FATCA_Const AS FATCA_Const, f.ITNNumber ITN, f.Name as name, cit.Name nameC, f.FT_Flags FT_Flags, f.IsFirm isFirm

					, cou.CodeISO_1 Country, f.AddrJuStreet street, f.AddrJuHouse as BuildingIdentifier, f.AddrJuIndex as PostCode, reg.Name CountrySubentity

	from QORT_BACK_DB.dbo.Firms f 

	left outer join QORT_BACK_DB.dbo.Cities cit on cit.id = f.AddrJuCity_ID

	left outer join QORT_BACK_DB.dbo.Countries cou on cou.id = f.Country_ID

	left outer join QORT_BACK_DB.dbo.Regions reg on reg.id = f.AddrJuRegion_ID

	where f.id = s.OwnerFirm_ID

	) as firm

  where firm.FATCA_Const in (1)-- US-person

	and s.Enabled = 0

	and (ag.DateSign < 20241231 and ag.DateSign > 0)

	and firm.ITN <> ''

 and exists (SELECT FlagName

FROM dbo.FTGetIncludedFlags(firm.FT_Flags)

WHERE FlagName = 'FT_CLIENT') -- Фильтруем по конкретному флагу, например, FT_CLIENT



DECLARE @AccountNumber NVARCHAR(50);
DECLARE @OutputParam1 FLOAT;
DECLARE @OutputParam2 FLOAT;

-- Создаем курсор для перебора всех аккаунтов
DECLARE cur CURSOR FOR 
SELECT AccountNumber FROM QORT_ARM_SUPPORT.dbo.Clients;

OPEN cur;
FETCH NEXT FROM cur IN
TO @AccountNumber;

WHILE @@FETCH_STATUS = 0
BEGIN
    -- Вызываем хранимую процедуру для каждого аккаунта
    EXEC QORT_ARM_SUPPORT.dbo.ReportTurnOverAMDCompliance 
        @DataFrom = '2024-01-01', 
        @DataTo = '2024-12-31', 
        @SubAccCode =
 @AccountNumber, 
        @OutputParam = @OutputParam1 OUTPUT,
        @OutputParamCL = @OutputParam2 OUTPUT;

		    UPDATE clients
    SET  PaymentAmount = @OutputParam2
    WHERE AccountNumber = @AccountNumber;

	EXEC QORT_ARM_SUPPORT.dbo.ReportTurnOver
AMDCompliance 
        @DataFrom = '2024-12-31', 
        @DataTo = '2024-12-31', 
        @SubAccCode = @AccountNumber, 
        @OutputParam = @OutputParam1 OUTPUT,
        @OutputParamCL = @OutputParam2 OUTPUT;

    -- Обновляем таблицу по `AccountNumb
er`
    UPDATE clients
    SET AccountBalance = @OutputParam2
    WHERE AccountNumber = @AccountNumber;

    -- Следующая итерация
    FETCH NEXT FROM cur INTO @AccountNumber;
END;

CLOSE cur;
DEALLOCATE cur;







/*

--------------------------------for test only - delete after finished-----------------------



drop TABLE Clients

CREATE TABLE Clients (

    ClientID INT PRIMARY KEY,

    FirstName NVARCHAR(100),

    LastName NVARCHAR(100),

    CompanyName NVARCHAR(255),

    Country NVARCHAR(10),

    TIN NVARCHAR(20),

    Street NVARCHAR(255),

    BuildingIdentifier NVARCHAR(100),

    PostCode NVARCHAR(20),

    City NVARCHAR(100),

    CountrySubentity NVARCHAR(100),

    AccountNumber NVARCHAR(50),

    AccountBalance DECIMAL(18,2),

    PaymentAmount DECIMAL(18,2)

);



-- Вставка случайных данных

INSERT INTO Clients (ClientID, FirstName, LastName, CompanyName, Country, TIN, Street, BuildingIdentifier, PostCode, City, CountrySubentity, AccountNumber, AccountBalance, PaymentAmount)

VALUES

(1, 

    'John', 

    'Doe', 

    'Doe Enterprises', 

    'US', 

    '123-45-6789', 

    'Main St', 

    '101', 

    '90210', 

    'Los Angeles', 

    'California', 

    'ACC1234567', 

    ROUND(RAND() * 1000000, 2), 

    ROUND(RAND() * 1000000, 2)

),

(2, 

    'Jane', 

    'Smith', 

    'Smith LLC', 

    'US', 

    '987-65-4321', 

    'Oak Rd', 

    '202', 

    '12345', 

    'New York', 

    'New York', 

    'ACC2345678', 

    ROUND(RAND() * 1000000, 2), 

    ROUND(RAND() * 1000000, 2)

),

(3, 

    'Alice', 

    'Johnson', 

    'Johnson Corp', 

    'CA', 

    '321-54-9876', 

    'Pine Ave', 

    '303', 

    '67890', 

    'Toronto', 

    'Ontario', 

    'ACC3456789', 

    ROUND(RAND() * 1000000, 2), 

    ROUND(RAND() * 1000000, 2)

),

(4, 

    'Bob', 

    'Williams', 

    'Williams Ltd', 

    'UK', 

    '111-22-3333', 

    'Elm St', 

    '404', 

    '54321', 

    'London', 

    'England', 

    'ACC4567890', 

    ROUND(RAND() * 1000000, 2), 

    ROUND(RAND() * 1000000, 2)

),

(5, 

    'Charlie', 

    'Brown', 

    'Brown Solutions', 

    'AU', 

    '555-66-7777', 

    'Cedar Dr', 

    '505', 

    '23456', 

    'Sydney', 

    'New South Wales', 

    'ACC5678901', 

    ROUND(RAND() * 1000000, 2), 

    ROUND(RAND() * 1000000, 2)

);

*/

-- ----------------------------------------------------------------------------------------------------------------------------------------------------

*/

--select * from Clients return



-- Start XML structure

IF OBJECT_ID('dbo.FATCA_XML_EXPORT', 'U') IS NOT NULL

    DROP TABLE dbo.FATCA_XML_EXPORT;



CREATE TABLE dbo.FATCA_XML_EXPORT (

    XMLData NVARCHAR(MAX)

);

DECLARE @Timestamp VARCHAR(19);  

SET @Timestamp = FORMAT(GETDATE(), 'yyyy-MM-ddTHH:mm:ss');  







-- 2️⃣ Генерация XML (пример для 3 строк)

DECLARE @XML NVARCHAR(MAX);



SET @XML = (
'<?xml version="1.0" encoding="UTF-8"?>' + 
'<ftc:FATCA_OECD xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="urn:oecd:ties:fatca:v2" xmlns:iso="urn:oecd:ties:isofatcatypes:v1" xmlns:ftc="urn:oecd:ties:fatca:v2" xmln
s:stf="urn:oecd:ties:stf:v4" xmlns:sfa="urn:oecd:ties:stffatcatypes:v2" version="2.0">' +
    '<ftc:MessageSpec>' +
        '<sfa:SendingCompanyIN>L0HSDF.99999.SL.051</sfa:SendingCompanyIN>' +
        '<sfa:TransmittingCountry>AM</sfa:TransmittingCountry>
' +
        '<sfa:ReceivingCountry>US</sfa:ReceivingCountry>' +
        '<sfa:MessageType>FATCA</sfa:MessageType>' +
        '<sfa:MessageRefId>' + CAST(NEWID() AS NVARCHAR(36)) + '</sfa:MessageRefId>' +
        '<sfa:ReportingPeriod>2024-12-31</sfa:Repor
tingPeriod>' +
        '<sfa:Timestamp>' + @Timestamp + '</sfa:Timestamp>' +
    '</ftc:MessageSpec>' +
    '<ftc:FATCA>' +
	'<ftc:ReportingFI>

		<sfa:ResCountryCode>AM</sfa:ResCountryCode>

		<sfa:TIN/>

		<sfa:Name>ARMBROK open joint stock company</sfa:Name>

		<sfa:Address>

		<sfa:CountryCode>AM</sfa:CountryCode>

		<sfa:AddressFix>

		<sfa:Street>Hanrapetutyan</sfa:Street>

		<sfa:BuildingIdentifier>39</sfa:BuildingIdentifier>

		<sfa:PostCode>0010</sfa:PostCode>

		<sfa:City>Yerevan</sfa:City>

		</sfa:AddressFix>

		</sfa:Address>

		<ftc:FilerCategory>FATCA604</ftc:FilerCategory>

		<ftc:DocSpec>

		<ftc:DocTypeIndic>FATCA1</ftc:DocTypeIndic>

		<ftc:DocRefId>L0HSDF.99999.SL.051.' + CAST(NEWID() AS NVARCHAR(36)) + '</ftc:DocRefId>

		</ftc:DocSpec>

		</ftc:ReportingFI>'+
    '<ftc:ReportingGroup>' +
        (

            SELECT 

                '<ftc:AccountReport>' + 

                    '<ftc:DocSpec>' + 

                        '<ftc:DocTypeIndic>FATCA1</ftc:DocTypeIndic>' + 

                        '<ftc:DocRefId>L0HSDF.99999.SL.051.' + CAST(NEWID() AS NVARCHAR(36)) + '</ftc:DocRefId>' + 

                    '</ftc:DocSpec>' + 

                    '<ftc:AccountNumber>' + AccountNumber + '</ftc:AccountNumber>' + 

                    '<ftc:AccountClosed>false</ftc:AccountClosed>' + 

                    '<ftc:AccountHolder>' + 

                        '<ftc:Organisation>' + 

                            '<sfa:ResCountryCode>' + Country + '</sfa:ResCountryCode>' + 

                            '<sfa:TIN issuedBy="' + Country + '">' + TIN + '</sfa:TIN>' + 

                            '<sfa:Name>' + CompanyName + '</sfa:Name>' + 

                            '<sfa:Address>' + 

                                '<sfa:CountryCode>' + Country + '</sfa:CountryCode>' + 

                                '<sfa:AddressFix>' + 

                                    '<sfa:Street>' + Street + '</sfa:Street>' + 

                                    '<sfa:BuildingIdentifier>' + BuildingIdentifier + '</sfa:BuildingIdentifier>' + 

                                    '<sfa:PostCode>' + PostCode + '</sfa:PostCode>' + 

                                    '<sfa:City>' + City + '</sfa:City>' + 

                                    '<sfa:CountrySubentity>' + CountrySubentity + '</sfa:CountrySubentity>' + 

                                '</sfa:AddressFix>' + 

                            '</sfa:Address>' + 

                        '</ftc:Organisation>' + 

                        '<ftc:AcctHolderType>FATCA104</ftc:AcctHolderType>' + 

                    '</ftc:AccountHolder>' + 

                    '<ftc:AccountBalance currCode="USD">' + CAST(AccountBalance AS NVARCHAR(18)) + '</ftc:AccountBalance>' + 

                    '<ftc:Payment>' + 

                        '<ftc:Type>FATCA503</ftc:Type>' + 

                        '<ftc:PaymentAmnt currCode="USD">' + CAST(PaymentAmount AS NVARCHAR(18)) + '</ftc:PaymentAmnt>' + 

                    '</ftc:Payment>' + 

                '</ftc:AccountReport>'

            FROM Clients

            FOR XML PATH(''), TYPE

        ).value('.', 'NVARCHAR(MAX)') +

        '</ftc:ReportingGroup>' +

        '</ftc:FATCA>' +

        '</ftc:FATCA_OECD>'

);






-- 3️⃣ Очищаем таблицу и добавляем XML в таблицу

TRUNCATE TABLE dbo.FATCA_XML_EXPORT;

INSERT INTO dbo.FATCA_XML_EXPORT (XMLData) VALUES (@XML);



-- 4️⃣ Выгружаем данные в файл (замените путь!)

EXEC xp_cmdshell 'bcp "SELECT XMLData FROM QORT_ARM_SUPPORT.dbo.FATCA_XML_EXPORT" queryout "C:\Path\L0HSDF.99999.SL.051_Payload.xml" -c -T -S 192.168.14.20 -w';





    END TRY

    BEGIN CATCH

        -- Обработка ошибок

        WHILE @@TRANCOUNT > 0 ROLLBACK TRAN;

        SET @Message = 'ERROR: ' + ERROR_MESSAGE(); 

        -- Логирование ошибки

        INSERT INTO QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) VALUES (@Message, 1001);

        -- Вывод ошибки

        SELECT @Message AS result, 'STATUS' AS defaultTask, 'red' AS color;

    END CATCH



END;

