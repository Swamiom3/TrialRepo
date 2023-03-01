/**
 * @description Class used to serialize a single Lookup search result item
 *              The Lookup controller returns a List<LookupSearchResult> when sending search result back to Lightning
 * @name trac_LookupSearchResult
 * @author Daniel Labonte, Traction on Demand
 * @date 2019-08-13
 *
 * Copyright 2019 Salesforce.com
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 *
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 * prefix "trac" added for visibility into the work Traction on Demand has done
 */
public class trac_LookupSearchResult {

    private Id id;
    private String sObjectType;
    private String icon;
    private String title;
    private String subtitle;
    private String apiName;

    public trac_LookupSearchResult(Id id, String sObjectType, String icon, String title, String subtitle, String apiName) {
        this.id = id;
        this.sObjectType = sObjectType;
        this.icon = icon;
        this.title = title;
        this.subtitle = subtitle;
        this.apiName = apiName;
    }

    @AuraEnabled
    public Id getId() { return id; }

    @AuraEnabled
    public String getSObjectType() { return sObjectType; }

    @AuraEnabled
    public String getIcon() { return icon; }

    @AuraEnabled
    public String getTitle() { return title; }

    @AuraEnabled
    public String getSubtitle() { return subtitle; }

    @AuraEnabled
    public String getApiName() { return apiName; }
}