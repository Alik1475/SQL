

--exec QORT_ARM_SUPPORT.dbo.SendMail_LetterForClients @sendmail = 0 , @SendText = '', @SendSubject = '05/07 NON-WORKING DAY ARMBROK'



CREATE PROCEDURE [dbo].[SendMail_LetterForClients]

	@SendMail bit,

	@SendText varchar(1024) ,

	@SendSubject varchar(1024)

AS

BEGIN



	SET NOCOUNT ON



	begin try



									



declare @FilePath varchar(255) = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\SendMail'

declare @Sheet varchar(16) 

if right(@FilePath, 1) <> '\' set @FilePath = @FilePath + '\'

declare @Message varchar (1024)									

declare @NotifyEmail varchar(1024) 

declare @NotifyMessage varchar(1024)



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

	, s.MarginEMail

	, IIF((f.FT_Flags > 4194304 and f.FT_Flags < 8388608) or f.FT_Flags > 8500000, 'y','n') own_clerk

	, f.Email emailBP

	, f.BOCode

	, f.Sales_ID

 into #result

 from QORT_BACK_DB..Subaccs s

   right outer join QORT_BACK_DB..Firms f on f.id = s.OwnerFirm_ID

 where ConstitutorCode <>'' and LEFT(subaccCode,2) ='AS' and s.Enabled <> s.ID and ACSTAT_Const = 5 and f.STAT_Const = 5 

  and s.SubAccCode not in ('AS1023','AS1144','AS1174','AS1188','AS1454','AS1515','AS1594','AS1008','AS1024','AS1887','AS1293', 'AS_test') --and (f.FT_Flags > 4194304 and f.FT_Flags < 8388608) or f.FT_Flags > 8500000 --and SubAccCode = 'AS1105'--and (c.FCT
_Const = 2 or c.FCT_Const is null) and c.IsCancel = 'n'

 -- and s.SubAccCode = 'AS1105'

--and f.Sales_ID in(273)

  order by SubAccCode asc





	set @n = CAST ((select max (num) from #result) as int)



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

	   set @NotifyTitle = 'Information letter for '+@Name+': '+@SendSubject

	   set @subaccode = cast((select SubAccCode from #result where Num = @n) as varchar(1024))

	  /* set @NotifyMessage = 'Dear clients, <br/><br/>

	        We are pleased to announce a significant change in our commission policy. With your trust in mind and our constant drive for improvement, we have decided to charge the broker commission on the day of trade execution since July 1, 2024. 

	        This decision makes your trading even more transparent and accessible, helping you achieve your financial goals more efficiently.

	        For further information kindly contact your personal manager.

	        <br/><br/>

	        We thank you for your continued trust and remain dedicated to your success.

	        <br/><br/><br/>

            Best wishes,<br/>

            ARMBROK Team'*/

	   set @NotifyEmail = cast((select email from #result where Num = @n ) as varchar(1024) )

	  

	  if @NotifyEmail = '' --уведомление, что емаил клиента не найден



	 begin

	    set @NotifyEmail = 'aleksandr.mironov@armbrok.am;sona.nalbandyan@armbrok.am;onboarding@armbrok.am'

	    set @NotifyTitle = 'Error. Client without email!!! '+@subaccode+' '+@Name

	 end

	

	print @NotifyEmail

	EXEC msdb.dbo.sp_send_dbmail

			@profile_name =  'onboarding-sql'--'onboarding-test-sql'--

			, @recipients = @NotifyEmail

			, @subject = @NotifyTitle

			, @BODY_FORMAT = 'HTML'

			, @body = @NotifyMessage 

		--	, @file_attachments = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Статика\02_SSI_ARMBROK_GENERAL_CLIENT_USD.pdf'

			

			set @n = @n - 1

			--print @NotifyEmail

			end

	   





	 end

	else 

	 begin

	 set @NotifyEmail = 'qort@armbrok.am'

	 set @Name = '--ClientName--'

	 set @NotifyTitle = 'Information letter for '+@Name+': '+@SendSubject

	 EXEC msdb.dbo.sp_send_dbmail

			@profile_name =  'onboarding-sql'--'onboarding-test-sql'--

			, @recipients = @NotifyEmail

			, @subject = @NotifyTitle

			, @BODY_FORMAT = 'HTML'

			, @body = @NotifyMessage 

		--	, @file_attachments = '\\192.168.14.22\Exchange\QORT_Files\PRODUCTION\Статика\02_SSI_ARMBROK_GENERAL_CLIENT_USD.pdf'

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

