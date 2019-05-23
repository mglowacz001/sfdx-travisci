public class AC_AFDDetailsController {

    private static final String APPROVED_BUDGET = 'Approved Budget';
    private static final String GF = 'GF';
    private static final String DISB_FINAL_FORECAST = 'Disb - Final Forecast';

    private static final String TOTAL_CASH_BALANCE = '%Total Cash Balance%';
    private static final String CASH_IN_TRANSIT = '%Cash in Transit%';
    private static final String OTHER_ADJUSTMENTS = '%Other Adjustments%';

	@AuraEnabled
	public DataWrapper afdWrapp {get;set;}

	@AuraEnabled
    public static AC_AFDDetailsController getRecordDetails(Id recordId){

    	AC_AFDDetailsController result = new AC_AFDDetailsController();
        
        AIM_Annual_Funding_Decision__c afd = [
            SELECT  AIM_Is_Supplementary__c,
                AIM_Implementation_Period__c,
                AIM_AFD_Unique__c,
                AIM_Supplementaries_Amount__c,
				ip.AIM_Amount_Signed_IP_Currency__c,
                ip.AIM_Grant_Currency__c,
				ip.AIM_Amount_Disbursed_IP_Currency__c,
                ip.AIM_Amount_Committed_IP_Currency__c,
				AIM_Reporting_Period__c,
				rp.AIM_Reporting_Period_End_Date_Text__c,
				rp.AIM_Reporting_Period_Start_Date_Text__c,
				rp.AIM_GF_Rating_Major_Issues__c,
				rp.AIM_GF_Rating_Overall_Rating__c

            FROM AIM_Annual_Funding_Decision__c,
                AIM_Annual_Funding_Decision__c.AIM_Implementation_Period__r ip,
                AIM_Annual_Funding_Decision__c.AIM_Reporting_Period__r rp
            WHERE Id =: recordId
            LIMIT 1
        ];

        List<AIM_Quarterly_Cash_Forecast__c> qcfs = new List<AIM_Quarterly_Cash_Forecast__c>();

        if(afd.AIM_Reporting_Period__c == null && afd.AIM_AFD_Unique__c.substringAfter('.').isNumeric()){
            String originalAFDName = afd.AIM_AFD_Unique__c.substringBefore('.') + '.0';
            qcfs = [
                SELECT AIM_type__c, Name, AIM_Total_Forecast_incl_Buffer__c
                FROM AIM_Quarterly_Cash_Forecast__c
                WHERE AIM_AFD__r.AIM_AFD_Unique__c = :originalAFDName
                    AND ((AIM_type__c = :APPROVED_BUDGET)
                        OR (AIM_type__c = :GF AND Name = :AIM_Constants.QFC_NAME_FORECASTED_AMOUNT_PPM_WAMBO)
                        OR (AIM_type__c = :GF AND Name IN (:AIM_Constants.QFC_NAME_FORECASTED_AMOUNT_PRINCIPAL_RECIPIENT, :AIM_Constants.QFC_NAME_FORECASTED_AMOUNT_3RD_PARTY))
                        OR (AIM_type__c = :DISB_FINAL_FORECAST AND (Name LIKE :TOTAL_CASH_BALANCE OR Name LIKE :CASH_IN_TRANSIT))
                        OR (AIM_type__c = :DISB_FINAL_FORECAST AND Name LIKE :OTHER_ADJUSTMENTS)
                    )
                ORDER BY createdDate ASC
                ];
        } else if (afd.AIM_Reporting_Period__c != null) {
            qcfs = [
                SELECT AIM_type__c, Name, AIM_Total_Forecast_incl_Buffer__c
                FROM AIM_Quarterly_Cash_Forecast__c
                WHERE aim_reporting_period_id__c = :afd.AIM_Reporting_Period__c
                    AND ((AIM_type__c = :APPROVED_BUDGET)
                        OR (AIM_type__c = :GF AND Name = :AIM_Constants.QFC_NAME_FORECASTED_AMOUNT_PPM_WAMBO)
                        OR (AIM_type__c = :GF AND Name IN (:AIM_Constants.QFC_NAME_FORECASTED_AMOUNT_PRINCIPAL_RECIPIENT, :AIM_Constants.QFC_NAME_FORECASTED_AMOUNT_3RD_PARTY))
                        OR (AIM_type__c = :DISB_FINAL_FORECAST AND (Name LIKE :TOTAL_CASH_BALANCE OR Name LIKE :CASH_IN_TRANSIT))
                        OR (AIM_type__c = :DISB_FINAL_FORECAST AND Name LIKE :OTHER_ADJUSTMENTS)
                    )
                ORDER BY createdDate ASC
                ];
        }

        result.afdWrapp = new DataWrapper(afd, qcfs);

        return result;

    }

    public class DataWrapper{

    	@AuraEnabled
    	public Decimal amountSigned;
        @AuraEnabled
        public Decimal amountComitted;
        @AuraEnabled
        public String reportingPeriod = '-';
        @AuraEnabled
        public String quantitativeIndicatorRating;
        @AuraEnabled
        public Decimal amountDisbursed;
        @AuraEnabled
        public String majorIssues = '-' ;
        @AuraEnabled
        public String ipCurrency;
        @AuraEnabled
        public String overallGrantRating = '-' ;

        @AuraEnabled
        public Decimal budgetAmount;
        @AuraEnabled
        public Decimal forecastAmountPpm;
        @AuraEnabled
        public Decimal otherAdjustments;
        @AuraEnabled
        public Decimal supplementary;
        @AuraEnabled
        public Decimal forecastAmountNonPpm;
        @AuraEnabled
        public Decimal totalFundingDecision;
        @AuraEnabled
        public Decimal inCountryCashBalance;

        public DataWrapper(AIM_Annual_Funding_Decision__c afd, List<AIM_Quarterly_Cash_Forecast__c> qcfs) {

            quantitativeIndicatorRating = '-';
            supplementary = afd.AIM_Supplementaries_Amount__c == null ? 0 : afd.AIM_Supplementaries_Amount__c;

            if (afd.AIM_Implementation_Period__r != null) {
                AIM_Implementation_Period__c ip = afd.AIM_Implementation_Period__r;            
		 /*
                 * Modified By: IBM Developer 10/08/2018
                 * INC082153 - AFD - Signed Amount and Documents Enhancement
                 */
                amountSigned = ip.AIM_Amount_Signed_IP_Currency__c == null ? 0 : ip.AIM_Amount_Signed_IP_Currency__c;
                amountComitted = ip.AIM_Amount_Committed_IP_Currency__c == null ? 0 : ip.AIM_Amount_Committed_IP_Currency__c;
                amountDisbursed = ip.AIM_Amount_Disbursed_IP_Currency__c == null ? 0 : ip.AIM_Amount_Disbursed_IP_Currency__c;
                ipCurrency = ip.AIM_Grant_Currency__c;
            }

            if (afd.AIM_Reporting_Period__r != null) {
                AIM_Reporting_Period__c rp = afd.AIM_Reporting_Period__r;

                reportingPeriod = (rp.AIM_Reporting_Period_Start_Date_Text__c == null || rp.AIM_Reporting_Period_End_Date_Text__c == null) ?
                    '-' : rp.AIM_Reporting_Period_Start_Date_Text__c + ' - ' +  rp.AIM_Reporting_Period_End_Date_Text__c;
                majorIssues = String.isBlank(rp.AIM_GF_Rating_Major_Issues__c) ? '-' : rp.AIM_GF_Rating_Major_Issues__c;
                overallGrantRating = String.isBlank(rp.AIM_GF_Rating_Overall_Rating__c) ? '-' : rp.AIM_GF_Rating_Overall_Rating__c;
            }

                
            Map<String, Decimal> amountsMap = new Map<String, Decimal>();

            for (AIM_Quarterly_Cash_Forecast__c qcf: qcfs) {

                if (qcf.AIM_type__c == APPROVED_BUDGET) {
                    amountsMap.put('budgetAmount', qcf.AIM_Total_Forecast_incl_Buffer__c);
                } else if (qcf.AIM_type__c == GF && qcf.name == AIM_Constants.QFC_NAME_FORECASTED_AMOUNT_PPM_WAMBO) {
                    amountsMap.put('forecastAmountPpm', qcf.AIM_Total_Forecast_incl_Buffer__c);
                } else if (qcf.AIM_type__c == GF && qcf.name.containsIgnoreCase(AIM_Constants.QFC_NAME_FORECASTED_AMOUNT_PRINCIPAL_RECIPIENT.replaceAll('%', ''))) {
                    amountsMap.put('forecastAmountNonPpm#' + AIM_Constants.QFC_NAME_FORECASTED_AMOUNT_PRINCIPAL_RECIPIENT, qcf.AIM_Total_Forecast_incl_Buffer__c);
                } else if (qcf.AIM_type__c == GF && qcf.name.containsIgnoreCase(AIM_Constants.QFC_NAME_FORECASTED_AMOUNT_3RD_PARTY.replace('%', ''))) {
                    amountsMap.put('forecastAmountNonPpm#' + AIM_Constants.QFC_NAME_FORECASTED_AMOUNT_3RD_PARTY, qcf.AIM_Total_Forecast_incl_Buffer__c);
                } else if (qcf.AIM_type__c == DISB_FINAL_FORECAST && qcf.name.containsIgnoreCase(TOTAL_CASH_BALANCE.replaceAll('%', ''))) {
                    amountsMap.put('inCountryCashBalance#' + TOTAL_CASH_BALANCE, qcf.AIM_Total_Forecast_incl_Buffer__c); // TKT-003594
                } else if (qcf.AIM_type__c == DISB_FINAL_FORECAST && qcf.name == AIM_Constants.QFC_NAME_CASH_IN_TRANSIT_END_RP) { //INC069928/INC070448
                    amountsMap.put('inCountryCashBalance#' + AIM_Constants.QFC_NAME_CASH_IN_TRANSIT_END_RP, qcf.AIM_Total_Forecast_incl_Buffer__c); //INC069928/INC070448
                } else if (qcf.AIM_type__c == DISB_FINAL_FORECAST && qcf.name == AIM_Constants.QFC_NAME_CASH_IN_TRANSIT_3RD_PARTY) { //INC069928/INC070448
                    amountsMap.put('inCountryCashBalance#' + AIM_Constants.QFC_NAME_CASH_IN_TRANSIT_3RD_PARTY, qcf.AIM_Total_Forecast_incl_Buffer__c); //INC069928/INC070448
                } else if (qcf.AIM_type__c == DISB_FINAL_FORECAST && qcf.name.contains(OTHER_ADJUSTMENTS.replaceAll('%', ''))) {
                    amountsMap.put('otherAdjustments', qcf.AIM_Total_Forecast_incl_Buffer__c);
                }
            }

            budgetAmount = amountsMap.containsKey('budgetAmount') ? amountsMap.get('budgetAmount') : 0;
            forecastAmountPpm = amountsMap.containsKey('forecastAmountPpm') ? amountsMap.get('forecastAmountPpm') : 0;
            forecastAmountNonPpm = (amountsMap.containsKey('forecastAmountNonPpm#' + AIM_Constants.QFC_NAME_FORECASTED_AMOUNT_PRINCIPAL_RECIPIENT) ? amountsMap.get('forecastAmountNonPpm#' + AIM_Constants.QFC_NAME_FORECASTED_AMOUNT_PRINCIPAL_RECIPIENT) : 0)
                    + (amountsMap.containsKey('forecastAmountNonPpm#' + AIM_Constants.QFC_NAME_FORECASTED_AMOUNT_3RD_PARTY) ? amountsMap.get('forecastAmountNonPpm#' + AIM_Constants.QFC_NAME_FORECASTED_AMOUNT_3RD_PARTY) : 0);
            inCountryCashBalance = (amountsMap.containsKey('inCountryCashBalance#' + TOTAL_CASH_BALANCE) ? amountsMap.get('inCountryCashBalance#' + TOTAL_CASH_BALANCE) : 0)
                    + (amountsMap.containsKey('inCountryCashBalance#' + AIM_Constants.QFC_NAME_CASH_IN_TRANSIT_END_RP) ? amountsMap.get('inCountryCashBalance#' + AIM_Constants.QFC_NAME_CASH_IN_TRANSIT_END_RP) : 0) //INC069928/INC070448
                    + (amountsMap.containsKey('inCountryCashBalance#' + AIM_Constants.QFC_NAME_CASH_IN_TRANSIT_3RD_PARTY) ? amountsMap.get('inCountryCashBalance#' + AIM_Constants.QFC_NAME_CASH_IN_TRANSIT_3RD_PARTY) : 0); //INC069928/INC070448                  
            otherAdjustments = amountsMap.containsKey('otherAdjustments') ? amountsMap.get('otherAdjustments') : 0;
            
            Decimal forecastAmountIncludingCashNonPpmPR = (amountsMap.containsKey('forecastAmountNonPpm#' + AIM_Constants.QFC_NAME_FORECASTED_AMOUNT_PRINCIPAL_RECIPIENT) ? amountsMap.get('forecastAmountNonPpm#' + AIM_Constants.QFC_NAME_FORECASTED_AMOUNT_PRINCIPAL_RECIPIENT) : 0) 
                    - (amountsMap.containsKey('inCountryCashBalance#' + TOTAL_CASH_BALANCE) ? amountsMap.get('inCountryCashBalance#' + TOTAL_CASH_BALANCE) : 0)
                    - (amountsMap.containsKey('inCountryCashBalance#' + AIM_Constants.QFC_NAME_CASH_IN_TRANSIT_END_RP) ? amountsMap.get('inCountryCashBalance#' + AIM_Constants.QFC_NAME_CASH_IN_TRANSIT_END_RP) : 0);
                    
            Decimal forecastAmountIncludingCashNonPpm3RD = (amountsMap.containsKey('forecastAmountNonPpm#' + AIM_Constants.QFC_NAME_FORECASTED_AMOUNT_3RD_PARTY) ? amountsMap.get('forecastAmountNonPpm#' + AIM_Constants.QFC_NAME_FORECASTED_AMOUNT_3RD_PARTY) : 0)
                    - (amountsMap.containsKey('inCountryCashBalance#' + AIM_Constants.QFC_NAME_CASH_IN_TRANSIT_3RD_PARTY) ? amountsMap.get('inCountryCashBalance#' + AIM_Constants.QFC_NAME_CASH_IN_TRANSIT_3RD_PARTY) : 0);
                    
            if (forecastAmountIncludingCashNonPpmPR < 0){
                forecastAmountIncludingCashNonPpmPR = 0.00;
            }
            
            if (forecastAmountIncludingCashNonPpm3RD < 0){
                forecastAmountIncludingCashNonPpm3RD = 0.00;
            }

            totalFundingDecision = forecastAmountIncludingCashNonPpmPR + forecastAmountIncludingCashNonPpm3RD + otherAdjustments;
            if(afd != null && afd.AIM_Supplementaries_Amount__c != null){
                totalFundingDecision += afd.AIM_Supplementaries_Amount__c;
            }

    	}

    }
}