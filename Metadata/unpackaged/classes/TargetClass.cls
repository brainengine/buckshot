public with sharing class TargetClass{
	
	public void ProcessAccount(){
		
		SourceClass sClass = new SourceClass();
		sClass.createPerson('dddd','dddd');
		
		AccountManagementService accnt = new AccountManagementService();
		accnt.createAccountPerson('Bob', 'Johnson', 'bjohnson@acme.com');
		
	}
	
	public class InnterClass{
		
		public string extFirstName {get;Set;}
		public string extLastName {get;Set;}
		
		public String ExtCreateAccountPerson(String fName, String lName, String email){
			//comment
			String fullName = fName + ' ' + lName;
			return 	fullName;
		}
		
	}


}