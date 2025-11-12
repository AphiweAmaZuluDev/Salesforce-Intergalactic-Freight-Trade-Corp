# **Intergalactic Freight & Trade Corp — Technical Documentation**

This documentation is generated from the live org (aphiwe.zulu852@agentforce.com) and aligned with the source in this repository. It inventories the data model, automation (flows, triggers), Apex code, UI components, and operational practices.

Last updated: 2025-11-11  
Org: aphiwe.zulu852@agentforce.com (API v65.0)

## **Contents**

* [Sandbox Access & Test Users](https://www.google.com/search?q=%23sandbox-access--test-users)  
* [Overview](https://www.google.com/search?q=%23overview)  
* [Architecture](https://www.google.com/search?q=%23architecture)  
* [Data Model](https://www.google.com/search?q=%23data-model)  
* [Automation (Flows, Triggers, Validation Rules)](https://www.google.com/search?q=%23automation)  
* [Apex](https://www.google.com/search?q=%23apex)  
* [UI (LWC, Aura, Visualforce, Apps/Pages)](https://www.google.com/search?q=%23ui)  
* [Integrations and Data Cloud Streams](https://www.google.com/search?q=%23integrations-and-data-cloud-streams)  
* [Security and Access](https://www.google.com/search?q=%23security-and-access)  
* [Operations (Deploy, Test, Troubleshoot)](https://www.google.com/search?q=%23operations)  
* [Appendix (List Views, Web Links, Known Gaps)](https://www.google.com/search?q=%23appendix)  
* [Change Log](https://www.google.com/search?q=%23change-log)

## **Sandbox Access & Test Users**

Login to the development/demo org using the credentials below.

**Login URL:** https://orgfarm-f26eb6866c-dev-ed.develop.my.salesforce.com/

### **Test User Credentials**

* **Role:** Operations Manager  
* **Username:** operationsmanager1@testuser.com  
* **Password:** eCYwz2PsJg6KR6i  
* **Role:** Freight Agent  
* **Username:** freightagent1@testuser.com  
* **Password:** 34Wb7VEwuQiSbUt

## **Overview**

Intergalactic Freight & Trade Corp manages shipments across planetary systems. This Salesforce package provides:

* Shipment planning and execution  
* Cargo assignment to available freight agents  
* Automated fuel cost calculation and ETA management  
* Customs documentation generation and linkage  
* Real-time shipment tracking UI components  
* Event ingestion (Data Cloud streams) for route metrics

## **Architecture**

* **Core objects:** Shipment\_\_c, Cargo\_\_c, Customs\_Document\_\_c, Customs\_Document\_Cargo\_Link\_\_c  
* **Relationships:**  
  * Cargo\_\_c.Shipment\_\_c (lookup to Shipment)  
  * Shipment\_\_c.Recipient\_\_c and Shipment\_\_c.Sender\_\_c (lookups to Contact)  
  * Customs\_Document\_\_c.Shipment\_\_c and Customs\_Document\_\_c.Cargo\_\_c  
  * Customs\_Document\_Cargo\_Link\_\_c bridges Customs\_Document\_\_c and Cargo\_\_c (enforces same-shipment validation)  
* **Automation:**  
  * Flows: Assign agent, calculate fuel, set/clear delivered date, delayed shipment notification, route metrics subscriber  
  * Triggers: Shipment management, cargo bulk processing, customs generators and link validation guard  
* **Code:**  
  * Service/logic classes: FuelCostCalculator, CustomsClearanceService, BulkShipmentProcessor, TriggerHandlerGuard  
  * Controllers: ShipmentTrackerController (LWC), QuickCargoAssignerController (Aura), FuelCostFlowAction (invocable)  
* **UI:**  
  * LWC realTimeTracking  
  * Aura QuickCargoAssigner  
  * Visualforce ShipmentSummaryPage  
* **Streaming/Data Cloud:**  
  * DataStreamDefinitions for Shipment, Shipping Route, Route Legs and Planetary Systems

## **Data Model**

### **Shipment\_\_c**

* **Key fields:**  
  * Departure\_Date\_\_c (Date)  
  * ETA\_\_c (Date/Time) \[VR: must be after departure\]  
  * Origin\_Planetary\_System\_\_c, Destination\_Planetary\_System\_\_c (Lookup/Text)  
  * Fuel\_Cost\_\_c (Currency) \[set by FuelCostCalculator/Flow\]  
  * Total\_Weight\_\_c (Number) \[rollup/summarized from Cargo\]  
  * Is\_Delayed\_\_c (Checkbox) \[set by Check\_for\_Delays Flow\]  
  * Total\_Delivery\_Time\_\_c (Number)  
  * Delay\_Likelihood\_Score\_Data\_Cloud\_\_c (Number) \[from Data Cloud\]  
  * Recipient\_\_c, Sender\_\_c (Lookup(Contact))  
  * Status\_\_c, Shipping\_Method\_\_c (Picklists)  
  * Suggested\_Shipping\_Route\_\_c, Estimated\_Direct\_Distance\_\_c  
  * Date\_Delivered\_\_c (Date) \[managed by Set/Remove Date Delivered Flows\]  
* **Validation Rules:**  
  * ETA\_Must\_Be\_After\_Departure\_Date  
  * Total\_Cargo\_Weight\_Within\_Ship\_Capacity (see VRs)  
* **List Views:** All

### **Cargo\_\_c**

* **Fields:**  
  * Shipment\_\_c (Lookup Shipment\_\_c)  
  * Agent\_\_c (Lookup/User or custom agent)  
  * Weight\_\_c (Number)  
  * Category\_\_c (Picklist)  
  * Description\_\_c (Text)  
* **List Views:** All

### **Customs\_Document\_\_c**

* **Fields:**  
  * Shipment\_\_c (Lookup)  
  * Cargo\_\_c (Lookup)  
  * Clearance\_Status\_\_c (Picklist: e.g., Submitted/Approved/Rejected)  
  * Date\_Submitted\_\_c (Date)  
  * Rejection\_Reason\_\_c (Text)  
* **List Views:** All

### **Customs\_Document\_Cargo\_Link\_\_c**

* **Junction:** between Customs\_Document\_\_c and Cargo\_\_c  
* **Validation:**  
  * Cargo\_Must\_Be\_From\_Shipment (cargo must belong to the same shipment as the customs doc)  
* **List Views:** All

### **Standard Objects in scope**

* **Account:** SLA\_\_c, SLAExpirationDate\_\_c, SLASerialNumber\_\_c, Active\_\_c, NumberofLocations\_\_c  
* **Opportunity:** TrackingNumber\_\_c, DeliveryStatus (WebLink), standard sales fields  
* **Contact:** various test fields (rh2\_\_\*) and demographics

## **Automation**

### **Flows (force-app/main/default/flows)**

* **Assign\_Shipment\_to\_Available\_Freight\_Agent**  
  * **Purpose:** On creation/update, assign a shipment to an available agent.  
  * **Notes:** Can lock User records during tests; test failures show UNABLE\_TO\_LOCK\_ROW in concurrent updates.  
* **Calculate\_Fuel\_Cost**  
  * **Purpose:** Compute Fuel\_Cost\_\_c for Shipment using FuelCostCalculator.  
  * **Entry:** Autolaunched/from invocable.  
* **Check\_for\_Delays**  
  * **Purpose:** Derive Is\_Delayed\_\_c based on ETA, route metrics, and events.  
* **Notify\_of\_Delayed\_Shipment**  
  * **Purpose:** Notification if shipment delayed.  
* **Set\_Date\_Delivered**  
  * **Purpose:** Set Date\_Delivered\_\_c when Status moves to 'Delivered'.  
* **Remove\_Date\_Delivered\_Value**  
  * **Purpose:** Clear Date\_Delivered\_\_c when status changes away from 'Delivered'.  
* **Route\_Metrics\_Event\_Subscriber**  
  * **Purpose:** Subscribe/process Data Cloud route metrics, update shipments.

### **Apex Triggers (force-app/main/default/triggers)**

* **ShipmentManagementTrigger** (Shipment\_\_c)  
  * **Purpose:** Enforces lifecycle rules (delete allowed only in certain statuses).  
  * **Notes:** Uses TriggerHandlerGuard to avoid recursion/bulk issues.  
* **CargoBulkProcessingTrigger** (Cargo\_\_c)  
  * **Purpose:** Handles bulk insert/update weight rollups and assignment logic.  
* **CustomsDocumentGenerator** (Customs\_Document\_\_c)  
  * **Purpose:** Generates/updates customs docs upon cargo/shipment associations.  
* **CustomsDocumentCargoLinkTrigger** (Customs\_Document\_Cargo\_Link\_\_c)  
  * **Purpose:** Enforces junction constraints, prevents cross-shipment linking.

### **Validation Rules**

* **Shipment\_\_c:**  
  * ETA\_Must\_Be\_After\_Departure\_Date  
  * Total\_Cargo\_Weight\_Within\_Ship\_Capacity  
* **Customs\_Document\_Cargo\_Link\_\_c:**  
  * Cargo\_Must\_Be\_From\_Shipment

## **Apex**

### **Service and Utility Classes**

* **FuelCostCalculator**  
  * **Purpose:** Calculates fuel cost based on distance, weight and method.  
  * **Coverage:** 100%  
* **FuelCostFlowAction**  
  * **Purpose:** Invocable wrapper for Flow integration.  
  * **Coverage:** 100%  
* **CustomsClearanceService**  
  * **Purpose:** Evaluates hazardous/mixed cargo and sets clearance outcomes.  
  * **Coverage:** 100%  
* **BulkShipmentProcessor**  
  * **Purpose:** Bulk operations over shipments.  
  * **Coverage:** 94%  
* **TriggerHandlerGuard**  
  * **Purpose:** Guard to ensure single execution per context and bulk-safe processing.  
  * **Coverage:** 100%

### **Controllers**

* **ShipmentTrackerController**  
  * **Purpose:** Apex controller to provide real-time tracking data to LWC.  
  * **Coverage:** 88% (lines 36–37 uncovered in latest run)  
* **QuickCargoAssignerController**  
  * **Purpose:** Aura controller for assigning agents to cargo.  
  * **Coverage:** 73%

### **Tests and Coverage (latest run)**

* **Tests ran:** 33  
* **Pass rate:** 85%  
* **Org-wide Coverage:** 92%  
* **Failing tests:**  
  * CustomsDocumentGenerator\_Test.testTriggerOnBulkInsert (due to flow lock row on assigning agent)  
  * CargoBulkProcessingTrigger\_Test.setup (due to same locking issue in flow)  
  * FuelCostCalculator\_Test.testConstructorLogic (assertion issue)

## **UI**

### **LWC**

* **realTimeTracking**  
  * **Files:** realTimeTracking.html, realTimeTracking.js, meta.xml  
  * **Purpose:** Displays shipment tracking data in real-time.  
  * **Backed by:** ShipmentTrackerController

### **Aura**

* **QuickCargoAssigner**  
  * **Files:** Component, controller, helper, renderer, design, doc  
  * **Purpose:** Quickly assign agents to cargo, bulk-friendly UI.  
  * **Backed by:** QuickCargoAssignerController

### **Visualforce**

* **ShipmentSummaryPage**  
  * **Purpose:** Summary page for shipment data, links to related cargo and documents.

### **Apps/Pages**

* Lightning App(s) present; Flexipages included in repo (see force-app/main/default/flexipages/)

## **Integrations and Data Cloud Streams**

* **DataStreamDefinitions:**  
  * Planetary\_System\_c\_Home  
  * Shipping\_Route\_c\_Home  
  * Route\_Leg\_c\_Home  
  * Route\_RouteLeg\_Junction\_c\_Home  
  * Shipment\_c\_Home  
* **Purpose:** Provide event data for route metrics and delay likelihood scoring. Flows subscribe via Route\_Metrics\_Event\_Subscriber.

## **Security and Access**

* **Permission Sets and Profiles:** Retrieved in org, ensure object/field access and tab visibility. Review force-app/main/default/permissionsets and profiles for detailed access matrices.  
* **Tabs and Web Links:**  
  * Account Billing web link  
  * Opportunity DeliveryStatus web link  
* **Layouts:** Standard and custom layouts present under force-app/main/default/layouts

## **Operations**

### **Local Setup**

* **Prereqs:** Node 18+, Salesforce CLI (sf), Git  
* **Clone:** git clone & npm install (if applicable for any tooling)  
* **Auth:** sf org login web \--alias your-org

### **Scratch Org (optional)**

\# Create scratch org  
sf org create scratch \--definition-file config/project-scratch-def.json \--alias iftc-scratch \--duration-days 7

\# Deploy project  
sf project deploy start \--target-org iftc-scratch

\# Run tests  
sf apex run test \--target-org iftc-scratch \--code-coverage \--result-format human \--wait 10

### **Retrieve/Deploy**

\# Retrieve from default org  
sf project retrieve start \--source-dir force-app \--wait 10

\# Deploy to target  
sf project deploy start \--target-org \<alias\> \--source-dir force-app \--test-level RunLocalTests

### **Run Tests**

sf apex run test \--code-coverage \--result-format human \--wait 10

* Review coverage by class and org-wide coverage.

### **Troubleshooting**

* **Flow locking during tests (UNABLE\_TO\_LOCK\_ROW on Assign\_Shipment\_to\_Available\_Freight\_Agent):**  
  * **Mitigation:** Mitigate with Platform Cache or Test.sealAllData(false) patterns, or mock assignment logic.  
  * **Bypass:** Consider pausing flow in test context via Custom Setting/Metadata flag that tests set ON to bypass agent updates.  
* **Missing fields warnings on retrieve (Shipment\_\_c.Distance\_\_c, Shipment\_\_c.Total\_Cargo\_Weight\_\_c):**  
  * **Cause:** Repo/package.xml may reference removed fields.  
  * **Action:** Clean references or re-add fields if expected.  
* **Coverage shortfalls:**  
  * ShipmentTrackerController (88%): Add tests for uncovered lines 36–37.  
  * QuickCargoAssignerController (73%): Add negative path and exception handling tests.

## **Appendix**

### **List Views (selected)**

* **Account:** AllAccounts, MyAccounts, NewThisWeek, NewLastWeek, PlatinumandGoldSLACustomers  
* **Contact:** AllContacts, MyContacts, BirthdaysThisMonth, NewThisWeek, NewLastWeek, BulkMessageContacts  
* **Opportunity:** AllOpportunities, MyOpportunities, ClosingThisMonth/NextMonth, Default\_Opportunity\_Pipeline, Private, Won  
* **Cargo\_\_c:** All  
* **Customs\_Document\_\_c:** All  
* **Customs\_Document\_Cargo\_Link\_\_c:** All  
* **Shipment\_\_c:** All

### **Validation Rules**

* **Shipment\_\_c**  
  * ETA\_Must\_Be\_After\_Departure\_Date  
  * Total\_Cargo\_Weight\_Within\_Ship\_Capacity  
* **Customs\_Document\_Cargo\_Link\_\_c**  
  * Cargo\_Must\_Be\_From\_Shipment

### **Web Links**

* **Account:** Billing  
* **Opportunity:** DeliveryStatus

### **Repository Pointers**

* **Apex:** force-app/main/default/classes  
* **Triggers:** force-app/main/default/triggers  
* **Flows:** force-app/main/default/flows  
* **LWC:** force-app/main/default/lwc/realTimeTracking  
* **Aura:** force-app/main/default/aura/QuickCargoAssigner  
* **Objects:** force-app/main/default/objects  
* **Data Streams:** force-app/main/default/dataStreamDefinitions  
* **Visualforce:** force-app/main/default/pages

## **Change Log (latest org sync)**

* Multiple metadata items retrieved and refreshed on 2025-11-11  
* Org-wide coverage reported at 92%  
* See sf retrieve output table in terminal for exact changed components
