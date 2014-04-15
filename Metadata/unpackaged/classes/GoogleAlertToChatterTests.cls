@isTest
private class GoogleAlertToChatterTests {
        
    // Test methods
    static testMethod void testGoogleAlertToChatter() {
      //setup data
      Account a = new Account();
      a.name = 'Test GATC';
      Account aprime = new Account();
      aprime.name = 'Duplicate GATC';
      aprime.Google_Alerts_to_Chatter_Status__c = 'Confirming';
      aprime.Google_Alert_Search_Term_s__c = 'Test GATC';
      Account b = new Account();
      b.name = 'Another Long Named GATC';
      Account c = new Account();
      c.name = 'Yet Another GATC';
      c.Google_Alerts_to_Chatter_Status__c = 'Sign Up';
      List<Account> bc = new List<Account>();
       bc.add(b);
       bc.add(c);
      List<AccountFeed> ps = new List<AccountFeed>();
      Integer initialPosts = 0;
      Integer beforePosts = 0;
      Integer afterPosts = 0;
      List<AccountFeed> psB = new List<AccountFeed>();
      Integer initialPostsB = 0;
      Integer beforePostsB = 0;
      Integer afterPostsB = 0;
      GoogleAlertToChatter GATC;
      
      //instantiate VF controller & set inbound email address; assert the settings record numbers
      List<Google_Alert_to_Chatter_Settings__c> settings = [select Email_Services_Address__c from Google_Alert_to_Chatter_Settings__c];
      if (settings.size() > 0) { delete settings; }
      GoogleAlertToChatterSettingsController GATCScontroller = new GoogleAlertToChatterSettingsController();
      settings = [select Email_Services_Address__c from Google_Alert_to_Chatter_Settings__c];
      System.assert(settings.size() == 0);
      GATCScontroller.emailServiceAddress = 'GATC@mailinator.com';
      GATCScontroller.updateAddress();
      settings = [select Email_Services_Address__c from Google_Alert_to_Chatter_Settings__c];
      System.assert(settings.size() == 0); //if invalid Email Services address, shouldn't insert
      GATCScontroller.emailServiceAddress = 'GATC@mailinator.apex.sandbox.salesforce.com';
      GATCScontroller.updateAddress();
      settings = [select Email_Services_Address__c from Google_Alert_to_Chatter_Settings__c];
      System.assert(settings.size() == 1);
      GATCScontroller.emailServiceAddress = 'GATC@mailinator.apex.salesforce.com';
      GATCScontroller.updateAddress();
      settings = [select Email_Services_Address__c from Google_Alert_to_Chatter_Settings__c];
      System.assert(settings.size() == 1);
      GoogleAlertToChatterSettingsController GATCScontroller2 = new GoogleAlertToChatterSettingsController();
      GATCScontroller.emailServiceAddress = 'GATC2@mailinator.apex.salesforce.com';
      GATCScontroller.updateAddress();
      settings = [select Email_Services_Address__c, News_Source_Blacklist__c, Maximum_Stories_Per_Alert__c from Google_Alert_to_Chatter_Settings__c];
      System.assert(settings.size() == 1);
      
      //sign up for an alert (test signup trigger); assert account status
      a.Google_Alerts_to_Chatter_Status__c = 'Sign Up'; //test sign up before trigger
      insert a;
      insert bc;
      b = [select id, Google_Alerts_to_Chatter_Status__c from Account where name = 'Another Long Named GATC' limit 1];
      b.Google_Alerts_to_Chatter_Status__c = 'Sign Up';
      update b;
      a = [select id, Google_Alerts_to_Chatter_Status__c from Account where name = 'Test GATC' limit 1];
      b = [select id, Google_Alerts_to_Chatter_Status__c from Account where name = 'Another Long Named GATC' limit 1];
      c = [select id, Google_Alerts_to_Chatter_Status__c, Google_Alert_Search_Term_s__c from Account where name = 'Yet Another GATC' limit 1];
      System.assertEquals('Confirming', a.Google_Alerts_to_Chatter_Status__c);
      System.assertEquals('Confirming', b.Google_Alerts_to_Chatter_Status__c);
      System.assertEquals('Confirming', c.Google_Alerts_to_Chatter_Status__c);
      System.assertEquals('Yet Another GATC', c.Google_Alert_Search_Term_s__c);
      ps = [select Id, Type from AccountFeed where ParentId = :a.Id];
      initialPosts = ps.size();
      psB = [select Id, Type from AccountFeed where ParentId = :b.Id];
      initialPosts = psB.size();
      
      //simulate the verification email (test verification processing); assert account status & cancel link
      GATC = new GoogleAlertToChatter();
      Messaging.InboundEmail verifyEmail = new Messaging.InboundEmail();
      Messaging.InboundEnvelope verifyEnvelope = new Messaging.InboundEnvelope();
      verifyEnvelope.fromAddress = 'googlealerts-noreply@google.com';
      verifyEmail.subject = 'Click to confirm your Google Alert';
      verifyEmail.plainTextBody = 'Google received a request to start sending Alerts for the search [ "Test GATC" ] to GATC@mailinator.com.  Verify this Google Alert request:  http://www.google.com/alerts/verify?gl=us&hl=en&s=AB2Xq4j7rYTTlxwDA2MJ_mdL7GPwdLWjIF1qzyQ    Cancel this Google Alert request:  http://www.google.com/alerts/remove?gl=us&hl=en&s=AB2Xq4j7rYTTlxwDA2MJ_mdL7GPwdLWjIF1qzyQ    Thanks,  The Google Alerts Team  http://www.google.com/alerts?gl=us&hl=en';
      GATC.handleInboundEmail(verifyEmail, verifyEnvelope);
      a = [select id, Google_Alerts_to_Chatter_Status__c, Google_Alert_Cancel_URL__c from Account where name = 'Test GATC' limit 1];
      System.assertEquals('Active', a.Google_Alerts_to_Chatter_Status__c);
      System.assert(a.Google_Alert_Cancel_URL__c != null);

      //simulate duplicate signup email (test duplicate processing); assert account status
      GATC = new GoogleAlertToChatter();
      insert aprime;
      Messaging.InboundEmail duplicateEmail = new Messaging.InboundEmail();
      Messaging.InboundEnvelope duplicateEnvelope = new Messaging.InboundEnvelope();
      duplicateEnvelope.fromAddress = 'googlealerts-noreply@google.com';
      duplicateEmail.subject = 'Error: Duplicate alerts';
      duplicateEmail.plainTextBody = 'You requested an alert for [ Test GATC ]. Google Alerts is already sending alerts for that topic to testaddress@mailinator.com, so a new alert was not created.  Thanks,  The Google Alerts Team  http://www.google.com/alerts?gl=us&hl=en';
      GATC.handleInboundEmail(duplicateEmail, duplicateEnvelope);
      a = [select id, Google_Alerts_to_Chatter_Status__c, Google_Alert_Cancel_URL__c from Account where name = 'Test GATC' limit 1];
      aprime = [select id, Google_Alerts_to_Chatter_Status__c, Google_Alert_Cancel_URL__c from Account where name = 'Duplicate GATC' limit 1];
      System.assertEquals('Active', a.Google_Alerts_to_Chatter_Status__c);
      System.assert(a.Google_Alert_Cancel_URL__c != null);
//      System.assertEquals('Active - Duplicate Search Term', aprime.Google_Alerts_to_Chatter_Status__c);
      System.assert(aprime.Google_Alert_Cancel_URL__c == null);

      //simulate the verification email with a truncated searchString; assert account status & cancel link
      GATC = new GoogleAlertToChatter();
      Messaging.InboundEmail verifyTruncEmail = new Messaging.InboundEmail();
      Messaging.InboundEnvelope verifyTruncEnvelope = new Messaging.InboundEnvelope();
      verifyTruncEnvelope.fromAddress = 'googlealerts-noreply@google.com';
      verifyTruncEmail.subject = 'Click to confirm your Google Alert';
      verifyTruncEmail.plainTextBody = 'Google received a request to start sending Alerts for the search [ Another Lon ... ] to GATC@mailinator.com.  Verify this Google Alert request:  http://www.google.com/alerts/verify?gl=us&hl=en&s=AB2Xq4j7rYTTlxwDA2MJ_mdL7GPwdLWjIF1qzyQ    Cancel this Google Alert request:  http://www.google.com/alerts/remove?gl=us&hl=en&s=AB2Xq4j7rYTTlxwDA2MJ_mdL7GPwdLWjIF1qzyQ    Thanks,  The Google Alerts Team  http://www.google.com/alerts?gl=us&hl=en';
      GATC.handleInboundEmail(verifyTruncEmail, verifyTruncEnvelope);
      b = [select id, Google_Alerts_to_Chatter_Status__c, Google_Alert_Cancel_URL__c from Account where name = 'Another Long Named GATC' limit 1];
      System.assertEquals('Active', b.Google_Alerts_to_Chatter_Status__c);
      System.assert(a.Google_Alert_Cancel_URL__c != null);
      
      //simulate a Google Alert email (test message parsing); assert chatter post
      GATC = new GoogleAlertToChatter();
      Messaging.InboundEmail alertEmail = new Messaging.InboundEmail();
      Messaging.InboundEnvelope alertEnvelope = new Messaging.InboundEnvelope();
      alertEnvelope.fromAddress = 'googlealerts-noreply@google.com';
      alertEmail.subject = 'Google Alert - "Test GATC"';
      alertEmail.htmlBody = '<html><head></head><body><div style="font-family: sans-serif"><p><font size="+1">Google News Alert for: <b>Test GATC</b></font></p><table cellpadding="0" cellspacing="0" border="0" width="600"><tr><td style="padding-bottom:1em"><a style="color: blue" href="http://www.google.com/url?sa=X&amp;q=http://news.alibaba.com/article/detail/business-in-china/100270384-1-nine-dragons-sees-substantial-profit.html&amp;ct=ga&amp;cad=7:1:0&amp;cd=YWBjhbfhmFg&amp;usg=AFQjCNFYsyO0MOWt1wipAE3xDyLQ84Ms1w">Nine <b>Dragons</b> sees substantial profit increase in H2 2009</a><br><font size="-1"><font color="#666666">Alibaba News Channel</font><br>31, 2010 (China Knowledge) - Nine <b>Dragons</b> Paper Holdings Ltd&lt;2689&gt;, the leading paperboard producer in mainland China, yesterday said that its net profit <b>...</b><br><a style="color: green" href="http://news.google.com/news/story?ncl=http://news.alibaba.com/article/detail/business-in-china/100270384-1-nine-dragons-sees-substantial-profit.html&amp;hl=en" title="http://news.google.com/news/story?ncl=http://news.alibaba.com/article/detail/business-in-china/100270384-1-nine-dragons-sees-substantial-profit.html&amp;hl=en">See all stories on this topic</a></font></td></tr><tr><td style="padding-bottom:1em"><a style="color: blue" href="http://www.google.com/url?sa=X&amp;q=http://online.wsj.com/article/BT-CO-20100329-707916.html&amp;ct=ga&amp;cad=7:1:0&amp;cd=YWBjhbfhmFg&amp;usg=AFQjCNFQNx98sSkI00Lfmw3E7j7KJuhWSg"><img src="testimage.jpg">sUS HOT STOCKS: Dreamworks, Apollo Group, Bell Microproducts</a><br><font size="-1"><font color="#666666">Wall Street Journal</font><br>On the first weekend when many theater owners introduced significant movie-ticket price increases, &quot;How to Train Your <b>Dragon</b>&quot; took in $43.3 million at the <b>...</b><br><a style="color: green" href="http://news.google.com/news/story?ncl=http://online.wsj.com/article/BT-CO-20100329-707916.html&amp;hl=en" title="http://news.google.com/news/story?ncl=http://online.wsj.com/article/BT-CO-20100329-707916.html&amp;hl=en">See all stories on this topic</a></font></td></tr></table><p><hr noshade size=1><font size="-1">Tip: Use quotes ("like this") around a set of words in your query to match them exactly. <a href="http://www.google.com/support/websearch/bin/answer.py?answer=136861&amp;hl=en&amp;gl=us&amp;source=alertsmail&amp;cd=YWBjhbfhmFg&amp;cad=7:1:0">Learn more</a>.</font><p><font size="-1"> <nobr><a href="http://www.google.com/alerts/remove?s=AB2Xq4j27eODgzz_Bpw_sOKmOXjGOXzXB73pBBw&amp;hl=en&amp;gl=us&amp;source=alertsmail&amp;cd=YWBjhbfhmFg&amp;cad=7:1:0">Remove</a> this alert.</nobr> <br><a href="http://www.google.com/alerts?hl=en&amp;gl=us&amp;source=alertsmail&amp;cd=YWBjhbfhmFg&amp;cad=7:1:0">Create</a> another alert.<br><a href="http://www.google.com/alerts/manage?hl=en&amp;gl=us&amp;source=alertsmail&amp;cd=YWBjhbfhmFg&amp;cad=7:1:0">Manage</a> your alerts.</font></p></div></body></html>';
      GATC.handleInboundEmail(alertEmail, alertEnvelope);
      ps = [select Id, Type from AccountFeed where ParentId = :a.Id];
      afterPosts = ps.size();
      System.assert(afterPosts > initialPosts);
      initialPosts = ps.size();

      //simulate a Google Alert email (too long url); assert no chatter post
      GATC = new GoogleAlertToChatter();
      Messaging.InboundEmail alertLongEmail = new Messaging.InboundEmail();
      Messaging.InboundEnvelope alertLongEnvelope = new Messaging.InboundEnvelope();
      alertLongEnvelope.fromAddress = 'googlealerts-noreply@google.com';
      alertLongEmail.subject = 'Google Alert - "Test GATC"';
      alertLongEmail.htmlBody = '<html><head></head><body><div style="font-family: sans-serif"><p><font size="+1">Google News Alert for: <b>Test GATC</b></font></p><table cellpadding="0" cellspacing="0" border="0" width="600"><tr><td style="padding-bottom:1em"><a style="color: blue" href="http://www.google.com/url?sa=X&amp;q=http://www.tmcnet.com/channels/crm-cloud-computing/articles/81511-cameleon-software-launches-its-new-app-salesforcecoms-chatterexchange.htmAFQjCNFysS5UObJBbub1wjFVCRBl7ZdyVQAFQjCNFysS5UObJBbub1wjFVCRBl7ZdyVQAFQjCNFysS5UObJBbub1wjFVCRBl7ZdyVQAFQjCNFysS5UObJBbub1wjFVCRBl7ZdyVQAFQjCNFysS5UObJBbub1wjFVCRBl7ZdyVQAFQjCNFysS5UObJBbub1wjFVCRBl7ZdyVQAFQjCNFysS5UObJBbub1wjFVCRBl7ZdyVQAFQjCNFysS5UObJBbub1wjFVCRBl7ZdyVQAFQjCNFysS5UObJBbub1wjFVCRBl7ZdyVQAFQjCNFysS5UObJBbub1wjFVCRBl7ZdyVQAFQjCNFysS5UObJBbub1wjFVCRBl7ZdyVQAFQjCNFysS5UObJBbub1wjFVCRBl7ZdyVQ&amp;ct=ga">Nine <b>Dragons</b> sees substantial profit increase in H2 2009</a>See all stories on this topic</a></font></td></tr></table><p><hr noshade size=1><font size="-1">Tip: Use quotes ("like this") around a set of words in your query to match them exactly. <a href="http://www.google.com/support/websearch/bin/answer.py?answer=136861&amp;hl=en&amp;gl=us&amp;source=alertsmail&amp;cd=YWBjhbfhmFg&amp;cad=7:1:0">Learn more</a>.</font><p><font size="-1"> <nobr><a href="http://www.google.com/alerts/remove?s=AB2Xq4j27eODgzz_Bpw_sOKmOXjGOXzXB73pBBw&amp;hl=en&amp;gl=us&amp;source=alertsmail&amp;cd=YWBjhbfhmFg&amp;cad=7:1:0">Remove</a> this alert.</nobr> <br><a href="http://www.google.com/alerts?hl=en&amp;gl=us&amp;source=alertsmail&amp;cd=YWBjhbfhmFg&amp;cad=7:1:0">Create</a> another alert.<br><a href="http://www.google.com/alerts/manage?hl=en&amp;gl=us&amp;source=alertsmail&amp;cd=YWBjhbfhmFg&amp;cad=7:1:0">Manage</a> your alerts.</font></p></div></body></html>';
      ps = [select Id, Type from AccountFeed where ParentId = :a.Id];
      beforePosts = ps.size();
      GATC.handleInboundEmail(alertLongEmail, alertLongEnvelope);
      ps = [select Id, Type from AccountFeed where ParentId = :a.Id];
      afterPosts = ps.size();
      System.assertEquals(afterPosts, beforePosts);
      initialPosts = ps.size();
      
      //simulate a Google Alert email with a truncated searchString; assert chatter post
      GATC = new GoogleAlertToChatter();
      Messaging.InboundEmail alertTruncEmail = new Messaging.InboundEmail();
      Messaging.InboundEnvelope alertTruncEnvelope = new Messaging.InboundEnvelope();
      alertTruncEnvelope.fromAddress = 'googlealerts-noreply@google.com';
      alertTruncEmail.subject = 'Google Alert - Another Lon ...';
      alertTruncEmail.htmlBody = '<html><head></head><body><div style="font-family: sans-serif"><p><font size="+1">Google News Alert for: <b>Another Lon ...</b></font></p><table cellpadding="0" cellspacing="0" border="0" width="600"><tr><td style="padding-bottom:1em"><a style="color: blue" href="http://www.google.com/url?sa=X&amp;q=http://news.alibaba.com/article/detail/business-in-china/100270384-1-nine-dragons-sees-substantial-profit.html&amp;ct=ga&amp;cad=7:1:0&amp;cd=YWBjhbfhmFg&amp;usg=AFQjCNFYsyO0MOWt1wipAE3xDyLQ84Ms1w">Nine <b>Dragons</b> sees substantial profit increase in H2 2009</a><br><font size="-1"><font color="#666666">Alibaba News Channel</font><br>31, 2010 (China Knowledge) - Nine <b>Dragons</b> Paper Holdings Ltd&lt;2689&gt;, the leading paperboard producer in mainland China, yesterday said that its net profit <b>...</b><br><a style="color: green" href="http://news.google.com/news/story?ncl=http://news.alibaba.com/article/detail/business-in-china/100270384-1-nine-dragons-sees-substantial-profit.html&amp;hl=en" title="http://news.google.com/news/story?ncl=http://news.alibaba.com/article/detail/business-in-china/100270384-1-nine-dragons-sees-substantial-profit.html&amp;hl=en">See all stories on this topic</a></font></td></tr><tr><td style="padding-bottom:1em"><a style="color: blue" href="http://www.google.com/url?sa=X&amp;q=http://online.wsj.com/article/BT-CO-20100329-707916.html&amp;ct=ga&amp;cad=7:1:0&amp;cd=YWBjhbfhmFg&amp;usg=AFQjCNFQNx98sSkI00Lfmw3E7j7KJuhWSg"><img src="testimage.jpg">sUS HOT STOCKS: Dreamworks, Apollo Group, Bell Microproducts</a><br><font size="-1"><font color="#666666">Wall Street Journal</font><br>On the first weekend when many theater owners introduced significant movie-ticket price increases, &quot;How to Train Your <b>Dragon</b>&quot; took in $43.3 million at the <b>...</b><br><a style="color: green" href="http://news.google.com/news/story?ncl=http://online.wsj.com/article/BT-CO-20100329-707916.html&amp;hl=en" title="http://news.google.com/news/story?ncl=http://online.wsj.com/article/BT-CO-20100329-707916.html&amp;hl=en">See all stories on this topic</a></font></td></tr></table><p><hr noshade size=1><font size="-1">Tip: Use quotes ("like this") around a set of words in your query to match them exactly. <a href="http://www.google.com/support/websearch/bin/answer.py?answer=136861&amp;hl=en&amp;gl=us&amp;source=alertsmail&amp;cd=YWBjhbfhmFg&amp;cad=7:1:0">Learn more</a>.</font><p><font size="-1"> <nobr><a href="http://www.google.com/alerts/remove?s=AB2Xq4j27eODgzz_Bpw_sOKmOXjGOXzXB73pBBw&amp;hl=en&amp;gl=us&amp;source=alertsmail&amp;cd=YWBjhbfhmFg&amp;cad=7:1:0">Remove</a> this alert.</nobr> <br><a href="http://www.google.com/alerts?hl=en&amp;gl=us&amp;source=alertsmail&amp;cd=YWBjhbfhmFg&amp;cad=7:1:0">Create</a> another alert.<br><a href="http://www.google.com/alerts/manage?hl=en&amp;gl=us&amp;source=alertsmail&amp;cd=YWBjhbfhmFg&amp;cad=7:1:0">Manage</a> your alerts.</font></p></div></body></html>';
      GATC.handleInboundEmail(alertTruncEmail, alertTruncEnvelope);
      psB = [select Id, Type from AccountFeed where ParentId = :b.Id];
      afterPostsB = psB.size();
      System.assert(afterPostsB > initialPostsB);
      
      //simulate an invalid email (test negative case); assert no chatter post
      GATC = new GoogleAlertToChatter();
      Messaging.InboundEmail invalidEmail = new Messaging.InboundEmail();
      Messaging.InboundEnvelope invalidEnvelope = new Messaging.InboundEnvelope();
      invalidEnvelope.fromAddress = 'googlealerts-noreply@google.com';
      invalidEmail.subject = 'Invalid Email Subject';
      invalidEmail.plainTextBody = 'This email should not be parsed by the Google Alert to Chatter application.';
      GATC.handleInboundEmail(invalidEmail, invalidEnvelope);
      ps = [select Id, Type from AccountFeed where ParentId = :a.Id];
      System.assertEquals(ps.size(), afterPosts);

      //simulate a Google Alert email from a blacklisted source; assert no chatter post
      GATCScontroller.newsSourceBlacklist = 'www.nytimes.com';
      GATCScontroller.updateBlacklist();
      GATC = new GoogleAlertToChatter();
      Messaging.InboundEmail blacklistEmail = new Messaging.InboundEmail();
      Messaging.InboundEnvelope blacklistEnvelope = new Messaging.InboundEnvelope();
      blacklistEnvelope.fromAddress = 'googlealerts-noreply@google.com';
      blacklistEmail.subject = 'Google Alert - "Test GATC"';
      blacklistEmail.htmlBody = '<html><head></head><body><div style="font-family: sans-serif"><p><font size="+1">Google News Alert for: <b>Test GATC</b></font></p><table cellpadding="0" cellspacing="0" border="0" width="600"><tr><td style="padding-bottom:1em"><a style="color: blue" href="http://www.google.com/url?sa=X&amp;q=http://www.nytimes.com/2010/08/25/business/25econ.html&amp;ct=ga&amp;cad=7:1:0&amp;cd=YWBjhbfhmFg&amp;usg=AFQjCNFYsyO0MOWt1wipAE3xDyLQ84Ms1w">Nine <b>Dragons</b> sees substantial profit increase in H2 2009</a><br><font size="-1"><font color="#666666">Alibaba News Channel</font><br>31, 2010 (China Knowledge) - Nine <b>Dragons</b> Paper Holdings Ltd&lt;2689&gt;, the leading paperboard producer in mainland China, yesterday said that its net profit <b>...</b><br><a style="color: green" href="http://news.google.com/news/story?ncl=http://www.nytimes.com/2010/08/25/business/25econ.html&amp;hl=en" title="http://news.google.com/news/story?ncl=http://www.nytimes.com/2010/08/25/business/25econ.html&amp;hl=en">See all stories on this topic</a></font></td></tr><tr><td style="padding-bottom:1em"><a style="color: blue" href="http://www.google.com/url?sa=X&amp;q=http://www.nytimes.com/2010/08/25/business/25econ.html&amp;ct=ga&amp;cad=7:1:0&amp;cd=YWBjhbfhmFg&amp;usg=AFQjCNFQNx98sSkI00Lfmw3E7j7KJuhWSg"><img src="testimage.jpg">sUS HOT STOCKS: Dreamworks, Apollo Group, Bell Microproducts</a><br><font size="-1"><font color="#666666">Wall Street Journal</font><br>On the first weekend when many theater owners introduced significant movie-ticket price increases, &quot;How to Train Your <b>Dragon</b>&quot; took in $43.3 million at the <b>...</b><br><a style="color: green" href="http://news.google.com/news/story?ncl=http://www.nytimes.com/2010/08/25/business/25econ.html&amp;hl=en" title="http://news.google.com/news/story?ncl=http://www.nytimes.com/2010/08/25/business/25econ.html&amp;hl=en">See all stories on this topic</a></font></td></tr></table><p><hr noshade size=1><font size="-1">Tip: Use quotes ("like this") around a set of words in your query to match them exactly. <a href="http://www.google.com/support/websearch/bin/answer.py?answer=136861&amp;hl=en&amp;gl=us&amp;source=alertsmail&amp;cd=YWBjhbfhmFg&amp;cad=7:1:0">Learn more</a>.</font><p><font size="-1"> <nobr><a href="http://www.google.com/alerts/remove?s=AB2Xq4j27eODgzz_Bpw_sOKmOXjGOXzXB73pBBw&amp;hl=en&amp;gl=us&amp;source=alertsmail&amp;cd=YWBjhbfhmFg&amp;cad=7:1:0">Remove</a> this alert.</nobr> <br><a href="http://www.google.com/alerts?hl=en&amp;gl=us&amp;source=alertsmail&amp;cd=YWBjhbfhmFg&amp;cad=7:1:0">Create</a> another alert.<br><a href="http://www.google.com/alerts/manage?hl=en&amp;gl=us&amp;source=alertsmail&amp;cd=YWBjhbfhmFg&amp;cad=7:1:0">Manage</a> your alerts.</font></p></div></body></html>';
      GATC.handleInboundEmail(blacklistEmail, blacklistEnvelope);
      ps = [select Id, Type from AccountFeed where ParentId = :a.Id];
      System.assertEquals(ps.size(), initialPosts);
      initialPosts = ps.size();
      
      //simulate a Google Alert email with more than the max stories (1); assert small number of chatter post
      GATCScontroller.maxStoriesPerAlert = 1;
      GATCScontroller.updateMaxStories();
      GATC = new GoogleAlertToChatter();
      Messaging.InboundEmail maxEmail = new Messaging.InboundEmail();
      Messaging.InboundEnvelope maxEnvelope = new Messaging.InboundEnvelope();
      maxEnvelope.fromAddress = 'googlealerts-noreply@google.com';
      maxEmail.subject = 'Google Alert - "Test GATC"';
      maxEmail.htmlBody = '<html><head></head><body><div style="font-family: sans-serif"><p><font size="+1">Google News Alert for: <b>Another Lon ...</b></font></p><table cellpadding="0" cellspacing="0" border="0" width="600"><tr><td style="padding-bottom:1em"><a style="color: blue" href="http://www.google.com/url?sa=X&amp;q=http://news.alibaba.com/article/detail/business-in-china/100270384-1-nine-dragons-sees-substantial-profit.html&amp;ct=ga&amp;cad=7:1:0&amp;cd=YWBjhbfhmFg&amp;usg=AFQjCNFYsyO0MOWt1wipAE3xDyLQ84Ms1w">Nine <b>Dragons</b> sees substantial profit increase in H2 2009</a><br><font size="-1"><font color="#666666">Alibaba News Channel</font><br>31, 2010 (China Knowledge) - Nine <b>Dragons</b> Paper Holdings Ltd&lt;2689&gt;, the leading paperboard producer in mainland China, yesterday said that its net profit <b>...</b><br><a style="color: green" href="http://news.google.com/news/story?ncl=http://news.alibaba.com/article/detail/business-in-china/100270384-1-nine-dragons-sees-substantial-profit.html&amp;hl=en" title="http://news.google.com/news/story?ncl=http://news.alibaba.com/article/detail/business-in-china/100270384-1-nine-dragons-sees-substantial-profit.html&amp;hl=en">See all stories on this topic</a></font></td></tr><tr><td style="padding-bottom:1em"><a style="color: blue" href="http://www.google.com/url?sa=X&amp;q=http://online.wsj.com/article/BT-CO-20100329-707916.html&amp;ct=ga&amp;cad=7:1:0&amp;cd=YWBjhbfhmFg&amp;usg=AFQjCNFQNx98sSkI00Lfmw3E7j7KJuhWSg"><img src="testimage.jpg">sUS HOT STOCKS: Dreamworks, Apollo Group, Bell Microproducts</a><br><font size="-1"><font color="#666666">Wall Street Journal</font><br>On the first weekend when many theater owners introduced significant movie-ticket price increases, &quot;How to Train Your <b>Dragon</b>&quot; took in $43.3 million at the <b>...</b><br><a style="color: green" href="http://news.google.com/news/story?ncl=http://online.wsj.com/article/BT-CO-20100329-707916.html&amp;hl=en" title="http://news.google.com/news/story?ncl=http://online.wsj.com/article/BT-CO-20100329-707916.html&amp;hl=en">See all stories on this topic</a></font></td></tr></table><p><hr noshade size=1><font size="-1">Tip: Use quotes ("like this") around a set of words in your query to match them exactly. <a href="http://www.google.com/support/websearch/bin/answer.py?answer=136861&amp;hl=en&amp;gl=us&amp;source=alertsmail&amp;cd=YWBjhbfhmFg&amp;cad=7:1:0">Learn more</a>.</font><p><font size="-1"> <nobr><a href="http://www.google.com/alerts/remove?s=AB2Xq4j27eODgzz_Bpw_sOKmOXjGOXzXB73pBBw&amp;hl=en&amp;gl=us&amp;source=alertsmail&amp;cd=YWBjhbfhmFg&amp;cad=7:1:0">Remove</a> this alert.</nobr> <br><a href="http://www.google.com/alerts?hl=en&amp;gl=us&amp;source=alertsmail&amp;cd=YWBjhbfhmFg&amp;cad=7:1:0">Create</a> another alert.<br><a href="http://www.google.com/alerts/manage?hl=en&amp;gl=us&amp;source=alertsmail&amp;cd=YWBjhbfhmFg&amp;cad=7:1:0">Manage</a> your alerts.</font></p></div></body></html>';
      GATC.handleInboundEmail(maxEmail, maxEnvelope);
      ps = [select Id, Type from AccountFeed where ParentId = :a.Id];
      System.assertEquals(ps.size(), initialPosts+1);
      initialPosts = ps.size();
      
      //simulate a Google Alert email with max stories set to 0; assert two chatter posts
      GATCScontroller.maxStoriesPerAlert = 0;
      GATCScontroller.updateMaxStories();
      GATC = new GoogleAlertToChatter();
      Messaging.InboundEmail max0Email = new Messaging.InboundEmail();
      Messaging.InboundEnvelope max0Envelope = new Messaging.InboundEnvelope();
      max0Envelope.fromAddress = 'googlealerts-noreply@google.com';
      max0Email.subject = 'Google Alert - "Test GATC"';
      max0Email.htmlBody = '<html><head></head><body><div style="font-family: sans-serif"><p><font size="+1">Google News Alert for: <b>Another Lon ...</b></font></p><table cellpadding="0" cellspacing="0" border="0" width="600"><tr><td style="padding-bottom:1em"><a style="color: blue" href="http://www.google.com/url?sa=X&amp;q=http://news.alibaba.com/article/detail/business-in-china/100270384-1-nine-dragons-sees-substantial-profit.html&amp;ct=ga&amp;cad=7:1:0&amp;cd=YWBjhbfhmFg&amp;usg=AFQjCNFYsyO0MOWt1wipAE3xDyLQ84Ms1w">Nine <b>Dragons</b> sees substantial profit increase in H2 2009</a><br><font size="-1"><font color="#666666">Alibaba News Channel</font><br>31, 2010 (China Knowledge) - Nine <b>Dragons</b> Paper Holdings Ltd&lt;2689&gt;, the leading paperboard producer in mainland China, yesterday said that its net profit <b>...</b><br><a style="color: green" href="http://news.google.com/news/story?ncl=http://news.alibaba.com/article/detail/business-in-china/100270384-1-nine-dragons-sees-substantial-profit.html&amp;hl=en" title="http://news.google.com/news/story?ncl=http://news.alibaba.com/article/detail/business-in-china/100270384-1-nine-dragons-sees-substantial-profit.html&amp;hl=en">See all stories on this topic</a></font></td></tr><tr><td style="padding-bottom:1em"><a style="color: blue" href="http://www.google.com/url?sa=X&amp;q=http://online.wsj.com/article/BT-CO-20100329-707916.html&amp;ct=ga&amp;cad=7:1:0&amp;cd=YWBjhbfhmFg&amp;usg=AFQjCNFQNx98sSkI00Lfmw3E7j7KJuhWSg"><img src="testimage.jpg">sUS HOT STOCKS: Dreamworks, Apollo Group, Bell Microproducts</a><br><font size="-1"><font color="#666666">Wall Street Journal</font><br>On the first weekend when many theater owners introduced significant movie-ticket price increases, &quot;How to Train Your <b>Dragon</b>&quot; took in $43.3 million at the <b>...</b><br><a style="color: green" href="http://news.google.com/news/story?ncl=http://online.wsj.com/article/BT-CO-20100329-707916.html&amp;hl=en" title="http://news.google.com/news/story?ncl=http://online.wsj.com/article/BT-CO-20100329-707916.html&amp;hl=en">See all stories on this topic</a></font></td></tr></table><p><hr noshade size=1><font size="-1">Tip: Use quotes ("like this") around a set of words in your query to match them exactly. <a href="http://www.google.com/support/websearch/bin/answer.py?answer=136861&amp;hl=en&amp;gl=us&amp;source=alertsmail&amp;cd=YWBjhbfhmFg&amp;cad=7:1:0">Learn more</a>.</font><p><font size="-1"> <nobr><a href="http://www.google.com/alerts/remove?s=AB2Xq4j27eODgzz_Bpw_sOKmOXjGOXzXB73pBBw&amp;hl=en&amp;gl=us&amp;source=alertsmail&amp;cd=YWBjhbfhmFg&amp;cad=7:1:0">Remove</a> this alert.</nobr> <br><a href="http://www.google.com/alerts?hl=en&amp;gl=us&amp;source=alertsmail&amp;cd=YWBjhbfhmFg&amp;cad=7:1:0">Create</a> another alert.<br><a href="http://www.google.com/alerts/manage?hl=en&amp;gl=us&amp;source=alertsmail&amp;cd=YWBjhbfhmFg&amp;cad=7:1:0">Manage</a> your alerts.</font></p></div></body></html>';
      GATC.handleInboundEmail(max0Email, max0Envelope);
      ps = [select Id, Type from AccountFeed where ParentId = :a.Id];
      System.assertEquals(ps.size(), initialPosts+2);
      initialPosts = ps.size();
      
      //test running the settings controller if there's already a setting record
      GATCScontroller.maxStoriesPerAlert = 1;
      GATCScontroller.updateMaxStories();
      GATCScontroller = new GoogleAlertToChatterSettingsController();
      GATCScontroller.maxStoriesPerAlert = null;
      GATCScontroller.updateMaxStories();

      //cancel alert (test cancel trigger); assert account status
      a.Google_Alerts_to_Chatter_Status__c = 'Cancel';
      update a;
      a = [select id, Google_Alerts_to_Chatter_Status__c, Google_Alert_Cancel_URL__c from Account where name = 'Test GATC' limit 1];
      System.assertEquals(null, a.Google_Alert_Cancel_URL__c);
      System.assertEquals('Inactive', a.Google_Alerts_to_Chatter_Status__c);
      
      //sign up for alert & delete
      delete b;
      
      //clean up
      delete a;
      delete c;
      delete aprime;
      
    }// end test method
}