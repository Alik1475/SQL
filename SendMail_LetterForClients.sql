/*

exec QORT_ARM_SUPPORT.dbo.SendMail_LetterForClients @sendmail = 1 , @SendText = '', @SendSubject = 'ARMBROK Non-Working Day on 28/01/2025', @SubAccCode = 'VICTOR'

*/

CREATE PROCEDURE [dbo].[SendMail_LetterForClients]

	@SendMail bit,

	@SendText varchar(3000) ,

	@SendSubject varchar(1024),

	@SubAccCode varchar(32)

AS

BEGIN



	SET NOCOUNT ON



	begin try



									



declare @FilePath varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\SendMail'

declare @Sheet varchar(16) 

if right(@FilePath, 1) <> '\' set @FilePath = @FilePath + '\'

declare @Message varchar (1024)									

declare @NotifyEmail varchar(1024) 

declare @NotifyMessage varchar(3000)

declare @copy_recipients varchar(1024) 

declare @profile_name varchar(1024) 

select @NotifyMessage = bulkColumn 

from openrowset(bulk '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\SendMail\NotifyMessage.txt', SINGLE_CLOB) as FileData

--print @NotifyMessage return

declare @NotifyTitle varchar(1024)

declare @subaccode varchar(1024)

declare @ConstitutorCode varchar(1024)

declare @Name varchar(1024)

declare @ContactsEmail varchar(1024)

declare @n int

declare @n1 int

if OBJECT_ID('tempdb..#RESULT', 'U') is not null drop table #RESULT



 select distinct ROW_NUMBER() OVER(order by SubAccCode asc) as Num

	, s.SubAccCode

	, f.Name

	, replace(f.Email,',',';')+IIF(s.MarginEMail = '','',';'+s.MarginEMail) email--, s.ConstitutorCode

	, s.OwnerFirm_ID firm_id

	, '' MarginEMail

	, IIF((f.FT_Flags > 4194304 and f.FT_Flags < 8388608) or f.FT_Flags > 8500000, 'y','n') own_clerk

	, f.Email emailBP

	, f.BOCode

	, f.Sales_ID

 into #result

 from QORT_BACK_DB..Subaccs s

   right outer join QORT_BACK_DB..Firms f on f.id = s.OwnerFirm_ID

 where LEFT(subaccCode,2) ='AS' and s.Enabled <> s.ID and ACSTAT_Const = 5 and f.STAT_Const = 5 

  and (

        @SubAccCode = 'ALL'

        or (@SubAccCode = 'VICTOR' and f.Sales_ID = 618)

        or (s.SubAccCode in (@SubAccCode) and @SubAccCode not in ('ALL', 'VICTOR'))

      )

 -- and s.SubAccCode in ('AS1935')

  order by SubAccCode asc



  --SELECT * from #result return



	set @n = 0--CAST ((select max (num) from #result) as int)



 while @n > 0

   begin

	 if OBJECT_ID('tempdb..#t', 'U') is not null drop table #t

	  

	  select ROW_NUMBER() OVER(order by email asc) as Num1, email 

	  into #t

	  from QORT_BACK_DB..FirmContacts fc

	  where fc.Firm_ID = CAST((select Firm_ID from #result where Num = @n) as varchar(1024)) and FCT_Const = 2 and IsCancel = 'n'



     set @n1 = CAST ((select max (Num1) from #t) as int)

	

	while @n1 > 0

	 begin   



	  set @ContactsEmail = CAST((select iif(charindex('@',email) > 0, email, '') from #result where Num = @n) as varchar(1024))+iif((select iif(charindex('@',email) > 0, email, '') from #t where Num1 = @n1) = '','',';'+CAST((select email from #t where Num1 =
 @n1) as varchar(1024)))

	  

	  update #result

	  set email = @ContactsEmail

	  where Num = @n

	  

	  set @n1 = @n1-1



	 end



	set @n = @n-1

   end

	

	SELECT * FROM #RESULT order by SubAccCode



	

	-------------------------------------блок отправки сообщений----------------------------------------

if @SendMail = 1 begin



	 set @n = CAST ((select max (num) from #result) as int)

	 while @n > 0

	  begin

	   set @Name = cast((select Name from #result where Num = @n) as varchar(1024))

	   set @NotifyTitle = @SendSubject

	   set @subaccode = cast((select SubAccCode from #result where Num = @n) as varchar(1024))

	  /* 

	  set @NotifyMessage = ' Dear client,<br/> 
	  We hope this message finds you well. <br/>
	  We would like to inform you that 28th of January, 2025 is a non-working day in Armenia. As a result, our team will be unavailable for regular operations on this 
date.  <br/> 

	  If you have any urgent inquiries, we kindly encourage you to contact us before 28th of January, 2025, and we will do our utmost to assist you promptly. <br/> 

	  Thank you for your understanding.<br/><br/>

Sincerely,<br/> 

Armbrok Team <br/><br/>

	



		<p>

									<img src="https://www.armbrok.am/logo.png" alt="Armbrok Logo"><br> <!-- Изменить URL на правильный путь к логотипу -->																

									+374 11 590 000 <br>

									+374 99 999 999 <br>

									<a href="http://www.armbrok.am">www.armbrok.am</a><br>

									39 Hanrapetutyan Street<br>

									Yerevan 0010, Armenia<br>

								</p>'

			--*/

	   set @NotifyEmail = cast((select email from #result where Num = @n ) as varchar(1024) )--'aleksandr.mironov@armbrok.am'--

	  

	  if @NotifyEmail = '' --уведомление, что емаил клиента не найден



	 begin

	    set @NotifyEmail = 'aleksandr.mironov@armbrok.am;sona.nalbandyan@armbrok.am;onboarding@armbrok.am'

	    set @NotifyTitle = 'Error. Client without email!!! '+@subaccode+' '+@Name

	 end

	

	print @NotifyEmail



			IF @SubAccCode = 'VICTOR' 

			BEGIN 

				SET @profile_name = 'Viktor.Dolzhenko'; 

				SET @copy_recipients = '' --'lilit.paronyan@armbrok.am'; 

			END

			ELSE

			BEGIN

				SET @profile_name = 'onboarding-sql'; 

				SET @copy_recipients = '';

			END

	--/*

	EXEC msdb.dbo.sp_send_dbmail

			@profile_name =  @profile_name --'Viktor.Dolzhenko' --'onboarding-sql'--'onboarding-test-sql'-- 

			, @recipients = @NotifyEmail

			, @copy_recipients = @copy_recipients

			, @subject = @NotifyTitle

			, @BODY_FORMAT = 'HTML'

			, @body = @NotifyMessage 

		--	, @file_attachments = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Статика\02_SSI_ARMBROK_GENERAL_CLIENT_USD.pdf'

			--*/

			set @n = @n - 1

			--print @NotifyEmail

			end

	   





	 end

	else 

	 begin

	 set @NotifyEmail = 'qort@armbrok.am'

	 set @Name = '--ClientName--'

	 set @NotifyTitle = 'Information letter for '+@Name+': '+@SendSubject

	 /*

	 EXEC msdb.dbo.sp_send_dbmail

			@profile_name =  'onboarding-sql'--'onboarding-test-sql'--

			, @recipients = @NotifyEmail

			, @subject = @NotifyTitle

			, @BODY_FORMAT = 'HTML'

			, @body = @NotifyMessage 

		--	, @file_attachments = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Статика\02_SSI_ARMBROK_GENERAL_CLIENT_USD.pdf'

		--*/

	 end

	-------------------------------------------------------------------------конец блока отправки сообщений-------------------------------------------

	end try

	begin catch

		while @@TRANCOUNT > 0 ROLLBACK TRAN

		set @Message = 'ERROR: ' + ERROR_MESSAGE(); 

		insert into QORT_ARM_SUPPORT.dbo.uploadLogs(logMessage, errorLevel) values (@message, 1001);

		select @Message result, 'STATUS' defaultTask, 'red' color

	end catch



END

