@isTest
public class WWTypesTest {
    @isTest
    public static void testWWtype() {
        WWTypes.Payment objPayment = new WWTypes.Payment();
        WWTypes.InboundLead objInboundLead = new WWTypes.InboundLead();
        objInboundLead.buildings_interested_uuids = null;
        objInboundLead.product_interests = null;
        objInboundLead.product_interests = null;
        objInboundLead.market_uuids = null;
        objInboundLead.lead_address = null;
        objInboundLead.google_analytics = null;
        WWTypes.OpportunityDetails objOpportunityDetails = new WWTypes.OpportunityDetails();
        objOpportunityDetails.reservables = null;
        objOpportunityDetails.members = null;
        objOpportunityDetails.discounts = null;
        objOpportunityDetails.locations_interested_uuids = null;
        objOpportunityDetails.office_types_interested = null;
        WWTypes.OpportunityInsert objOpportunityInsert = new WWTypes.OpportunityInsert();
        objOpportunityInsert.discounts = NULL;
        WWTypes.OpportunityUpdate objOpportunityUpdate = new WWTypes.OpportunityUpdate();
        objOpportunityUpdate.discounts = NULL;
        WWTypes.BuildingAvailability objBuildingAvailability = new WWTypes.BuildingAvailability();
        objBuildingAvailability.dates = null;
        WWTypes.TourDate objTourDate = new WWTypes.TourDate();
        objTourDate.times = null;
        WWTypes.Waitlist objWaitlist = new WWTypes.Waitlist();
        objWaitlist.buildings_interested_uuids = null;
        WWTypes.Members objMembers = new WWTypes.Members();
        objMembers.users.add(new WWTypes.Member());
        objMembers.users[0].address = null;
    }
}