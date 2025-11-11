# Intergalactic Freight & Trade Corp — Technical Documentation

This documentation is generated from the live org (aphiwe.zulu852@agentforce.com) and aligned with the source in this repository. It inventories the data model, automation (flows, triggers), Apex code, UI components, and operational practices.

Last updated: 2025-11-11
Org: aphiwe.zulu852@agentforce.com (API v65.0)

Contents
- Overview
- Architecture
- Data Model
- Automation (Flows, Triggers, Validation Rules)
- Apex
- UI (LWC, Aura, Visualforce, Apps/Pages)
- Integrations and Data Cloud Streams
- Security and Access
- Operations (Deploy, Test, Troubleshoot)
- Appendix (List Views, Web Links, Known Gaps)

Overview
Intergalactic Freight & Trade Corp manages shipments across planetary systems. This Salesforce package provides:
- Shipment planning and execution
- Cargo assignment to available freight agents
- Automated fuel cost calculation and ETA management
- Customs documentation generation and linkage
- Real-time shipment tracking UI components
- Event ingestion (Data Cloud streams) for route metrics

Architecture
- Core objects: Shipment__c, Cargo__c, Customs_Document__c, Customs_Document_Cargo_Link__c
- Relationships:
  - Cargo__c.Shipment__c (lookup to Shipment)
  - Shipment__c.Recipient__c and Shipment__c.Sender__c (lookups to Contact)
  - Customs_Document__c.Shipment__c and Customs_Document__c.Cargo__c
  - Customs_Document_Cargo_Link__c bridges Customs_Document__c and Cargo__c (enforces same-shipment validation)
- Automation:
  - Flows: Assign agent, calculate fuel, set/clear delivered date, delayed shipment notification, route metrics subscriber
  - Triggers: Shipment management, cargo bulk processing, customs generators and link validation guard
- Code:
  - Service/logic classes: FuelCostCalculator, CustomsClearanceService, BulkShipmentProcessor, TriggerHandlerGuard
  - Controllers: ShipmentTrackerController (LWC), QuickCargoAssignerController (Aura), FuelCostFlowAction (invocable)
- UI:
  - LWC realTimeTracking
  - Aura QuickCargoAssigner
  - Visualforce ShipmentSummaryPage
- Streaming/Data Cloud:
  - DataStreamDefinitions for Shipment, Shipping Route, Route Legs and Planetary Systems

Data Model

Shipment__c
- Key fields:
  - Departure_Date__c (Date)
  - ETA__c (Date/Time) [VR: must be after departure]
  - Origin_Planetary_System__c, Destination_Planetary_System__c (Lookup/Text)
  - Fuel_Cost__c (Currency) [set by FuelCostCalculator/Flow]
  - Total_Weight__c (Number) [rollup/summarized from Cargo]
  - Is_Delayed__c (Checkbox) [set by Check_for_Delays Flow]
  - Total_Delivery_Time__c (Number)
  - Delay_Likelihood_Score_Data_Cloud__c (Number) [from Data Cloud]
  - Recipient__c, Sender__c (Lookup(Contact))
  - Status__c, Shipping_Method__c (Picklists)
  - Suggested_Shipping_Route__c, Estimated_Direct_Distance__c
  - Date_Delivered__c (Date) [managed by Set/Remove Date Delivered Flows]
- Validation Rules:
  - ETA_Must_Be_After_Departure_Date
  - Total_Cargo_Weight_Within_Ship_Capacity (see VRs)
- List Views: All

Cargo__c
- Fields:
  - Shipment__c (Lookup Shipment__c)
  - Agent__c (Lookup/User or custom agent)
  - Weight__c (Number)
  - Category__c (Picklist)
  - Description__c (Text)
- List Views: All

Customs_Document__c
- Fields:
  - Shipment__c (Lookup)
  - Cargo__c (Lookup)
  - Clearance_Status__c (Picklist: e.g., Submitted/Approved/Rejected)
  - Date_Submitted__c (Date)
  - Rejection_Reason__c (Text)
- List Views: All

Customs_Document_Cargo_Link__c
- Junction between Customs_Document__c and Cargo__c
- Validation:
  - Cargo_Must_Be_From_Shipment (cargo must belong to the same shipment as the customs doc)
- List Views: All

Standard Objects in scope
- Account, Contact, Opportunity typical fields and customizations (examples):
  - Account: SLA__c, SLAExpirationDate__c, SLASerialNumber__c, Active__c, NumberofLocations__c
  - Opportunity: TrackingNumber__c, DeliveryStatus (WebLink), standard sales fields
  - Contact: various test fields (rh2__*) and demographics

Automation

Flows (force-app/main/default/flows)
- Assign_Shipment_to_Available_Freight_Agent
  - Purpose: On creation/update, assign a shipment to an available agent
  - Notes: Can lock User records during tests; test failures show UNABLE_TO_LOCK_ROW in concurrent updates
- Calculate_Fuel_Cost
  - Purpose: Compute Fuel_Cost__c for Shipment using FuelCostCalculator
  - Entry: Autolaunched/from invocable
- Check_for_Delays
  - Purpose: Derive Is_Delayed__c based on ETA, route metrics, and events
- Notify_of_Delayed_Shipment
  - Purpose: Notification if shipment delayed
- Set_Date_Delivered
  - Purpose: Set Date_Delivered__c when Status moves to Delivered
- Remove_Date_Delivered_Value
  - Purpose: Clear Date_Delivered__c when status changes away from Delivered
- Route_Metrics_Event_Subscriber
  - Purpose: Subscribe/process Data Cloud route metrics, update shipments

Apex Triggers (force-app/main/default/triggers)
- ShipmentManagementTrigger (Shipment__c)
  - Enforces lifecycle rules (delete allowed only in certain statuses)
  - Uses TriggerHandlerGuard to avoid recursion/bulk issues
- CargoBulkProcessingTrigger (Cargo__c)
  - Handles bulk insert/update weight rollups and assignment logic
- CustomsDocumentGenerator (Customs_Document__c)
  - Generates/updates customs docs upon cargo/shipment associations
- CustomsDocumentCargoLinkTrigger (Customs_Document_Cargo_Link__c)
  - Enforces junction constraints, prevents cross-shipment linking

Validation Rules
- Shipment__c:
  - ETA_Must_Be_After_Departure_Date
  - Total_Cargo_Weight_Within_Ship_Capacity
- Customs_Document_Cargo_Link__c:
  - Cargo_Must_Be_From_Shipment

Apex

Service and Utility Classes
- FuelCostCalculator
  - Calculates fuel cost based on distance, weight and method
  - Tested to 100% coverage in current run
- FuelCostFlowAction
  - Invocable wrapper for Flow integration
- CustomsClearanceService
  - Evaluates hazardous/mixed cargo and sets clearance outcomes
  - 100% coverage
- BulkShipmentProcessor
  - Bulk operations over shipments; 94% coverage
- TriggerHandlerGuard
  - Guard to ensure single execution per context and bulk-safe processing

Controllers
- ShipmentTrackerController
  - Apex controller to provide real-time tracking data to LWC
  - 88% coverage; lines 36–37 uncovered in latest run
- QuickCargoAssignerController
  - Aura controller for assigning agents to cargo; 73% coverage

Tests and Coverage (latest run)
- Tests ran: 33, Pass rate: 85%, Org-wide Coverage: 92%
- Failing tests:
  - CustomsDocumentGenerator_Test.testTriggerOnBulkInsert due to flow lock row on assigning agent
  - CargoBulkProcessingTrigger_Test.setup due to same locking issue in flow
  - FuelCostCalculator_Test.testConstructorLogic assertion issue
- Key coverages:
  - 100%: FuelCostCalculator, CustomsDocumentCargoLinkTrigger, CustomsClearanceService, ShipmentManagementTrigger, TriggerHandlerGuard, FuelCostFlowAction
  - 89%: CustomsDocumentGenerator
  - 94%: BulkShipmentProcessor
  - 88%: ShipmentTrackerController
  - 73%: QuickCargoAssignerController

UI

LWC
- realTimeTracking
  - Files: realTimeTracking.html, realTimeTracking.js, meta.xml
  - Purpose: Displays shipment tracking data in real-time
  - Backed by ShipmentTrackerController

Aura
- QuickCargoAssigner
  - Component, controller, helper, renderer, design, doc
  - Purpose: Quickly assign agents to cargo, bulk-friendly UI
  - Backing Apex: QuickCargoAssignerController

Visualforce
- ShipmentSummaryPage
  - Summary page for shipment data, links to related cargo and documents

Apps/Pages
- Lightning App(s) present; Flexipages included in repo (see force-app/main/default/flexipages/)

Integrations and Data Cloud Streams
- DataStreamDefinitions:
  - Planetary_System_c_Home
  - Shipping_Route_c_Home
  - Route_Leg_c_Home
  - Route_RouteLeg_Junction_c_Home
  - Shipment_c_Home
- Purpose: Provide event data for route metrics and delay likelihood scoring. Flows subscribe via Route_Metrics_Event_Subscriber.

Security and Access
- Permission Sets and Profiles: retrieved in org, ensure object/field access and tab visibility. Review force-app/main/default/permissionsets and profiles for detailed access matrices.
- Tabs and Web Links:
  - Account Billing web link
  - Opportunity DeliveryStatus web link
- Layouts: standard and custom layouts present under force-app/main/default/layouts

Operations

Local Setup
- Prereqs: Node 18+, Salesforce CLI (sf), Git
- Clone: git clone & npm install (if applicable for any tooling)
- Auth: sf org login web --alias your-org

Scratch Org (optional)
- sf org create scratch --definition-file config/project-scratch-def.json --alias iftc-scratch --duration-days 7
- sf project deploy start --target-org iftc-scratch
- sf apex run test --target-org iftc-scratch --code-coverage --result-format human --wait 10

Retrieve/Deploy
- Retrieve from default org:
  - sf project retrieve start --source-dir force-app --wait 10
- Deploy to target:
  - sf project deploy start --target-org <alias> --source-dir force-app --test-level RunLocalTests

Run Tests
- sf apex run test --code-coverage --result-format human --wait 10
- Review coverage by class and org-wide coverage

Troubleshooting
- Flow locking during tests (UNABLE_TO_LOCK_ROW on Assign_Shipment_to_Available_Freight_Agent):
  - Mitigate with Platform Cache or Test.sealAllData false patterns, or mock assignment logic
  - Consider pausing flow in test context via Custom Setting/Metadata flag that tests set ON to bypass agent updates
- Missing fields warnings on retrieve (Shipment__c.Distance__c, Shipment__c.Total_Cargo_Weight__c):
  - Repo/package.xml may reference removed fields. Clean references or re-add fields if expected.
- Coverage shortfalls:
  - ShipmentTrackerController uncovered lines 36–37; add tests for those branches
  - QuickCargoAssignerController at 73%; add negative path and exception handling tests

Appendix

List Views (selected)
- Account: AllAccounts, MyAccounts, NewThisWeek, NewLastWeek, PlatinumandGoldSLACustomers
- Contact: AllContacts, MyContacts, BirthdaysThisMonth, NewThisWeek, NewLastWeek, BulkMessageContacts
- Opportunity: AllOpportunities, MyOpportunities, ClosingThisMonth/NextMonth, Default_Opportunity_Pipeline, Private, Won
- Cargo__c: All
- Customs_Document__c: All
- Customs_Document_Cargo_Link__c: All
- Shipment__c: All

Validation Rules
- Shipment__c
  - ETA_Must_Be_After_Departure_Date
  - Total_Cargo_Weight_Within_Ship_Capacity
- Customs_Document_Cargo_Link__c
  - Cargo_Must_Be_From_Shipment

Web Links
- Account: Billing
- Opportunity: DeliveryStatus

Repository Pointers
- Apex: force-app/main/default/classes
- Triggers: force-app/main/default/triggers
- Flows: force-app/main/default/flows
- LWC: force-app/main/default/lwc/realTimeTracking
- Aura: force-app/main/default/aura/QuickCargoAssigner
- Objects and fields: force-app/main/default/objects
- Data Streams: force-app/main/default/dataStreamDefinitions
- Visualforce: force-app/main/default/pages

Change Log (latest org sync)
- Multiple metadata items retrieved and refreshed on 2025-11-11
- Org-wide coverage reported at 92%
- See sf retrieve output table in terminal for exact changed components
