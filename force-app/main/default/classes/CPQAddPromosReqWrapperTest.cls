@isTest
private class CPQAddPromosReqWrapperTest {
	@isTest
    static void testWrapper() {
        String uuid = 'TEST_UUID';
        
        CPQAddPromosReqWrapper.RequestWithUUIDandCommimentTerms uuidReq = new CPQAddPromosReqWrapper.RequestWithUUIDandCommimentTerms();
        uuidReq.uuid = uuid;
        uuidReq.commitmentLengths = new List<Integer>{0};
            
        CPQAddPromosReqWrapper.RequestWrapper req = new CPQAddPromosReqWrapper.RequestWrapper();
        req.discountparam = new List<CPQAddPromosReqWrapper.RequestWithUUIDandCommimentTerms>{uuidReq};
            
        System.assert(uuidReq.uuid == uuid, 'Failed to populate the UUID');
    }
}