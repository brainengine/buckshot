public with sharing class TestServiceClass{
	
	public String logMessage {get;Set;}
	public String msg {get;Set;}
	public String url {get;Set;}
	
	private static String ENP_POINT_URL = 'https://fishbowl.wufoo.com/api/v3/forms/DSUZ-IJZ9-M2XK-61GR/entries.xml';
	private static String REQUEST_BODY = 'grant_type=password&client_id={0}&client_secret={1}&username={2}&password={3}';
	private static String USERNAME = 'Your_Username';
	private static String PASSWORD = 'Your_Password';
	
	public PageReference save() {
        return null;
    }
	
	public PageReference TestService(){
		
		try{
			HttpRequest req = new HttpRequest();
			req.setEndpoint('https://wyday.com/limelm/api/rest/');
			req.setMethod('POST');          
			
		 	//set the authorization header info
			String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(Blob.valueOf('DSUZ-IJZ9-M2XK-61GR' + ':' + 'brapibop'));
			//req.setHeader('Authorization', authorizationHeader);
			//req.setBody('method=limelm.pkey.find&version_id=829&email=brian%40brainengine.net&api_key=184f95655078929fb69b56.25388484');
			req.setBody('method=limelm.pkey.advancedSearch&version_id=829&page=2&num=100&email=&api_key=184f95655078929fb69b56.25388484');
			req.setTimeout(60000);
			Http objHttp = new Http();
			HttpResponse res;
			if(!Test.isRunningTest()){
	        	res = objHttp.send(req);
	        	System.debug('>>>>>>>>>>>>'+res.getbody());
	        	//logMessage = res.getbody();
			}
			
			Dom.Document doc = res.getBodyDocument();
        
	        //Retrieve the root element for this document.
	        Dom.XMLNode response = doc.getRootElement();
			
			List<License__c> liceses = new List<                 License__c>();
	        
	        Dom.XMLNode keys = response.getChildElement('pkeys', null);
			for(Dom.XMLNode child : keys.getChildElements()) {
				
				String key = child.getAttributeValue('key', null);
				String email = child.getAttributeValue('email', null);
				String acts = child.getAttributeValue('acts', null);
				String acts_used = child.getAttributeValue('acts_used', null);
				logMessage += key + ' @@@ ' +  email + ' @@@ ' +  acts + ' @@@ ' +  acts_used + ' @@@ ';
	            System.debug(child.getText());
				
				license__c license = new License__c();
				license.Email__c = email;
				license.Total_Activations__c = Decimal.valueOf(acts);
				license.Used_Activations__c = Decimal.valueOf(acts_used);
				license.Type__c = 'Professional';
				liceses.add(license);
	        }
			
			insert liceses;
	        
			
		}catch(Exception cce){
			logMessage = cce.getMessage();
            System.debug('@@@@@@@@@ ERROR: ' + cce.getMessage());
        }
		
		return null;
	}

}