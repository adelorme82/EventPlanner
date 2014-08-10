@RestResource(urlMapping='/SMSReceiver/*')
global class TextMessageRecieverController
{
    public static final String ATTEND = 'ok';
    public static final String MASS_TEXT = 'Mass text';
    public static final String APPROVED_NUMBER = '+16023277948';
    public TextMessageRecieverController(ApexPages.StandardController sc)
    {

    }

    @HttpPost
    global static void recieveMessage()
    {   
        //String fromName, String fromNumber, String message
        Map<String, String> params = RestContext.request.params;
        String toNumber = params.get('To');
        String fromNumber = params.get('From');
        String wholeMessage = params.get('Body');

        for (String param : params.keyset())
        {
            System.debug('Param - ' + param + ': ' + params.get(param));
        }

        //System.debug(params);
        //System.debug('fromName: ' + fromName);
        //System.debug('fromNumber: ' + fromNumber);
        //System.debug('message: ' + message);


        //SMS_Message__c msg = new SMS_Message__c();
        //msg.To_Number__c = toNumber;
        //msg.From_Number__c = fromNumber;
        //msg.Message__c = message;
        //insert msg;
        List<String> messageParts = wholeMessage.split(' ', 2);
        String eventKey = messageParts[0];
        String message = '';
        if (messageParts.size() > 1) message = messageParts[1];

        if (fromNumber == APPROVED_NUMBER)
        {
            sendMessageToAttendees(eventKey, message);
        }
        else
        {
            System.debug('###Creating Attendee: ' + fromNumber);
            List<Event__c> e = getEvent(eventKey);
            if (e.isEmpty())
            {
                system.debug('###No event found: ' + eventKey);
                respondWithfailure(fromNumber, eventKey);
            }
            else
            {
                Contact c = getContactByPhone(fromNumber);
                Boolean newAttendee = true;
                if (c != null)
                {
                    System.debug('###Contact found: ' + c.Name);
                    //check for the same contact
                    for (Attendee__c a : [SELECT Contact__c, Phone_Number__c, Contact__r.MobilePhone, Contact__r.Name FROM Attendee__c WHERE Event__c =: e[0].Id])
                    {
                        if (a.Contact__c == c.Id)
                        {
                            if (c.Name == 'UNKNOWN')
                            {
                                System.debug('###Unknown contact: ' + fromNumber);
                                //make a new attendee if numbers arent the same
                                newAttendee = fromNumber != a.Phone_Number__c;
                            }
                            else
                            {
                                System.debug('###Duplicate contact found');
                                newAttendee = false;
                                break;
                            }
                        }
                    }
                }
                
                if (newAttendee)
                {
                    Attendee__c a = new Attendee__c();
                    a.Name = c.Name;
                    a.Contact__c = c.Id;
                    a.Registration_Message__c = wholeMessage;
                    a.Date_registered__c = Datetime.now();
                    a.Event__c = e[0].Id;
                    a.Phone_Number__c = fromNumber;
                    insert a;
                }
            }
        }


    }

    private static void sendMessageToAttendees(String eventKey, String message)
    {
        List<Event__c> e = getEvent(eventKey);
        if (e.isEmpty()) respondWithfailure(APPROVED_NUMBER, eventKey);
        else
        {
            Set<String> phoneNumbers = new Set<String>();

            for (Attendee__c a : [SELECT Contact__r.MobilePhone FROM Attendee__c WHERE Event__c =: e[0].Id])
            {
                phoneNumbers.add(a.Contact__r.MobilePhone);
            }
            TextMessageSender.send(phoneNumbers, message);
        }
    }

    private static void respondWithfailure(String fromNumber, String eventKey)
    {
        String response = 'Sorry, no current events found with key: ' + eventKey;
        TextMessageSender.send(new Set<String>{fromNumber}, response);
    }

    private static List<Event__c> getEvent(String eventKey)
    {
        String search = '%' + eventKey.toLowerCase() + '%';
        return [SELECT Id, Name, Location__c, Start_Time__c FROM Event__c WHERE SMS_Keys__c like :search];
    }

    private static Contact getContactByPhone(String phoneNumber)
    {
        String formatPhoneNumber = formatphonenumber(phoneNumber);

        phoneNumber = phoneNumber.replaceAll('\\D', '');
        if (phoneNumber.substring(0,1) == '1') phoneNumber = phoneNumber.substring(1);

        System.debug('formatPhoneNumber' + formatPhoneNumber);
        System.debug('phoneNumber' + phoneNumber);
        List<Contact> contacts = [SELECT Id, Name, MobilePhone FROM Contact WHERE MobilePhone =: formatPhoneNumber OR MobilePhone =: phoneNumber];

        Contact c = null;
        if (!contacts.isEmpty())
        {
            c = contacts[0];
        }
        else
        {
            System.debug('### No Contact found');
            c = [SELECT Id, Name, MobilePhone FROM Contact WHERE Name='UNKNOWN'][0];
        }

        return c;

    }

    public static Contact createContactFromNameAndPhone(String name, String phone)
    {
        List<String> names = name.split(' ');
        Contact c = new Contact();
        if (names.size() > 1)
        {
            c.LastName = names[names.size() - 1];
            c.FirstName = names[0];
        }
        else
        {
            c.LastName = names[0];
        }

        if (phone != null)
        {
            phone = phone.replaceAll('\\D', '');

            if (phone.substring(0,1) == '1') phone = phone.substring(1);

            if (phone.length() == 7) phone = '602' + phone;
        }

        c.MobilePhone = phone;

        insert c;
        return c;

    }


    public static String formatphonenumber(String cphone) {
        String fphone = cphone.replaceAll('\\D','');

        if (fphone.length() == 11) 
        {
            fphone = formatphonenum(fphone);
            return fphone;
        }
        else 
        {
            return cphone;
        }

    }

    static String formatphonenum (String s) 
    {
        s = '(' + s.substring(1, 4) + ') ' + s.substring(4, 7) + '-' + s.substring(7);
        return s;
    }
}