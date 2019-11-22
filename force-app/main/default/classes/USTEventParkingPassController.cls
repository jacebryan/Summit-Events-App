// Copyright 2019 University of St. Thomas - Minnesota. All rights reserved.
// Use of this source code is governed by a BSD Revised
// license that can be found in the LICENSE file.
// Created by Thaddaeus Dahlberg on 5/1/2018.

public with sharing class USTEventParkingPassController {
    public String couponOut { get; set; }
    public String firstName { get; set; }
    public String warning { get; set; }
    private USTEventShared USTShare = new USTEventShared();


    public USTEventParkingPassController() {
        warning = '';
        couponOut = '';
        Boolean validId = true;
        Id registrationId = null;
        String regId = ApexPages.currentPage().getParameters().get('regId');
            UST_Event_Registration__c visitor  = [SELECT Event_Instance_Date__c, Event_Instance__r.Event_Location_Time_Zone__c, Contact__r.Name, Contact__r.FirstName, Contact__r.Preferred_First_Name__c, Status__c FROM UST_Event_Registration__c WHERE id = :regId LIMIT 1];
            if (visitor != null) {
                Datetime todayDateTime = USTShare.adjustForOrgTimezone(Datetime.now(),visitor.Event_Instance__r.Event_Location_Time_Zone__c);
                DateTime todayDate = USTShare.adjustForOrgTimezone(date.newinstance(todayDateTime.year(), todayDateTime.month(), todayDateTime.day()),visitor.Event_Instance__r.Event_Location_Time_Zone__c);
                if (todayDate <= visitor.Event_Instance_Date__c && visitor.Status__c != 'Started' && visitor.Status__c != 'Cancelled') {
                    couponOut += '<p>NAME:&nbsp; ' + visitor.Contact__r.Name + '</p>';
                    couponOut += '<p>DATE VALID:&nbsp; ' + visitor.Date__c.format() + '</p>';
                    if (!String.isBlank(visitor.Contact__r.Preferred_First_Name__c)) {
                        firstName = visitor.Contact__r.Preferred_First_Name__c;
                    } else {
                        firstName = visitor.Contact__r.FirstName;
                    }
                } else {
                    warning = '<p>Sorry, this parking permit has expired or invalid. (' + regId + ')</p>';
                }
        } else {
            warning = '<p>Sorry, We could not find your parking permit ID. (' + regId + ')</p>';
        }
    }
}