

-- exec QORT_ARM_SUPPORT..uploadGTN

CREATE PROCEDURE [dbo].[uploadGTN]

AS

BEGIN

	SET NOCOUNT ON



	BEGIN TRY

		DECLARE @FilePath VARCHAR(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\GTN'



		IF right(@FilePath, 1) <> '\'

			SET @FilePath = @FilePath + '\'



		DECLARE @HistPath VARCHAR(255) = @FilePath + 'history\'

			,@InfoSource VARCHAR(64) = object_name(@@procid)

		DECLARE @TodayDate DATE = getdate()

		DECLARE @TodayDateInt INT = cast(convert(VARCHAR, @TodayDate, 112) AS INT)

		DECLARE @Message VARCHAR(1024)

		DECLARE @n INT = 0

		DECLARE @WaitCount INT

		DECLARE @rowsInFile INT

		DECLARE @CheckDate AS VARCHAR(16)

		DECLARE @CheckDateInt INT

		DECLARE @FileCount INT

		DECLARE @cmd VARCHAR(255)



		SET @cmd = 'md "' + @HistPath + '"'



		EXEC master.dbo.xp_cmdshell @cmd

			,no_output



		-----------------Список файлов в папке.---------------------------

		DECLARE @files TABLE (

			fileId INT identity

			,filename NVARCHAR(max)

			);



		SET @cmd = 'dir /b "' + @FilePath + '*.TXT*"'



		INSERT INTO @files (filename)

		EXEC master..xp_cmdshell @cmd --, no_output



		SELECT *

		FROM @files



		DELETE

		FROM @files

		WHERE filename IS NULL



		-- Проверка, есть ли файлы

		SELECT @FileCount = COUNT(*)

		FROM @files

		WHERE filename IS NOT NULL

			AND filename NOT IN ('File Not Found')



		-- Если файлы найдены, продолжаем выполнение

		IF @FileCount > 0

		BEGIN

			SELECT *

			FROM @FILES



			DECLARE @FileId INT = 0

			DECLARE @FileName VARCHAR(255)

			DECLARE @NewFileName VARCHAR(255)



			-- Подсчёт количества файлов



			SELECT TOP 1 @FileId = f.fileId

				,@FileName = f.filename

			FROM @files f

			WHERE f.fileId > @FileId

				AND filename IS NOT NULL



			SET @rowsInFile = (

					SELECT MAX(fileId)

					FROM @FILES

					)



			WHILE (@rowsInFile > 0)

			BEGIN

				SELECT @FileName = f.filename

				FROM @files f

				WHERE f.fileId = @rowsInFile



				PRINT @FileName



				DECLARE @Command NVARCHAR(MAX);

				DECLARE @PowerShellCommand VARCHAR(4000);

				DECLARE @TempFilePath NVARCHAR(255);



				IF OBJECT_ID('tempdb..#Transactions', 'U') IS NOT NULL

					DROP TABLE #Transactions



				IF OBJECT_ID('tempdb..#comms', 'U') IS NOT NULL

					DROP TABLE #comms



				-- Получаем первый файл из списка

				SET @FilePath = @FilePath + '\' + @FileName



				--set @FilePath = 'C:\Path\To\your\output_file.txt'

				-- Проверка, найден ли файл

				IF @FilePath IS NOT NULL

				BEGIN

					-- Создание временной таблицы

					CREATE TABLE #Transactions (

						DateGMT VARCHAR(50)

						,DateLocal VARCHAR(50)

						,Institution NVARCHAR(50)

						,OrderID NVARCHAR(50)

						,CustomerNo NVARCHAR(50)

						,CustExtRefNo NVARCHAR(50)

						,GroupType NVARCHAR(50)

						,CashAccountRef NVARCHAR(50)

						,Symbol NVARCHAR(50)

						,Exchange NVARCHAR(10)

						,Side NVARCHAR(20)

						,Statement NVARCHAR(20)

						,NetHoldings NVARCHAR(20)

						,NetSettle NVARCHAR(20)

						,CumHoldings NVARCHAR(20)

						,AvgCost NVARCHAR(20)

						,SellPending NVARCHAR(20)

						,BuyPending NVARCHAR(20)

						,PledgedQty NVARCHAR(20)

						,CustomerName NVARCHAR(100)

						,SequenceNo NVARCHAR(50)

						,Narration NVARCHAR(255)

						,EligibleShares NVARCHAR(20)

						,MubasherOmnibus NVARCHAR(10)

						--, ConvertedDate int

						--, ConvertedTime int

						);



					-- Проверка существования файла и корректности пути

					IF OBJECT_ID('tempdb..#Transactions') IS NOT NULL

					BEGIN

						DECLARE @ScriptPath NVARCHAR(255) = N'C:\Path\To\your\RemoveQuotes.ps1';

						DECLARE @InputFilePath NVARCHAR(255) = N'C:\Path\To\your\file.txt';

						DECLARE @OutputFilePath NVARCHAR(255) = N'C:\Path\To\your\output_file.txt';



						-- Формируем команду для запуска PowerShell-скрипта с параметрами

						SET @PowerShellCommand = N'powershell -Command "Copy-Item -Path ''' + @FilePath + ''' -Destination ''' + @InputFilePath + ''' -Force"';



						EXEC xp_cmdshell @PowerShellCommand;



						SET @PowerShellCommand = N'powershell -ExecutionPolicy Bypass -File "' + @ScriptPath -- + '" -InputFilePath "' + @InputFilePath + '" -OutputFilePath "' + @OutputFilePath + '"';



						EXEC xp_cmdshell @PowerShellCommand;



						SET @Command = '

                BULK INSERT #Transactions

                FROM ''' + @OutputFilePath + '''

                WITH 

                (

                    FIELDTERMINATOR = '','',  -- Разделитель полей

                    ROWTERMINATOR = ''0x0d0a'', -- Разделитель строк (Windows формат)

                    FIRSTROW = 2,             -- Пропускаем заголовок

                    CODEPAGE = ''65001'',     -- Кодировка UTF-8

                    TABLOCK

                );';



						--0x0d0a

						BEGIN TRY

							EXEC sp_executesql @Command;



							PRINT 'Data successfully loaded into temporary table from file: ' + @FilePath;

								-- Здесь можно выполнить дальнейшую обработку данных из временной таблицы #Transactions

						END TRY



						BEGIN CATCH

							PRINT 'Error occurred: ' + ERROR_MESSAGE();

						END CATCH;

					END

				END

				ELSE

				BEGIN

					PRINT 'No CSV or TXT file found in the specified folder.';

				END



				SELECT *

				FROM #Transactions



				ALTER TABLE #Transactions ADD ConvertedDate INT

					,ConvertedTime INT;



				DELETE #Transactions

				WHERE Side NOT IN (

						'Buy'

						,'Sell'

						, 'Short Sell'

						, 'Buy To Cover'

						)

					OR Statement IS NULL



				SELECT *

				FROM #Transactions --return



BEGIN TRY
UPDATE #Transactions

SET 

    ConvertedDate = CAST(CONVERT(VARCHAR, 

                    IIF(ABS(DATEDIFF(DAY, GETDATE(), DATEADD(HOUR, 4, TRY_CONVERT(DATETIME, DateGMT, 101)))) <= ABS(DATEDIFF(DAY, GETDATE(), DATEADD(HOUR, 4, ISNULL(TRY_CONVERT(DATETIME, DateGMT, 103), 0)))), 

                        DATEADD(HOUR, 4, TRY_CONVERT(DATETIME, DateGMT, 101)), 

                        DATEADD(HOUR, 4, ISNULL(TRY_CONVERT(DATETIME, DateGMT, 103), 0))

                    ), 112) AS INT),

    ConvertedTime = CAST(

                    RIGHT('0' + CAST(DATEPART(HOUR, DATEADD(HOUR, 4, 

                    IIF(ABS(DATEDIFF(DAY, GETDATE(), TRY_CONVERT(DATETIME, DateGMT, 101))) <= ABS(DATEDIFF(DAY, GETDATE(), ISNULL(TRY_CONVERT(DATETIME, DateGMT, 103), 0))),

                        TRY_CONVERT(DATETIME, DateGMT, 101), 

                        ISNULL(TRY_CONVERT(DATETIME, DateGMT, 103), 0)))) AS VARCHAR), 2) + 

                    RIGHT('0' + CAST(DATEPART(MINUTE, DATEADD(HOUR, 4, 

                    IIF(ABS(DATEDIFF(DAY, GETDATE(), TRY_CONVERT(DATETIME, DateGMT, 101))) <= ABS(DATEDIFF(DAY, GETDATE(), ISNULL(TRY_CONVERT(DATETIME, DateGMT, 103), 0))),

                        TRY_CONVERT(DATETIME, DateGMT, 101), 

                        ISNULL(TRY_CONVERT(DATETIME, DateGMT, 103), 0)))) AS VARCHAR), 2) + 

                    RIGHT('0' + CAST(DATEPART(SECOND, DATEADD(HOUR, 4, 

                    IIF(ABS(DATEDIFF(DAY, GETDATE(), TRY_CONVERT(DATETIME, DateGMT, 101))) <= ABS(DATEDIFF(DAY, GETDATE(), ISNULL(TRY_CONVERT(DATETIME, DateGMT, 103), 0))),

                        TRY_CONVERT(DATETIME, DateGMT, 101), 

                        ISNULL(TRY_CONVERT(DATETIME, DateGMT, 103), 0)))) AS VARCHAR), 2) + 

                    RIGHT('00' + CAST(DATEPART(MILLISECOND, DATEADD(HOUR, 4, 

                    IIF(ABS(DATEDIFF(DAY, GETDATE(), TRY_CONVERT(DATETIME, DateGMT, 101))) <= ABS(DATEDIFF(DAY, GETDATE(), ISNULL(TRY_CONVERT(DATETIME, DateGMT, 103), 0))),

                        TRY_CONVERT(DATETIME, DateGMT, 101), 

                        ISNULL(TRY_CONVERT(DATETIME, DateGMT, 103), 0)))) AS VARCHAR), 3) AS INT


    );
END TRY



			--	print RIGHT('0' + CAST(DATEPART(HOUR, DATEADD(HOUR, 4, CONVERT(DATETIME, '10/16/2024 11:41:58 PM', 101))) AS VARCHAR), 2)



				BEGIN CATCH

					-- Записываем ошибку в лог или выводим сообщение

					DECLARE @ErrorMessage NVARCHAR(4000)

						,@ErrorSeverity INT

						,@ErrorState INT;



					SELECT @ErrorMessage = ERROR_MESSAGE()

						,@ErrorSeverity = ERROR_SEVERITY()

						,@ErrorState = ERROR_STATE();



					-- Выводим сообщение об ошибке

					RAISERROR (

							@ErrorMessage

							,@ErrorSeverity

							,@ErrorState

							);

				END CATCH;



				SELECT *

				FROM #Transactions

				

				----------------------добавление инструмента НА ПЛОЩАДКУ  ЕСЛИ НЕТ--------------------------

				--/*

				INSERT INTO QORT_BACK_TDB.dbo.Securities (

					IsProcessed

					,ET_Const

					,ShortName

					,Name

					,TSSection_Name

					,SecCode

					,Asset_ShortName

					,QuoteList

					,IsProcent

					,LotSize

					,IsTrading

					,Lot_multiplicity

					,Scale

					)

				--, CurrPriceAsset_ShortName

				--*/

				SELECT DISTINCT 1 AS IsProcessed

					,2 AS ET_Const

					,tt.shortname

					,tt.ISIN Name

					,tss.Name AS TSSection_Name

					,tt.shortname secCode

					,tt.ShortName Asset_ShortName

					,1 QuoteList

					,iif(tt.AssetSort_Const IN (

							6

							,3

							), 'y', NULL) IsProcent

					,1 LotSize

					,'y' IsTrading

					,1 lot_multiplicity

					,8 Scale

				--, B.ShortName CurrPriceAsset_ShortName

				--into #t10 

				FROM #Transactions ttt

				LEFT OUTER JOIN QORT_BACK_DB.dbo.TSSections tss ON tss.BONumPref = left(ttt.Exchange, 4)

				OUTER APPLY (

					SELECT AssetSort_Const

						,Enabled

						,id

						,ISIN

						,ass.ShortName AS ShortName

					FROM QORT_BACK_DB.dbo.Assets Ass

					WHERE left(ass.viewName, len(ttt.symbol)) = ttt.symbol

						AND ASS.AssetClass_Const IN (5) -- Equity only

					) AS tt

				WHERE tt.Enabled = 0

					AND tt.id IS NOT NULL			

					AND NOT EXISTS (

						SELECT TOP 1 *

						FROM QORT_BACK_DB.dbo.Securities a

						WHERE a.Asset_ID = tt.id

							AND tt.Enabled = 0

							AND a.TSSection_ID = tss.id

							

						)



				--select * from #t10-- return

				SET @WaitCount = 1200 -------------------- задержка, не продолжаем пока не подгрузили бумаги----------------------



				WHILE (

						@WaitCount > 0

						AND EXISTS (

							SELECT TOP 1 1

							FROM QORT_BACK_TDB.dbo.Securities q WITH (NOLOCK)

							WHERE q.IsProcessed IN (

									1

									,2

									)

							)

						)

				BEGIN

					WAITFOR DELAY '00:00:03'



					SET @WaitCount = @WaitCount - 1

				END



				SELECT row_number() OVER (

						ORDER BY SequenceNo

						) rn

					,t.ConvertedDate AS TradeDate

					,t.ConvertedTime AS TimeInt

					,NULL AS SubAcc

					,t.Narration AddComment

					,tt.SecCode Security_Code

					,abs(t.NetHoldings) Qty

					,'USD' CurrPriceAsset_ShortName

					,round(CONVERT(FLOAT, REVERSE(SUBSTRING(REVERSE(t.Narration), 1, CHARINDEX('@', REVERSE(t.Narration)) - 1))) * abs(t.NetHoldings) * 100, 0) / 100 * IIF(TSS.NAME = 'OPRA',TT.BaseAssetSize,1) AS Volume1

					,CONVERT(FLOAT, REVERSE(SUBSTRING(REVERSE(t.Narration), 1, CHARINDEX('@', REVERSE(t.Narration)) - 1))) Price

					,t.Side BUY_sell

					,t.OrderID OrderID

					,round(cast(t.SequenceNo as float),0) Ref

					,CONVERT(INT, CONVERT(VARCHAR, dbo.fGetBusinessDay(CONVERT(DATETIME, CONVERT(VARCHAR(8), t.ConvertedDate), 112), 1), 112)) AS PutPlannedDate				

						--CONVERT(INT, CONVERT(VARCHAR, dbo.fGetBusinessDay(CONVERT(DATETIME, T.DateGMT, 101), 1), 112)) 

					,t.ConvertedTime AS TimeIntUpdate

					,t.Exchange PutAccount_ExportCode

					,tss.Name TSSection_Name

					,tss.TT_Const TT_Const

					,f.FirmShortName ExtBrokerFirm_ShortName

				INTO #comms

				FROM #Transactions t

				LEFT OUTER JOIN QORT_BACK_DB.dbo.TSSections tss ON tss.BONumPref = left(t.Exchange, 4)

				LEFT OUTER JOIN QORT_BACK_DB.dbo.Firms f ON f.BOCode = '19915' --GTN Middle East Financial Services

				OUTER APPLY (

					SELECT sec.SecCode AS SecCode,

							Ass.BaseAssetSize AS BaseAssetSize

					FROM QORT_BACK_DB.dbo.Assets Ass

					LEFT OUTER JOIN QORT_BACK_DB.dbo.Securities sec ON Sec.Asset_ID = Ass.id

						AND sec.TSSection_ID = tss.id

					WHERE left(ass.viewName, len(t.symbol)) = t.symbol

					) AS tt

					--where t.SequenceNo = '3458186864004.00'



				SELECT * FROM #comms



				--return

				----------------------- формирование сделОК в Корт---------------------------------------------------

				SET @n = (

						SELECT max(rn)

						FROM #comms

						)



				WHILE @n > 0

				BEGIN

					SET @WaitCount = 1200 -------------------- задержка, не передаем в ТДБ сделку, пока предыдущая не закончила грузиться----------------------



					WHILE (

							@WaitCount > 0

							AND EXISTS (

								SELECT TOP 1 1

								FROM QORT_BACK_TDB.dbo.ImportTrades t WITH (NOLOCK)

								WHERE t.IsProcessed IN (

										1

										,2

										)

								)

							)

					BEGIN

						WAITFOR DELAY '00:00:03'



						SET @WaitCount = @WaitCount - 1

					END



					--/*

					INSERT INTO QORT_BACK_TDB.dbo.ImportTrades (

						IsProcessed

						,ET_Const

						,IsDraft

						,TradeDate

						,TradeTime

						,TSSection_Name

						,BuySell

						,Security_Code

						,Qty

						,Price

						,Volume1

						,Volume1Nom

						,CurrPriceAsset_ShortName

						,PutPlannedDate

						,PayPlannedDate

						,PutAccount_ExportCode

						,PayAccount_ExportCode

						,SubAcc_Code

						,AgreeNum

						,TT_Const

						,AddComment

						--, AgreePlannedDate, Accruedint

						--, TraderUser_ID, SalesManager_ID

						,PT_Const

						--, TSCommission, IsAccrued

						,IsSynchronize

						--, CpSubacc_Code

						--, SS_Const

						,FunctionType

						,CurrPayAsset_ShortName

						,TradeNum

						,OrdExchCode

						,CpFirm_BOCode

						,ExtBrokerFirm_ShortName

						

						)

					--*/		

					SELECT 1 AS IsProcessed

						,2 AS ET_Const

						,'y' AS IsDraft

						,TradeDate AS TradeDate

						,TimeInt TradeTime

						,TSSection_Name AS TSSection_Name

						,iif(BUY_sell = 'Sell' or BUY_sell = 'Short Sell' , 2, 1) AS BuySell

						,Security_Code AS Security_Code

						,Qty AS Qty

						,Price AS Price

						,Volume1 AS Volume1

						,Volume1 AS Volume1Nom

						,CurrPriceAsset_ShortName AS CurrPriceAsset_ShortName

						,PutPlannedDate PutPlannedDate

						,PutPlannedDate PayPlannedDate

						,iif(TSSection_Name = 'OTC_Derivatives','ARMBR_DEPO_GTN_deriv', 'ARMBR_DEPO_GTN') as PutAccount_ExportCode

						,'Armbrok_Mn_Client' PayAccount_ExportCode

						,SubAcc AS SubAcc_Code

						,OrderID AgreeNum

						,TT_Const AS TT_Const

						,AddComment AS AddComment

						--, AgreePlannedDate, Accruedint

						--, TraderUser_ID, SalesManager_ID

						,2 AS PT_Const

						--, TSCommission, IsAccrued

						,'n' IsSynchronize

						--, 'ARMBR_Subacc' as CpSubacc_Code

						--, SS_Const

						,0 AS FunctionType

						,CurrPriceAsset_ShortName AS CurrPayAsset_ShortName

						, ref TradeNum

						--,cast((	cast(isnull((SELECT max(ID)	FROM QORT_BACK_DB.dbo.Trades WITH (NOLOCK)) + 1, 0) AS VARCHAR(8))) AS INT) TradeNum

						,Ref AS OrdExchCode

						,'19915' CpFirm_BOCode --GTN Middle East Financial Services

						,ExtBrokerFirm_ShortName

						

					FROM #comms

					WHERE rn = @n



					SET @n = @n - 1

				END

--return

				--/*

				-- весь файл обработан, надо переложить в history

				SELECT @NewFileName = convert(VARCHAR, getdate(), 112) + '_' + replace(convert(VARCHAR, getdate(), 108), ':', '-') + '_' + @FileName



				SET @cmd = 'move "' + @FilePath + '" "' + @HistPath + @NewFileName + '"'



				EXEC master.dbo.xp_cmdshell @cmd

					,no_output



				------ очищаем содержимое промежуточного файлаЮ чтобы второй раз не грузить-----

				SET @PowerShellCommand = 'powershell -Command "Clear-Content -Path ''' + @OutputFilePath + '''"';



				EXEC xp_cmdshell @PowerShellCommand;



				SET @rowsInFile = @rowsInFile - 1



				PRINT @rowsInFile



				--*/

				SET @rowsInFile = @rowsInFile - 1;

			END

		END

		ELSE

		BEGIN

			PRINT 'No files found';

		END;
	END TRY



	BEGIN CATCH

		WHILE @@TRANCOUNT > 0

			ROLLBACK TRAN



		SET @Message = 'ERROR: ' + ERROR_MESSAGE() + ISNULL(', ' + @FileName, '');



		IF @message NOT LIKE '%12345 Cannot initialize the data source%'

			INSERT INTO QORT_ARM_SUPPORT.dbo.uploadLogs (

				logMessage

				,errorLevel

				)

			VALUES (

				@message

				,1001

				);



		PRINT @Message

	END CATCH

END

