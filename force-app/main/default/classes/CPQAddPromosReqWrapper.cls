/*************************************************************************************************************************************
 Author      :   Arun
 Description :   Wrapper class for CPQAddPromos
 --------------------------------------------------------------------------------------------------------------------------------------
 VERSION         DATE            AUTHOR              DETAIL
 1               03/15/2021       Arun        Initial Deployment
**************************************************************************************************************************************/
public class CPQAddPromosReqWrapper {
    public class RequestWrapper{
        public List<RequestWithUUIDandCommimentTerms> discountparam;   
    }
    public class RequestWithUUIDandCommimentTerms{
        public String uuid;
        public List<Integer> commitmentLengths;
    }
}