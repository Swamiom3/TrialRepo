/*************************************************************************************************************************************
    Author      :    Krishana Tupe
    Description :    This trigger is used to handle LogException__e logic.
    --------------------------------------------------------------------------------------------------------------------------------------
    VERSION    DATE            AUTHOR            DETAIL
    1          2 May, 2018     Krishana Tupe     Changes for exception logging.
    2          29 Nov, 2021    Pawel Biszczak    Moving to a new framework
**************************************************************************************************************************************/
trigger LogExceptionTriggers on LogException__e (after insert) {
    new MetadataDrivenTriggerHandler().run();
}