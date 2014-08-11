global class MassTextMessageSender implements Database.Batchable<sObject>, Database.AllowsCallouts
{
	public Integer batchNum;

	global MassTextMessageSender()
	{
		this(0);
	}

	global MassTextMessageSender(Integer index)
	{
		batchNum = index;
	    System.debug('###batchNum: ' + batchNum);
	}

	global Iterable<sObject> start(Database.BatchableContext bc) 
	{
		List<SMS_Message__c> messages = [SELECT Id, To_Number__c, From_Number__c, Sent__c, Body__c, Send_Error__c, Send_Error_Text__c FROM SMS_Message__c WHERE Type__c='Outgoing' AND Sent__c=false AND Send_Error__c=false];
		System.debug('###start messages.size(): ' + messages.size());
		return messages;
	}

    global void execute(Database.BatchableContext BC, List<SMS_Message__c> messages)
    {

    	for (SMS_Message__c sms : messages)
    	{
            System.debug('###raw toNumber: ' + sms.To_Number__c);
    		String toNumber = formatPhoneNumber(sms.To_Number__c);
	    	Boolean success = true;
	    	System.debug('###toNumber: ' + toNumber);
	    	System.debug('###sms.Id: ' + sms.Id);
	    	System.debug('###sms.Body__c: ' + sms.Body__c);
	    	try
	    	{
			    GoogleVoice g = new GoogleVoice();
			    g.sendMessage(toNumber, sms.Body__c);
	    	}
	    	catch (Exception e)
	    	{
	    		success = false;
	    		sms.Send_Error__c = true;
	    		sms.Send_Error_Text__c = e.getStackTraceString();
                sms.Send_Error_Text__c += '\n\n' + e.getCause();
                sms.Send_Error_Text__c += '\n\n' + e.getMessage();
	    		System.debug('###e: ' + e);
	    	}
	    	sms.Sent__c = success;
	    	System.debug('###success: ' + success);
    	}
		update messages;

    }

    global void finish(Database.BatchableContext BC)
    {
		List<SMS_Message__c> messages = [SELECT Id FROM SMS_Message__c WHERE Sent__c = false AND Send_Error__c = false];
		if (!messages.isEmpty())
		{
			//only do one record - batch can only do one callout
			MassTextMessageSender sender = new MassTextMessageSender(batchNum + 1);
			Id batchprocessid = Database.executebatch(sender,1);
            System.debug('###chain batchprocessid: ' + batchprocessid);

		}

    }

    global String formatPhoneNumber(String raw)
    {
    	if (raw.length() == 12 && raw.startsWith('+1')) return raw;

        String phoneNumber = raw.replaceAll('\\D', '');
        if (phoneNumber.length() == 11 && phoneNumber.startsWith('1')) return '+' + phoneNumber;

        if (phoneNumber.length() == 10) return '+1' + phoneNumber;

        return null;

    }
}