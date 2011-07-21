<?xml version="1.0" encoding="UTF-8"?>
<Workflow xmlns="http://soap.sforce.com/2006/04/metadata">
    <rules>
        <fullName>Silly Lead Rule</fullName>
        <active>true</active>
        <criteriaItems>
            <field>Lead.FirstName</field>
            <operation>equals</operation>
            <value>Jane</value>
        </criteriaItems>
        <triggerType>onCreateOrTriggeringUpdate</triggerType>
    </rules>
    <tasks>
        <fullName>do_something</fullName>
        <assignedTo>j163p@labs.com</assignedTo>
        <assignedToType>user</assignedToType>
        <dueDateOffset>10</dueDateOffset>
        <notifyAssignee>false</notifyAssignee>
        <priority>Normal</priority>
        <protected>false</protected>
        <status>Not Started</status>
        <subject>do something</subject>
    </tasks>
</Workflow>
