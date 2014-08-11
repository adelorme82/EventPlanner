global class GoogleVoice
{
	Map<String, String> params;
	private String account_type = 'GOOGLE';
	private String service = 'grandcentral';
	private String rnr_se = 'WltAswa8jiPSdjbormjI091pkgc='; 
	private String url = 'https://www.google.com/';
	private String auth;
	private String email;
	private String password;


	global GoogleVoice()
	{
		GoogleVoice__c gvp = GoogleVoice__c.getInstance( [SELECT Id FROM User WHERE username='adelorme@austin.com.twilio'][0].Id);
		params = new Map<String, String>();
		params.put('accountType', account_type);
		params.put('service', service);
		params.put('Email', gvp.Google_Email__c);
		params.put('Passwd', gvp.Google_Password__c);

	    //:", "Authorization: GoogleLogin auth=".$this->auth)
	    
		Map<String, String> body = makeRequest(params, 'accounts/ClientLogin');
	    auth = body.get('Auth');
	    System.debug('Auth: ' + auth);
	   
	}

	global void sendMessage(String toNumber, String message)
	{
		params = new Map<String, String>();
		params.put('phoneNumber', toNumber);
		params.put('text', message);
		params.put('id', '');
		params.put('_rnr_se', rnr_se);
		makeRequest(params, 'voice/sms/send/');
	}

	private Map<String, String> makeRequest(Map<String, String> params, String endpoint)
	{
		return makeRequest(params, endpoint, 'POST');
	}

	private Map<String, String> makeRequest(Map<String, String> params, String endpoint, String type)
	{
		Http h = new Http();
		HttpRequest req = new HttpRequest();
	    req.setEndpoint(url + endpoint);
	    req.setMethod(type);
	    req.setHeader('Content-Type', ' application/x-www-form-urlencoded');
	    if (auth != null)
	    {
	   		req.setHeader('Authorization', 'GoogleLogin auth=' + auth);
	    }

	    req.setBody(getRequestBody(params));
		system.debug(req.getBody());

		HttpResponse res = h.send(req);
	    system.debug(res.getBody());
	    Map<String, String> body = getMapFromResponseBody(res.getBody());

	    return body;
	}

	private String getRequestBody(Map<String, String> params)
	{
		List<String> values = new List<String>();

		for (String key : params.keySet())
		{
			String temp = key + '=' + EncodingUtil.urlEncode(params.get(key), 'UTF-8'); 
			values.add(temp);
		}

		return String.join(values, '&');
	}

	private Map<String, String> getMapFromResponseBody(String body)
	{
		Map<String, String> returnMap = new Map<String, String>();
		List<String> values = body.split('\\s+');
	   	for (String value : values)
	   	{
	   		List<String> temp = value.split('=', 2);
	   		if (temp.size() > 1) returnMap.put(temp[0], temp[1]);
	   	}
	   	return returnMap;
	}
	

}