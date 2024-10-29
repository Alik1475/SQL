



-- exec QORT_ARM_SUPPORT_TEST..uploadGTN







CREATE PROCEDURE [dbo].[uploadGTN]

	

AS



BEGIN



	begin try

		declare @FilePath varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\GTN'

		declare @Sheet varchar(16) 

		if right(@FilePath, 1) <> '\' set @FilePath = @FilePath + '\'

		declare @HistPath varchar(255) = @FilePath + 'history\'

		declare @InfoSource varchar(64) = object_name(@@procid)

		declare @TodayDate date = getdate()

		declare @TodayDateInt int = cast(convert(varchar, @TodayDate, 112) as int)

		declare @Message varchar(1024)

		declare @aid int = 0

		declare @n int = 0

		declare @WaitCount int

		declare @rowsInFile int

		declare @rowsNew int

		declare @rowsDone int

		declare @rowsError int

		declare @CheckDate as varchar(16)

		declare @CheckDateInt int 

		DECLARE @FileCount INT

		SET NOCOUNT ON







		declare @cmd varchar(255)

		declare @sql varchar(1024)

	

		set @cmd = 'md "' + @HistPath + '"'

		exec master.dbo.xp_cmdshell @cmd, no_output



		-----------------Список файлов в папке.

			declare @files table (fileId int identity, filename nvarchar(max));

		set @cmd = 'dir /b "'+@FilePath+'*.TXT*"'

		insert into @files(filename) exec master..xp_cmdshell @cmd--, no_output

		/*

		declare @files table (fileId int identity, filename nvarchar(max));

		set @cmd = 'dir /b "'+@FilePath+'*.xls*"'

		PRINT @CMD --RETURN

		insert into @files(filename) exec master..xp_cmdshell @cmd, no_output

		*/

		SELECT * FROM @files

		DELETE FROM @files WHERE filename IS NULL 

	

				-- Проверка, есть ли файлы
SELECT @FileCount = COUNT(*) FROM @files WHERE filename IS NOT NULL and filename not in('File Not Found')

-- Если файлы найдены, продолжаем выполнение
IF @FileCount > 0

begin	

		SELECT * FROM @FILES 

		declare @FileId int = 0

		declare @FileName varchar(255)

		declare @NewFileName varchar(255)

/*		-- Подсчёт количества файлов
SET @cmd = 'dir /b "' + @filePath + '*.xls*"';
INSERT INTO @files(filename) 
EXEC master.dbo.xp_cmdshell @cmd;
*/


		select top 1 @FileId = f.fileId, @FileName = f.filename

		from @files f

		where f.fileId > @FileId AND filename IS NOT NULL 

		SET @rowsInFile = (SELECT MAX(fileId) FROM @FILES)

		

		while (@rowsInFile > 0)

	

	begin

		select @FileName = f.filename

		from @files f

		where f.fileId = @rowsInFile

			print @FileName



 
    DECLARE @Command NVARCHAR(MAX);
	
	DECLARE @FolderPath NVARCHAR(MAX) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\GTN';
    DECLARE @Table TABLE (FileName NVARCHAR(255));
	DECLARE @PowerShellCommand VARCHAR(4000);
    DECLARE @TempFilePath NVAR
CHAR(255);
	IF OBJECT_ID('tempdb..#Transactions', 'U') IS NOT NULL DROP TABLE #Transactions



    -- Получаем первый файл из списка
    SEt @FilePath = @FolderPath + '\' + @FileName
   
	--set @FilePath = 'C:\Path\To\your\output_file.txt'
    -- Проверка
, найден ли файл

   IF @FilePath IS NOT NULL
   BEGIN
        -- Создание временной таблицы
        CREATE TABLE #Transactions
        (
            DateGMT NVARCHAR(50),
            DateLocal NVARCHAR(50),
            Institution NVARCHAR(50),
         
   OrderID NVARCHAR(50),
            CustomerNo NVARCHAR(50),
            CustExtRefNo NVARCHAR(50),
            GroupType NVARCHAR(50),
            CashAccountRef NVARCHAR(50),
            Symbol NVARCHAR(10),
            Exchange NVARCHAR(10),
         
   Side NVARCHAR(20),
            Statement NVARCHAR(20),
            NetHoldings DECIMAL(18, 2),
            NetSettle DECIMAL(18, 2),
            CumHoldings DECIMAL(18, 2),
            AvgCost DECIMAL(18, 2),
            SellPending DECIMAL(18, 2),
   
         BuyPending DECIMAL(18, 2),
            PledgedQty DECIMAL(18, 2),
            CustomerName NVARCHAR(100),
            SequenceNo NVARCHAR(50),
            Narration NVARCHAR(255),
            EligibleShares DECIMAL(18, 2),
            MubasherOmn
ibus NVARCHAR(10)
        );

        -- Проверка существования файла и корректности пути
       IF OBJECT_ID('tempdb..#Transactions') IS NOT NULL
       BEGIN
DECLARE @ScriptPath NVARCHAR(255) = N'C:\Path\To\your\RemoveQuotes.ps1';
DECLARE @InputFilePath
 NVARCHAR(255) = N'C:\Path\To\your\file.txt';
DECLARE @OutputFilePath NVARCHAR(255) = N'C:\Path\To\your\output_file.txt';

-- Формируем команду для запуска PowerShell-скрипта с параметрами
SET @PowerShellCommand = N'powershell -Command "Copy-Item -Path ''
' + @FilePath + ''' -Destination ''' + @InputFilePath + ''' -Force"';

EXEC xp_cmdshell @PowerShellCommand;

SET @PowerShellCommand = N'powershell -ExecutionPolicy Bypass -File "' + @ScriptPath-- + '" -InputFilePath "' + @InputFilePath + '" -OutputFilePat
h "' + @OutputFilePath + '"';

EXEC xp_cmdshell @PowerShellCommand;

            SET @Command = '
                BULK INSERT #Transactions
                FROM ''' + @OutputFilePath + '''
                WITH 
                (
                    FIELDT
ERMINATOR = '','',  -- Разделитель полей
                    ROWTERMINATOR = ''0x0d0a'', -- Разделитель строк (Windows формат)
                    FIRSTROW = 2,             -- Пропускаем заголовок
                    CODEPAGE = ''65001'',     -- Кодировка
 UTF-8
                    TABLOCK
                );';
--0x0d0a
            BEGIN TRY
                EXEC sp_executesql @Command;
                PRINT 'Data successfully loaded into temporary table from file: ' + @FilePath;

                -- Здесь мо
жно выполнить дальнейшую обработку данных из временной таблицы #Transactions

            END TRY
            BEGIN CATCH
                PRINT 'Error occurred: ' + ERROR_MESSAGE();
            END CATCH;
        END
    END
    ELSE
    BEGIN
        PRI
NT 'No CSV or TXT file found in the specified folder.';
    END
	

	select * from #Transactions

	ALTER TABLE #Transactions
	ADD ConvertedDate int, ConvertedTime int; 



	 delete #Transactions where Side not in ('Buy','Sell') or Statement is null

		
		UPDATE #Transactions

		SET ConvertedDate = CONVERT(INT, CONVERT(VARCHAR,dbo.fGetBusinessDay(CONVERT(DATETIME, DateGMT, 103), 0), 112)),
			ConvertedTime = CAST(
						RIGHT('0' + CAST(DATEPART(HOUR, DATEADD(HOUR, 4, CONVERT(DATETIME, DateGMT, 103)))
 AS VARCHAR), 2) + 
						RIGHT('0' + CAST(DATEPART(MINUTE, DATEADD(HOUR, 4, CONVERT(DATETIME, DateGMT, 103))) AS VARCHAR), 2) + 
						RIGHT('0' + CAST(DATEPART(SECOND, DATEADD(HOUR, 4, CONVERT(DATETIME, DateGMT, 103))) AS VARCHAR), 2) + 
						RIGHT('00
' + CAST(DATEPART(MILLISECOND, DATEADD(HOUR, 4, CONVERT(DATETIME, DateGMT, 103))) AS VARCHAR), 3)
					AS INT)

		



			select * from #Transactions

			----------------------добавление инструмента НА ПЛОЩАДКУ ОТС РЕПО ЕСЛИ НЕТ--------------------------

			--/*

			insert into QORT_BACK_TDB_UAT.dbo.Securities (

			IsProcessed, ET_Const, ShortName

			, Name, TSSection_Name, SecCode

			, Asset_ShortName, QuoteList, IsProcent

			, LotSize, IsTrading, Lot_multiplicity

			, Scale

			--, CurrPriceAsset_ShortName

		) 

		--*/

		SELECT DISTINCT

		1 as IsProcessed, 2 as ET_Const

			, tt.shortname

			, tt.ISIN Name

			, tss.Name as TSSection_Name

			, tt.ISIN  secCode

			, tt.ShortName Asset_ShortName

			, 1 QuoteList

			, iif(tt.AssetSort_Const in (6,3), 'y', NULL) IsProcent

			, 1 LotSize

			, 'y' IsTrading

			, 1 lot_multiplicity

			, 8 Scale

			--, B.ShortName CurrPriceAsset_ShortName

		--into #t10 

		FROM #Transactions ttt 

		left outer join QORT_BACK_DB_UAT.dbo.TSSections tss on tss.BONumPref = left(ttt.Exchange, 4)

				outer apply (select AssetSort_Const, Enabled,id, ISIN,  ass.ShortName as ShortName from QORT_BACK_DB_UAT.dbo.Assets Ass

					where left(ass.viewName, len(ttt.symbol)) = ttt.symbol) as tt



		where tt.Enabled = 0 

				and tt.id is not null

		 and NOT EXISTS (

				select TOP 1 *

				from QORT_BACK_DB_UAT.dbo.Securities a

				where a.Asset_ID = tt.id and tt.Enabled = 0 

				and a.TSSection_ID = tss.id

			)

			--select * from #t10-- return

			

		set @WaitCount = 1200 -------------------- задержка, не продолжаем пока не подгрузили бумаги----------------------

		while (@WaitCount > 0 and exists (select top 1 1 from QORT_BACK_TDB_UAT.dbo.Securities q with (nolock) where q.IsProcessed in (1,2)))

		begin

			waitfor delay '00:00:03'

			set @WaitCount = @WaitCount - 1

		end

			select row_number() over(order by SequenceNo) rn

			   , t.ConvertedDate AS TradeDate

			   , t.ConvertedTime AS TimeInt

				, null as SubAcc

				, t.Narration AddComment

				, tt.SecCode Security_Code

				, abs(t.NetHoldings) Qty

				, 'USD' CurrPriceAsset_ShortName

				, CONVERT(FLOAT, 
						REVERSE(SUBSTRING(REVERSE(t.Narration), 1, CHARINDEX('@', REVERSE(t.Narration)) - 1))) * abs(t.NetHoldings) Volume

				, CONVERT(FLOAT, 
						REVERSE(SUBSTRING(REVERSE(t.Narration), 1, CHARINDEX('@', REVERSE(t.Narration)) - 1))) Price

				, t.Side BUY_sell

				, t.OrderID OrderID

				, t.SequenceNo Ref

				, CONVERT(INT, CONVERT(VARCHAR,dbo.fGetBusinessDay(CONVERT(DATETIME, T.DateGMT, 103), 1), 112)) AS PutPlannedDate

				, t.ConvertedTime AS TimeIntUpdate

				, t.Exchange PutAccount_ExportCode

				, tss.Name TSSection_Name

			into #comms

			from #Transactions t

			left outer join QORT_BACK_DB_UAT.dbo.TSSections tss on tss.BONumPref = left(t.Exchange, 4)

				outer apply (select sec.SecCode as SecCode from QORT_BACK_DB_UAT.dbo.Assets Ass

					left outer join QORT_BACK_DB_UAT.dbo.Securities sec on Sec.Asset_ID = Ass.id and sec.TSSection_ID = tss.id

					where left(ass.viewName, len(t.symbol)) = t.symbol) as tt

		



			select * from #comms 

			--return

----------------------- формирование сделОК в Корт---------------------------------------------------



		set @n = (select max(rn) from #comms) 

			

				while @n > 0

	begin



				set @WaitCount = 1200 -------------------- задержка, не передаем в ТДБ сделку, пока предыдущая не закончила грузиться----------------------

		while (@WaitCount > 0 and exists (select top 1 1 from QORT_BACK_TDB_UAT.dbo.ImportTrades t with (nolock) where t.IsProcessed in (1,2)))

		begin

			waitfor delay '00:00:03'

			set @WaitCount = @WaitCount - 1

		end

		

--/*

		insert into QORT_BACK_TDB_UAT.dbo.ImportTrades (

			IsProcessed, ET_Const, IsDraft

			, TradeDate, TradeTime, TSSection_Name

			, BuySell, Security_Code, Qty, Price

			, Volume1

			, CurrPriceAsset_ShortName, PutPlannedDate, PayPlannedDate

			, PutAccount_ExportCode, PayAccount_ExportCode, SubAcc_Code

			, AgreeNum

			, TT_Const

			, AddComment

			--, AgreePlannedDate, Accruedint

			--, TraderUser_ID, SalesManager_ID

			, PT_Const

			--, TSCommission, IsAccrued

			, IsSynchronize

			--, CpSubacc_Code

			--, SS_Const

			, FunctionType

			, CurrPayAsset_ShortName

			, TradeNum

			, OrdExchCode

			, CpFirm_BOCode

		) 

--*/		

			select 1 as IsProcessed, 2 as ET_Const, 'y' as IsDraft

			, TradeDate as TradeDate

			, TimeInt TradeTime

			, TSSection_Name as TSSection_Name

			, iif(BUY_sell = 'Sell', 2, 1) as BuySell

			, Security_Code as Security_Code

			, Qty as Qty

			, Price as Price

			, Volume as Volume

			, CurrPriceAsset_ShortName as CurrPriceAsset_ShortName

			, PutPlannedDate PutPlannedDate

			, PutPlannedDate PayPlannedDate

			, 'ARMBR_DEPO_GTN' PutAccount_ExportCode

			, 'Armbrok_Mn_Client' PayAccount_ExportCode

			, SubAcc as SubAcc_Code

			, OrderID AgreeNum

			, 7 as TT_Const --TT_M_FORWARD(Exchange forward)

			, AddComment as AddComment

			--, AgreePlannedDate, Accruedint

			--, TraderUser_ID, SalesManager_ID

			, 2 as PT_Const

			--, TSCommission, IsAccrued

			, 'n' IsSynchronize

			--, 'ARMBR_Subacc' as CpSubacc_Code

			--, SS_Const

			, 0 as FunctionType

			, CurrPriceAsset_ShortName as CurrPayAsset_ShortName

			--, right(replace(replace(replace(replace(convert(varchar, getdate(),121), ':', ''), '-', ''), ' ', ''), '.', ''),15) TradeNum

			, cast((cast(isnull((select max(ID) from QORT_BACK_DB_UAT.dbo.Trades with (nolock))+1,0) as varchar(8))) as int) TradeNum

			, Ref as OrdExchCode

			, '19915' CpFirm_BOCode --GTN Middle East Financial Services

			

			from #comms

			where rn = @n



			set @n = @n - 1



		end	

		

--/*



					-- весь файл обработан, надо переложить в history

			select @NewFileName = convert(varchar, getdate(), 112) + '_' + replace(convert(varchar, getdate(), 108), ':','-') + '_' + @FileName

			set @cmd = 'move "' + @FilePath + '" "' + @HistPath + @NewFileName + '"'

			exec master.dbo.xp_cmdshell @cmd, no_output

			------ очищаем содержимое промежуточного файлаЮ чтобы второй раз не грузить-----

			SET @PowerShellCommand = 'powershell -Command "Clear-Content -Path ''' + @OutputFilePath + '''"';

			EXEC xp_cmdshell @PowerShellCommand;





			SET @rowsInFile = @rowsInFile - 1

			PRINT @rowsInFile

--*/

		end



	end

	ELSE
BEGIN
    PRINT 'No files found';
END;

			

	end try

	begin catch

		while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE() + ISNULL(', ' + @FileName, '');  

		if @message not like '%12345 Cannot initialize the data source%' insert into QORT_ARM_SUPPORT_TEST.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		print @Message

	end catch



END
