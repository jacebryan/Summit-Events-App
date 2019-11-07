// Copyright 2019 University of St. Thomas - Minnesota. All rights reserved.
// Use of this source code is governed by a BSD Revised
// license that can be found in the LICENSE file.
// Created by Thaddaeus Dahlberg on 5/1/2018.

public with sharing class USTEventSubmitController {
    public USTEventShared USTShared = new USTEventShared();
    public String test { get; set; }
    public USTEventShared.USTEventInfo evtInfo { get; set; }
    public UST_Event__C eventPage { get; set; }
    public UST_Event_Instance__c evtInstance { get; set; }
    public List<UST_Event_Appointment_Type__c> appts { get; set; }
    public List<UST_Event_Appointments__c> chosenAppts { get; set; }
    public String chosenFormatted { get; set; }
    public String templateSelected { get; set; }
    public String eventStartDateTimeCrumb { get; set; }

    /*Below are all private attribute*/
    // private EnrollmentrxRx__Enrollment_Opportunity__c application; //Store current application
    private Contact student; // store current Contact
    private String touchNetService;
    private String gatewayOrigin;
    private Map<String, String> mapResponse = new Map<String, String>();
    private String contactName;
    private Map<String, String> params;
    // private List<EnrollmentrxRx__Admissions_Document__c> admisDocList;
    private Map<String, String> admDocInfoMap;
    private String successLink;
    private String errorLink;
    private String cancelLink;
    private String feeTypeInfo;//get the payment type value from the url parameter.

    /*Below are all public get;set; attribute*/
    public String upayURL { get; set; }
    public String upayId { get; set; }
    public Boolean successReturnFromGateway { get; set; }
    public String ticket { get; set; }
    public String ticketName { get; set; }
    public Double paymentAmount { get; set; }
    public String docName { get; set; }
    public String docNameVal { get; set; }
    public Boolean isPayButtonShow { get; set; }
    public String docStatus { get; set; }
    public String paymentMessage { get; set; }
    public String collegeOfInterest { get; set; }
    public List<SelectOption> LLCDD { get; set; }
    public List<SelectOption> LLCDD2 { get; set; }
    public String LLC { get; set; }
    public String LLC2 { get; set; }
    public String springHousing { get; set; }
    public List<SelectOption> SPRHSNG { get; set; }
    public String applicantType { get; set; }
    public Boolean isPriorTerm { get; set; }
    public Boolean isInternational { get; set; }

    public USTEventSubmitController() {
        test = '';
        templateSelected = USTShared.defaultTemplate;

        /****** Code for Custom Payment Setting Start from here ********/
        UST_Event_Settings__c custSetting = UST_Event_Settings__c.getInstance();
        touchNetService = custSetting.Tlink_URL__c;
        upayURL = custSetting.Upay_URL__c;
        upayId = custSetting.UpayId__c;
        gatewayOrigin = custSetting.Gateway_Origin__c;
        successLink = custSetting.Deposit_Fee_Success_Link__c;//Payment Successfull redirection link
        errorLink = custSetting.Deposit_Fee_Error_Link__c;//Payment Error redirection link
        cancelLink = custSetting.Deposit_Fee_Cancel_Link__c;//In case of user click on cancel button from payment gateway
        /****** Code for Custom Payment Setting End from here ********/


        //Get cookie or URL string variable
        evtInfo = USTShared.getUSTEventInfo();
        chosenFormatted = '';
        if (!String.isEmpty(evtInfo.evtId)) {
            eventPage = [
                    SELECT Event_Name__c, Event_Submit_Title__c, Event_Submit_Description__c, Event_Footer__c, Template__c, Event_Home_Link_Title__c, Event_Home_Link_URL__c, Tracking_Submit_Registration__c
                    FROM UST_Event__c
                    WHERE Id = :evtinfo.evtId
            ][0];
            templateSelected = eventPage.Template__c;

            evtInstance = [SELECT Instance_Title__c, Start_Date_Time__c, End_Date_Time__c FROM UST_Event_Instance__c WHERE Id = :evtinfo.instanceID LIMIT 1];

            if (evtInstance.Start_Date_Time__c != null && evtInstance.End_Date_Time__c != null) {
                eventStartDateTimeCrumb = evtInstance.Start_Date_Time__c.format('MMMM d, YYYY, h:mm a') + ' - ' + evtInstance.End_Date_Time__c.format('h:mm a');
            }
        }


        if (!String.isBlank(evtinfo.evtRegId)) {
            chosenAppts = [
                    SELECT Id, Appointment_Category__c, Event_Appointment_Type__c, Appointment_Type__c, Description__c, Appointment_Title__c, Chosen_State__C
                    FROM UST_Event_Appointments__c
                    WHERE Event_Registration__c = :evtinfo.evtRegId
                    AND Chosen_State__c != 'Added but not shown'
                    ORDER BY Appointment_Title__c
            ];
            if (chosenAppts.size() > 0) {
                chosenFormatted += '<ul id="choosenAppointments">';
                for (UST_Event_appointments__c cappt : chosenAppts) {
                    chosenFormatted += '<li>';
                    chosenFormatted += cappt.Appointment_Title__c;
                    if (!String.isEmpty(cappt.Appointment_Type__c)) {
                        chosenFormatted += '<br/><em>' + cappt.Appointment_Type__c + '</em>';
                    } else if (!String.isEmpty(cappt.Description__c)) {
                        chosenFormatted += '<br/><em>' + cappt.Description__c + '</em>';
                    }
                    chosenFormatted += '</li>';
                }
                chosenFormatted += '</ul>';
            }
        }

    }

    public PageReference checkEventDetails() {
        return USTShared.checkForEvent();
    }

    public PageReference submitRegistration() {
        PageReference confirmPage = Page.USTEventConfirmation;
        return confirmPage;
    }

    public PageReference previousPage() {
        List<UST_Event_Appointment_Type__c> apptTypes = [
                SELECT Id
                From UST_Event_Appointment_Type__c
                WHERE UST_Event__c = :evtInfo.evtId
                AND (Restrict_To_Instance_Title__r.Instance_Title__c = :evtInstance.Instance_Title__c OR Restrict_To_Instance_Title__r.Instance_Title__c = null)
        ];
        PageReference lastPage;
        if (apptTypes.size() == 0) {
            //If no options skip that step
            lastPage = Page.USTEventRegister;
        } else {
            lastPage = Page.USTEventRegistrationOptions;
        }
        return lastPage;
    }


    /* Payment gateway stuff */


    /******* Below is used to generating ticket for Touchnet ********/
    public void generateTicket() {
        system.debug('paymentAmount' + paymentAmount);
        String envelop = '';

        envelop = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:typ="http://types.secureLink.touchnet.com">';
        envelop += '<soapenv:Header/>';
        envelop += '<soapenv:Body>';
        envelop += '    <typ:generateSecureLinkTicketRequest>';
        envelop += '        <typ:ticketName>' + ticketName + '</typ:ticketName>';
        envelop += '        <typ:nameValuePairs>';
        envelop += '            <typ:name>AMT</typ:name>';
        envelop += '            <typ:value>' + paymentAmount + '</typ:value>';
        envelop += '        </typ:nameValuePairs>';
        envelop += '        <typ:nameValuePairs>';
        envelop += '            <typ:name>SUCCESS_LINK</typ:name>';
        envelop += '            <typ:value>' + successLink + '</typ:value>';
        envelop += '        </typ:nameValuePairs>';
        envelop += '        <typ:nameValuePairs>';
        envelop += '            <typ:name>CANCEL_LINK</typ:name>';
        envelop += '            <typ:value>' + cancelLink + '</typ:value>';
        envelop += '        </typ:nameValuePairs>';
        envelop += '        <typ:nameValuePairs>';
        envelop += '            <typ:name>ERROR_LINK</typ:name>';
        envelop += '            <typ:value>' + errorLink + '</typ:value>';
        envelop += '        </typ:nameValuePairs>';
        envelop += '        <typ:nameValuePairs>';
        envelop += '            <typ:name>EXT_TRANS_ID</typ:name>';
        envelop += '            <typ:value>' + contactName + ' | ' + 'THAD-HERE:eventReg.Name' + '$$docName' + docNameVal + '</typ:value>';
        envelop += '        </typ:nameValuePairs>';
        envelop += '        <typ:nameValuePairs>';
        envelop += '            <typ:name>POSTING_KEY</typ:name>';
        envelop += '            <typ:value>' + docNameVal + '</typ:value>';
        envelop += '        </typ:nameValuePairs>';
        envelop += '    </typ:generateSecureLinkTicketRequest>';
        envelop += '</soapenv:Body>';
        envelop += '</soapenv:Envelope>';

        try {
            System.debug('print envelop: ' + envelop);
            System.debug('print touchNetService: ' + touchNetService);

            HTTP h = new HTTP();
            HTTPRequest r = new HTTPRequest();
            r.setEndpoint(touchNetService);
            Blob headerValue = Blob.valueOf('Enrollment:m49g3TEXu');
            String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
            System.debug('print authorizationHeader: ' + authorizationHeader);
            r.setHeader('Authorization', authorizationHeader);
            r.setHeader('SOAPAction', touchNetService);
            r.setMethod('GET');
            r.setBody(envelop);
            HTTPResponse resp = h.send(r);
            DOM.Document doc = resp.getBodyDocument();
            DOM.XMLNode root = doc.getRootElement();
            walkThrough(root);
            ticket = mapResponse.get('ticket');
            system.debug('ticket' + ticket);
        } catch (Exception ex) {
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Error connecting payment gateway, please try later!!'));
        }
    }

    @TestVisible private String walkThrough(DOM.XMLNode node) {
        String result = '\n';
        if (node.getNodeType() == DOM.XMLNodeType.COMMENT) {
            return 'Comment (' + node.getText() + ')';
        }
        if (node.getNodeType() == DOM.XMLNodeType.TEXT) {
            return 'Text (' + node.getText() + ')';
        }
        if (node.getNodeType() == DOM.XMLNodeType.ELEMENT) {
            result += 'Element: ' + node.getName();
            if (node.getText().trim() != '') {
                result += ', text=' + node.getText().trim();
                if (!mapResponse.containsKey(node.getName())) {
                    mapResponse.put(node.getName(), node.getText().trim());
                }
            }
            if (node.getAttributeCount() > 0) {
                for (Integer i = 0; i < node.getAttributeCount(); i++) {
                    result += ', attribute #' + i + ':' + node.getAttributeKeyAt(i) + '=' + node.getAttributeValue(node.getAttributeKeyAt(i), node.getAttributeKeyNsAt(i));
                }
            }
            for (Dom.XMLNode child : node.getChildElements()) {
                result += walkThrough(child);
            }
            return result;
        }
        return '';  //should never reach here
    }

    /****** Payment request to Touchnet, setting different parameters ***/

    private String getTransactionFeeName() {
        String extTransIdInfo = ApexPages.currentPage().getParameters().get('EXT_TRANS_ID');
        String feeNameValue = '';
        if (String.isNotBlank(extTransIdInfo)) {
            String[] arrTrans = extTransIdInfo.split('docName');
            if (String.isNotBlank(arrTrans[1])) {
                feeNameValue = arrTrans[1];
            }
        }
        return feeNameValue;
    }

    public PageReference addPaymentInformation() {
        PageReference pageRedirect = null;
        Savepoint sp = null;
        try {
            system.debug('@@@@@successReturnFromGateway:' + successReturnFromGateway);
            if (successReturnFromGateway) {
                String envelop = '';
                // String envelop = '<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:typ="http://types.secureLink.touchnet.com"><soapenv:Header/><soapenv:Body><typ:authorizeAccountRequest><typ:session>' + params.get('session_identifier') + '</typ:session><typ:invoiceNumber>' + application.Name + '</typ:invoiceNumber><typ:ancillaryData>EnrollmentRx Berkeley</typ:ancillaryData><typ:application>EnrollmentRx</typ:application></typ:authorizeAccountRequest></soapenv:Body></soapenv:Envelope>';
                HTTP h = new HTTP();
                HTTPRequest r = new HTTPRequest();
                r.setTimeout(120000); // timeout in milliseconds

                r.setEndpoint(touchNetService);
                Blob headerValue = Blob.valueOf('Enrollment:m49g3TEXu');
                String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);
                r.setHeader('Authorization', authorizationHeader);
                r.setHeader('SOAPAction', touchNetService);
                r.setMethod('GET');
                r.setBody(envelop);
                HTTPResponse resp = h.send(r);
                DOM.Document doc = resp.getBodyDocument();
                DOM.XMLNode root = doc.getRootElement();
                walkThrough(root);
                system.debug('###3' + root);
                system.debug('###4' + mapResponse);
                system.debug('###5' + mapResponse.get('pmt_status'));

                //check if application has payment information
                if (mapResponse.containskey('receiptNumber') && mapResponse.get('receiptNumber') != '') {

                    feeTypeInfo = getTransactionFeeName();

                    sp = Database.setSavepoint();
                    UST_Event_Payment__c paymentInformation = new UST_Event_Payment__c();
                    paymentInformation.Address_1__c = params.get('acct_addr');
                    paymentInformation.Address_2__c = params.get('acct_addr2');
                    paymentInformation.City__c = params.get('acct_city');
                    paymentInformation.Country__c = params.get('acct_country');
                    paymentInformation.Email_Address__c = params.get('acct_email_address');
                    paymentInformation.Account_Number__c = params.get('acct_number');
                    paymentInformation.Phone__c = params.get('acct_phone_mobile');
                    paymentInformation.State__c = params.get('acct_state');
                    paymentInformation.Zip__c = params.get('acct_zip');
                    paymentInformation.Card_Type__c = params.get('card_type');
                    paymentInformation.Name_On_Account__c = params.get('name_on_acct');
                    paymentInformation.Payment_Amount__c = decimal.valueOf(params.get('pmt_amt'));
                    paymentInformation.Payment_Method__c = params.get('pmt_method');
                    paymentInformation.Payment_Method_Expiration_Date__c = params.get('pmt_method_exp_date');
                    paymentInformation.Gateway_Session_Identifier__c = params.get('session_identifier');
                    paymentInformation.TouchnetReceiptNumber__c = mapResponse.get('receiptNumber');
                    paymentInformation.GatewayApprovalCode__c = mapResponse.get('approvalCode');
//                    paymentInformation.PaymentType__c = feeTypeInfo;
//                    paymentInformation.Application__c = application.Id;
                    paymentInformation.Method_of_Payment__c = 'Credit Card';
                    paymentInformation.Payment_Status__c = 'Received';
                    paymentInformation.Payment_Received_Date__c = System.Now();
                    insert paymentInformation;

                    /**** Below If and Else IF case is used to store the Payment Information Id into their respective type of payment ******//*
                    if (String.isNotBlank(feeTypeInfo) && (feeTypeInfo == 'Housing Deposit')) {
                        application.HousingDepositLookup__c = paymentInformation.Id;
                        application.Housing_Deposit_Received_Date__c = System.Now();
                    } else if (String.isNotBlank(feeTypeInfo) && (feeTypeInfo == 'Confirming Deposit')) {
                        application.ConfirmingDepositLookup__c = paymentInformation.Id;
                        application.Confirming_Deposit_Received_Date__c = System.Now();
                    } else if (String.isNotBlank(feeTypeInfo) && (feeTypeInfo == 'Both')) {
                        application.BothPaymentsLookup__c = paymentInformation.Id;
                        application.Housing_Deposit_Received_Date__c = System.Now();
                        application.Confirming_Deposit_Received_Date__c = System.Now();
                    }

                    *//**** Below If case is used to set the application admission status field to confirmed in case of payment type Both or Confirming Deposit ****//*
                    if (String.isNotBlank(feeTypeInfo) && (feeTypeInfo == 'Both' || feeTypeInfo == 'Confirming Deposit')) {
                        application.EnrollmentrxRx__Admissions_Status__c = 'Confirmed';
                    }

                    application.Payment_Information__c = paymentInformation.Id;
                    application.Payment_Status__c = true;
                    application.Payment_Mode__c = 'Credit Card';
                    update application;

                    *//**** Below If case is used to update the admisison document Info ***//*
                    if (String.isNotBlank(feeTypeInfo)) {
                        updateAdmisDoc(feeTypeInfo);
                    }
                    */


                    successReturnFromGateway = false;
                    pageRedirect = new PageReference(ApexPages.currentPage().getheaders().get('Referer'));
                    pageRedirect.setRedirect(true);
                    //Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Payment Successful: Your '+docNameVal+' fee has been successfully processed.'));
                } else {
                    successReturnFromGateway = false;
                    Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Transaction was not successful, please try again'));
                }
            }
        } catch (Exception ex) {
            Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Payment can not be processed, please try later!!' + ex));
            successReturnFromGateway = false;
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            List<String> toAddresses = new List<String>();
            toAddresses.add('dahl3702@stthomas.edu');

            // Sets the paramaters of the email
            email.setSubject('Thomas Transaction Error');
            email.setToAddresses(toAddresses);
            email.setPlainTextBody(ex.getStackTraceString() + '***' + ex.getMessage());

            // Sends the email
            Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{
                    email
            });
            if (sp != null) {
                Database.rollback(sp);
            }
        }
        return pageRedirect;
    }


}