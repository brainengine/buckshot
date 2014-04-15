/**
 * Author  : Brad Herman, bherman@salesforce.com
 * Date    : March, 2010
 * Comment : This class creates and handles Google Alerts, parses the emails to identify a relevant Account,
 *           and posts the email content to that Account's chatter feed.
 *           Apex Email Services documentation: http://wiki.developerforce.com/index.php/Force.com_Email_Services
 *           Chatter API documentation: http://www.salesforce.com/us/developer/docs/api/Content/sforce_api_erd_chatter.htm
 * Requires: Instantiate and configure Email-to-Apex.
**/

global class GoogleAlertToChatter implements Messaging.InboundEmailHandler {
    // class variables
    public static final String openBracket = '[';
    public static final String closeBracket = ']';
    public List <String >alertMessages = new List <String >();
    public List <String >alertURLs = new List <String >();
    public Google_Alert_to_Chatter_Settings__c settings = [select News_Source_Blacklist__c, Maximum_Stories_Per_Alert__c 
                                                           from Google_Alert_to_Chatter_Settings__c limit 1];
    public String newsSourceBlacklist = '';
    // Method to handle inbound email from google
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        // set variables using logic
        if (settings.News_Source_Blacklist__c != null) {
            newsSourceBlacklist = settings.News_Source_Blacklist__c;
        }
        // Create an inboundEmailResult object for returning the result of the Force.com Email Service
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult ();
        // Other variables
        String emailSender = '';
        String emailSubject = '';
        String emailBody = '';
        String emailTextBody = '';
        String verifyURL = '';
        String cancelURL = '';
        List <Account >relevantAccounts;
        // Extract sender and text of email
        try {
            emailSender = email.fromAddress;
            emailSubject = email.subject;
            emailBody = email.htmlBody;
            emailTextBody = email.plainTextBody;
        }
        catch (System.StringException e) {
            System.debug('Invalid Email - malformed: '+ e);
        }
        // If this is a verification email from Google Alerts, do an HTTP Post callout to verify & store Account details
        if (emailSubject == 'Click to confirm your Google Alert') {
            verifyURL = parseGoogleAlertforVerifyURL(emailTextBody);
            cancelURL = parseGoogleAlertforCancelURL(emailTextBody);
            verifyGoogleAlert(verifyURL);
            relevantAccounts = parseGoogleAlertVerifyforAccount(emailTextBody);
            updateAlertStatusAccounts(relevantAccounts, cancelURL);
            result.success = true;
            // Else if this is an alert email, parse text and post to chatter
        }
        else if (emailSubject != null &&emailSubject.startsWith('Google Alert -')) {
            relevantAccounts = parseGoogleAlertforAccount(emailSubject);
            parseGoogleAlertforMessage(emailBody);
            postChatter(relevantAccounts, alertMessages, alertURLs);
            result.success = true;
            // Else if this is duplicate notification email, parse find account and update status
        }
        else if (emailSubject != null &&emailSubject == 'Error: Duplicate alerts') {
            relevantAccounts = parseGoogleAlertDupeforAccount(emailTextBody);
            updateDuplicateStatusAccounts(relevantAccounts);
            result.success = true;
            // Else this is not an appropriate Google Alert email 
        }
        else {
            System.debug('Invalid Email - did not recognize subject line: '+ emailSubject);
            result.success = false;
        }
        // end email type identification if/then
        return result;
    }
    //end inbound email handling method
    // Method to parse Google Alert Verify email for the verification URL
    public String parseGoogleAlertforVerifyURL(String emailBody) {
        String verifyURL = emailBody.substring(emailBody.indexOf('http://'));
        verifyURL = verifyURL.substring(0, 89);
        return verifyURL;
    }
    //end method to parse for verification URL
    // Method to parse Google Alert Verify email for the cancelation URL
    public String parseGoogleAlertforCancelURL(String emailBody) {
        String cancelURL = emailBody.split('http://')[2];
        cancelURL = cancelURL.substring(0, 82);
        return cancelURL;
    }
    //end method to parse for cancel URL
    // Method to HTTP Post callout to Google to verify the alert
    public Boolean verifyGoogleAlert(String url) {
        List <String >methods = new List <String >();
        List <String >endpoints = new List <String >();
        List <String >bodies = new List <String >();
        methods.add('GET');
        endpoints.add(url.substring(7));
        bodies.add('');
        executeGoogleAlertsCallouts(methods, endpoints, bodies);
        return true;
    }
    //end method to verify Google Alert
    // Method to parse Google Alert verification email for the relevant Account
    public List <Account >parseGoogleAlertVerifyforAccount(String emailBody) {
        String alertSearchString = emailBody.substring(emailBody.indexOf(openBracket)+ 2, emailBody.indexOf(closeBracket)- 1);
        // eliminate possible quotes in search string
        if (alertSearchString.startsWith('"')&&alertSearchString.endsWith('"')) {
            alertSearchString = alertSearchString.substring(1, alertSearchString.length()- 1);
        }
        // remove elipsis in search string, included when search string is longer than 15 characters
        if (alertSearchString.contains('...')) {
            alertSearchString = alertSearchString.substring(0, alertSearchString.indexOf('...')- 1);
        }
        List <Account >relevantAccounts;
        relevantAccounts = [select id, name from Account where Google_Alert_Search_Term_s__c = :alertSearchString];
        if (relevantAccounts.size()== 0) {
            relevantAccounts = [select id, name from Account where name = :alertSearchString];
        }
        alertSearchString = alertSearchString + '%';
        if (relevantAccounts.size()== 0) {
            relevantAccounts = [select id, name from Account where Google_Alert_Search_Term_s__c like :alertSearchString];
        }
        if (relevantAccounts.size()== 0) {
            relevantAccounts = [select id, name from Account where name like :alertSearchString];
        }
        return relevantAccounts;
    }
    //end method to parse for Account
    // Update accounts GoogleAlertsToChatter status and cancel URL
    public Void updateAlertStatusAccounts(List <Account >relevantAccounts, String cancelURL) {
        for (Account a :relevantAccounts) {
            a.Google_Alerts_to_Chatter_Status__c = 'Active';
            a.Google_Alert_Cancel_URL__c = cancelURL;
        }
        //end for each loop
        update relevantAccounts;
    }
    //end method to update accounts with status
    // Update accounts that are still waiting on confirmation with duplicate status
    public Void updateDuplicateStatusAccounts(List <Account >relevantAccounts) {
        for (Integer i = 0;
        i <relevantAccounts.size();
        i ++) {
            if (relevantAccounts [i ].Google_Alerts_to_Chatter_Status__c == 'Confirming') {
                relevantAccounts [i ].Google_Alerts_to_Chatter_Status__c = 'Active - Duplicate Search Term';
            }
            else {
                relevantAccounts.remove(i);
            }
            //end if/then
        }
        //end for each loop
        update relevantAccounts;
    }
    // end method to update accounts with duplicate status
    // Method to parse Google Alert email for the relevant Account
    public List <Account >parseGoogleAlertforAccount(String emailSubject) {
        String alertSearchString = emailSubject.substring(15);
        // eliminate possible quotes in search string
        if (alertSearchString.startsWith('"')&&alertSearchString.endsWith('"')) {
            alertSearchString = alertSearchString.substring(1, alertSearchString.length()- 1);
        }
        // remove elipsis in search string, included when search string is longer than 15 characters
        if (alertSearchString.contains('...')) {
            alertSearchString = alertSearchString.substring(0, alertSearchString.indexOf('...')- 1);
        }
        //match the search term(s) against account name or google alert search term 
        List <Account >relevantAccounts;
        relevantAccounts = [select id, name from Account where Google_Alert_Search_Term_s__c = :alertSearchString];
        if (relevantAccounts.size()== 0) {
            relevantAccounts = [select id, name from Account where name = :alertSearchString];
        }
        alertSearchString = alertSearchString + '%';
        if (relevantAccounts.size()== 0) {
            relevantAccounts = [select id, name from Account where Google_Alert_Search_Term_s__c like :alertSearchString];
        }
        if (relevantAccounts.size()== 0) {
            relevantAccounts = [select id, name from Account where name like :alertSearchString];
        }
        return relevantAccounts;
    }
    //end method to parse for Account
    // Method to parse Google Alert duplicate notice email for the relevant Account
    public List <Account >parseGoogleAlertDupeforAccount(String emailBody) {
        String alertSearchString = emailBody.substring(emailBody.indexOf(openBracket)+ 1, emailBody.indexOf(closeBracket)- 1);
        // eliminate possible quotes in search string
        if (alertSearchString.startsWith('"')&&alertSearchString.endsWith('"')) {
            alertSearchString = alertSearchString.substring(1, alertSearchString.length()- 1);
        }
        // remove elipsis in search string, included when search string is longer than 15 characters
        if (alertSearchString.contains('...')) {
            alertSearchString = alertSearchString.substring(0, alertSearchString.indexOf('...')- 1);
        }
        //match the search term(s) against account name or google alert search term 
        List <Account >relevantAccounts;
        relevantAccounts = [select id, name from Account where Google_Alert_Search_Term_s__c = :alertSearchString];
        if (relevantAccounts.size()== 0) {
            relevantAccounts = [select id, name from Account where name = :alertSearchString];
        }
        alertSearchString = alertSearchString + '%';
        if (relevantAccounts.size()== 0) {
            relevantAccounts = [select id, name from Account where Google_Alert_Search_Term_s__c like :alertSearchString];
        }
        if (relevantAccounts.size()== 0) {
            relevantAccounts = [select id, name from Account where name like :alertSearchString];
        }
        return relevantAccounts;
    }
    //end method to parse for Account
    // Method to parse Google Alert email for the message to post
    public Boolean parseGoogleAlertforMessage(String emailBody) {
        String headline = '';
        String link = '';
        // break the email into each "story", ignore the last string
        List <String >emailBodyStories = emailBody.split('http://www.google.com/url');
        // loop through each story to extract the headline and link, add to global list
        for (Integer i = 1;
        i <emailBodyStories.size();
        i ++) {
            try {
                // parse the headline text and urls from the "story"
                headline = emailBodyStories [i ];
                headline = headline.substring(headline.indexOf('>')+ 1, headline.indexOf('</a>')).trim();
                link = emailBodyStories [i ];
                link = link.substring(link.indexOf('q='), link.indexOf('&amp;ct'));
                link = link.substring(2);
                //make sure really long urls or the "See all stories" or "Related videos" links don't get included
                if (link.length()<=255&&!headline.contains('See all stories on this topic')&&headline != 'Related videos') {
                    alertMessages.add(htmlDecode(headline));
                    alertURLs.add(link);
                }
                //end link length if
            }
            catch (exception e) {
                System.debug('Parsing alert email for message failed: '+ e);
                return false;
            }
            //end try/catch
        }
        //end for loop
        return true;
    }
    //end method to parse for messages
    // Method to post the message to the relevant Account's chatter feed
    public Boolean postChatter(List <Account >relevantAccounts, List <String >alertMessages, List <String >alertURLs) {
        if (!alertMessages.isEmpty()&&!alertURLs.isEmpty()) {
            //ensure we don't post if there's no messages to post
            FeedItem post;
            List <FeedItem >posts = new List <FeedItem >();
            //calculate the max number of stories to post per alert 
            Integer maxStories;
            if (settings.Maximum_Stories_Per_Alert__c == null ||settings.Maximum_Stories_Per_Alert__c == 0) {
                maxStories = alertMessages.size();
            }
            else {
                maxStories = settings.Maximum_Stories_Per_Alert__c.intValue();
            }
            //post on each of the relevant accounts
            for (Account a :relevantAccounts) {
                //post each of the stories in the Google Alert
                for (Integer i = 0;
                i <maxStories;
                i ++) {
                    //changed to "alertMessages.size()"
                    try {
                        //filter out images in the Google Alert email, also filter out stories from blacklisted sources
                        if (!alertMessages [i ].contains('img border=')&&!newsSourceBlacklist.contains(alertURLs [i ].split('//')[1].split('/')[0])) {
                            post = new FeedItem();
                            post.Body = 'Google Alert - '+ alertMessages [i ];
                            post.LinkURL = alertURLs [i ];
                            post.ParentId = a.Id;
                            post.Type = 'LinkPost';
                            posts.add(post);
                        }
                        else {
                            if (maxStories <alertMessages.size()) {
                                maxStories ++;
                            }
                            //if a story was filtered out, don't count against the maximum story limit
                        }
                    }
                    catch (exception e) {
                        System.debug('Post to chatter failed: '+ e);
                        return false;
                    }
                }
                //end messages for loop
            }
            //end accounts for loop
            insert posts;
            return true;
        }
        else {
            return false;
        }
        //end empty message/alert list if/then
    }
    //end method to post chatter
    // Helper method to clear out HTML strings from headlines
    public String htmlDecode(String s) {
        s = s.replace('</b>', '');
        s = s.replace('<b>', '');
        s = s.replace('&#39;', '');
        s = s.replace('#39;', '');
        s = s.replace('&lt;', '');
        s = s.replace('&gt;', '');
        s = s.replace('&quot;', '"');
        s = s.replace('&amp;', '&');
        return s;
    }
    // Method to execute @future callouts to GoogleAlerts - called from GoogleAlertsToChatterStatusChange trigger
    @future
(callout = true)public static Void executeGoogleAlertsCallouts(List <String >methods, List <String >endpoints, List <String >bodies) {
        //variables to get the appropriate Email Service address
        String email;
        List <Google_Alert_to_Chatter_Settings__c >settings = [select Email_Services_Address__c from Google_Alert_to_Chatter_Settings__c limit 1];
        if (settings.size()>0) {
            email = settings [0].Email_Services_Address__c;
        }
        else {
            email = '';
        }
        //variables for the callouts
        HttpRequest req = new HttpRequest ();
        Http http = new Http ();
        HTTPResponse res;
        for (Integer i = 0;
        i <endpoints.size();
        i ++) {
            if (endpoints [i ]!= null) {
                //ensure that the endpoint is not null
                //compose request
                req.setMethod(methods [i ]);
                //Set HTTPRequest Method 
                req.setHeader('Content-Length', '1024');
                //Set HTTPRequest header properties
                req.setHeader('Host', 'www.google.com');
                req.setHeader('Connection', 'keep-alive');
                req.setEndpoint('http://'+ endpoints [i ]);
                req.setHeader('Date', ''+ date.today());
                //add the appropriate email if it's a signup callout
                if (bodies [i ].contains('q=')) {
                    bodies [i ]= bodies [i ]+ email;
                }
                req.setBody(bodies [i ]);
                //Set the HTTPRequest body
                //execute http callout
                try {
                    res = http.send(req);
                    //Execute web service call here   
                    //Helpful debug messages
                    //System.debug(res.toString());
                    //System.debug('Callout STATUS:'+res.getStatus());
                    //System.debug('Callout STATUS_CODE:'+res.getStatusCode()); 
                    //System.debug('Callout BODY: '+res.getBody());
                }
                catch (System.TypeException e) {
                    System.debug('Type error: '+ e);
                }
                catch (System.CalloutException e) {
                    System.debug('Callout error: '+ e + '/n Callout body: '+ res.getBody());
                }
                //end try/catch around callout
            }
            //end null endpoint if
        }
        //end for loop
    }
    //end execute callouts method
}

// end class