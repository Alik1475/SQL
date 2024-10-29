









 -- exec QORT_ARM_SUPPORT.dbo.upload_ClientNameTranslate



CREATE PROCEDURE [dbo].[upload_ClientNameTranslate]

AS

BEGIN



	SET NOCOUNT ON







		declare @Message varchar(1024)

		declare @rows int

		declare @aid int = 0

		declare @WaitCount int

		declare @rowsInFile int

		declare @rowsNew int



		set @aid = isnull((select max(aid) from QORT_BACK_TDB.dbo.Firms with (nolock)), 0)



		declare @FileName varchar(128) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Clients\Clients_Import UniCode_TEST3.xlsx';

		declare @Sheet1 varchar(64) = 'Sheet3' 

		declare @sql varchar(1024)



		if OBJECT_ID('tempdb..##fUnicode', 'U') is not null drop table ##fUnicode

		if OBJECT_ID('tempdb..#t', 'U') is not null drop table #t

	

		SET @sql = 'SELECT * INTO ##fUnicode

		FROM OPENROWSET (

			''Microsoft.ACE.OLEDB.12.0'',

			''Excel 12.0; Database='+ @FileName + '; HDR=YES;IMEX=0'',

			''SELECT * FROM [' + @Sheet1 + '$A1:ZZ1000000]'')'



		exec(@sql)



		select nullif([NAME_Translate], '') NAME_Translate

			, nullif([Account], '') Account

		

		into #t

		from ##fUnicode





		insert into QORT_ARM_SUPPORT..ClientNameTranslate (NAME_Translate, Account)

		select NAME_Translate, Account

		from #t

		

		where NAME_Translate is not null and NAME_Translate <>''

END

