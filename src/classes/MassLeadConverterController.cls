/*
Copyright (c) 2011, salesforce.com, Inc.
All rights reserved.

Redistribution and use in source and binary forms, with or without modification, 
are permitted provided that the following conditions are met:

    * Redistributions of source code must retain the above copyright notice, 
    this list of conditions and the following disclaimer.
    * Redistributions in binary form must reproduce the above copyright notice, 
    this list of conditions and the following disclaimer in the documentation 
    and/or other materials provided with the distribution.
    * Neither the name of the salesforce.com, Inc. nor the names of its contributors 
    may be used to endorse or promote products derived from this software 
    without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. 
IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, 
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, 
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF 
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE 
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED 
OF THE POSSIBILITY OF SUCH DAMAGE.

*/
public with sharing class MassLeadConverterController {
 
public List<Lead> selectedItems{get;set;}
public Lead lc{get;set;} 
public Task leadTask{get;set;}
public Contact con{get;set;}
public Account acc{get;set;}
public Boolean sendEmailBox {get;set;}

public String accountName {get;set;}
public String opportunityName {get;set;}

public Boolean isEditable {get;set;}
public String oppOption {get;set;}
public List<SelectOption> oppOptions {get;set;}
public String taskOption {get;set;}
public List<SelectOption> taskOptions {get;set;}
public String accOption {get;set;}
public List<SelectOption> accOptions {get;set;}
public String errorMessages {get;set;}
List<Database.LeadConvertResult> lcr;



	public MassLeadConverterController(ApexPages.StandardSetController controller) {
		selectedItems = controller.getSelected();
		lc = new Lead();
		leadTask = new Task();
		con = new Contact();
		sendEmailBox = false;
		opportunityName = '';
		acc = new Account();
		con.AccountId = acc.Id;
		errorMessages = '';
		oppOption = 'Do not create new opportunity';
		taskOption = 'Combine all leads into a single task';
		accOption = 'Create new account';
		
		oppOptions = new List<SelectOption>();
		oppOptions.add(new SelectOption('Do not create new opportunity', 'Do not create new opportunity'));
		oppOptions.add(new SelectOption('Combine all leads into a single opportunity','Combine all leads into a single opportunity'));
		oppOptions.add(new SelectOption('Create an opportunity for each lead', 'Create an opportunity for each lead'));
		
		taskOptions = new List<SelectOption>();
		taskOptions.add(new SelectOption ('Combine all leads into a single task','Combine all leads into a single task'));
		taskOptions.add(new SelectOption ('Create a task for each lead', 'Create a task for each lead'));
		
		accOptions = new List<SelectOption>();
		accOptions.add(new SelectOption('Create new account', 'Create new account'));
		accOptions.add(new SelectOption('Add to existing account','Add to existing account'));
	
		if (selectedItems.size() <= 0)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Please select at least one lead to convert.'));
			isEditable = false;
		}
		else if (selectedItems.size() > 100)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, 'Please select fewer than 100 leads to convert.'));
			isEditable = false;
		}
		else
		{
			isEditable = true;
			accountName = selectedItems[0].Company;
			opportunityName = accountName;
			try
			{
			   User usr = [select Id from User where Id=:selectedItems[0].OwnerId];	
			   acc.OwnerId =  selectedItems[0].OwnerId;
			}
			catch (Exception ex)
			{
				acc.OwnerId = UserInfo.getUserId();
			}
		}
	}
	
	public PageReference convertLeads()
	{
		Database.LeadConvert ltc = new database.LeadConvert();
		LeadStatus convertStatus = [Select Id, MasterLabel from LeadStatus where IsConverted=true limit 1];
		List<Database.LeadConvert> leadsToConvert = new List<Database.LeadConvert>();
		
		if (accOption == 'Create new account')
		{
			//gather information from first lead and create new account
			Account acc1 = new Account();
			acc1.Name = accountName;
			acc1.Phone = selectedItems[0].Phone;
			acc1.BillingCity = selectedItems[0].City;
			acc1.BillingCountry = selectedItems[0].Country;
			acc1.BillingPostalCode = selectedItems[0].PostalCode;
			acc1.BillingState = selectedItems[0].State;
			acc1.BillingStreet = selectedItems[0].Street;
			acc1.Fax = selectedItems[0].Fax;
			acc1.Rating = selectedItems[0].Rating;
			acc1.NumberOfEmployees = selectedItems[0].NumberOfEmployees;
			acc1.Website = selectedItems[0].Website;
			if (acc.OwnerId != null)
			{
				acc1.OwnerId = acc.OwnerId;
			}
			insert acc1;
			con.AccountId = acc1.Id;
		}
		
		for (Lead myLead : selectedItems)
		{
			ltc = new database.Leadconvert();
			ltc.setConvertedStatus(convertStatus.MasterLabel);
			ltc.setLeadId(myLead.Id);
			ltc.setAccountId(con.AccountId);
			if (oppOption == 'Do not create new opportunity')
			{
				ltc.setDoNotCreateOpportunity(true);
			}
			else if (oppOption == 'Combine all leads into a single opportunity')
			{
				ltc.setDoNotCreateOpportunity(false);
				ltc.setOpportunityName(opportunityName);
				oppOption = 'Do not create new opportunity';
			}
			else if (oppOption == 'Create an opportunity for each lead')
			{
				ltc.setDoNotCreateOpportunity(false);
				ltc.setOpportunityName(opportunityName);
			}
			
			ltc.setSendNotificationEmail(sendEmailBox);
			if (acc.OwnerId != null)
			{
				ltc.setOwnerId(acc.OwnerId);
			}
			leadsToConvert.add(ltc);
		}
		
		try{			
		
			lcr = Database.convertLead(leadsToConvert);
			
			
			
		
		Task newTask = new Task();
		List<Task> tasks = new List<Task>();
		if (taskOption == 'Combine all leads into a single task')
		{
			newTask = new Task();
			newTask.WhoId = lcr[0].getContactId();
			newTask.ActivityDate = leadTask.ActivityDate;
			newTask.Subject = leadTask.Subject;
			newTask.Status = leadTask.Status;
			newTask.Description = leadTask.Description;
			newTask.Priority = leadTask.Priority;
			newTask.ReminderDateTime = leadTask.ReminderDateTime;				
			newTask.isReminderSet = leadTask.isReminderSet;
			tasks.add(newTask);			 
		}
		else
		{
			for (Database.LeadConvertResult res : lcr)
			{
				if (res.isSuccess())
				{
					newTask = new Task();
					newTask.WhoId = res.getContactId();
					newTask.ActivityDate = leadTask.ActivityDate;
					newTask.Subject = leadTask.Subject;
					newTask.Status = leadTask.Status;
					newTask.Description = leadTask.Description;
					newTask.Priority = leadTask.Priority;
					newTask.ReminderDateTime = leadTask.ReminderDateTime;
					newTask.isReminderSet = leadTask.isReminderSet;
					tasks.add(newTask);
				}
			}
		}
		insert tasks;
		
		return new PageReference('/' + lcr[0].getContactId());
		
		}
		catch(Exception ex)
		{

			errorMessages += ex.getMessage();
			if (errorMessages.contains('RECORD_IN_USE_BY_WORKFLOW'))
			{
				String[] findRow = errorMessages.split('row ');
				String[] findRowNum = findRow[1].split(';');
				Integer i = Integer.valueOf(findRowNum[0]);	
				errorMessages += '\n Cannot convert the following lead: ' + selectedItems[i].FirstName + ' ' +
				selectedItems[i].LastName + ' with Id ' + selectedItems[i].Id;		
			}
			ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessages));
						 
			return null;
		}
	}
	
	public PageReference cancel()
	{
		String retUrl = Apexpages.currentPage().getParameters().get('retUrl');
		if (retUrl == '')
		{
			return new PageReference('/');
		}
		else
		{
			return new PageReference(retUrl);
		}
		
	}

}