@IsTest
private class FixApexClassAccessProcTest {

    private class SuccessWebServiceMockImpl implements WebServiceMock {
        public void doInvoke(Object stub, Object request, Map<String, Object> response, String endpoint, String soapAction, String requestName, String responseNS, String responseName, String responseType) {
            MetadataService.SaveResult saveResult = new MetadataService.SaveResult();
            saveResult.success = true;
            MetadataService.updateMetadataResponse_element elResponse = new MetadataService.updateMetadataResponse_element();
            elResponse.result = new List<MetadataService.SaveResult>{saveResult};
            response.put('response_x', elResponse);
        }
    }

    private class FailedWebServiceMockImpl implements WebServiceMock {
        public void doInvoke(Object stub, Object request, Map<String, Object> response, String endpoint, String soapAction, String requestName, String responseNS, String responseName, String responseType) {
            // Save result with data
            MetadataService.SaveResult saveResult = new MetadataService.SaveResult();
            saveResult.success = false; // set result is failed
            MetadataService.Error error = new MetadataService.Error(); // create an error
            error.message = 'Error';
            saveResult.errors = new List<MetadataService.Error>{error};

            MetadataService.updateMetadataResponse_element elResponse = new MetadataService.updateMetadataResponse_element();
            elResponse.result = new List<MetadataService.SaveResult>{saveResult};
            elResponse.result.add(saveResult);
            response.put('response_x', elResponse);
        }
    }

    @IsTest
    static void testSuccessChangeApexClassAccess() {
        Test.setMock(WebServiceMock.class, new SuccessWebServiceMockImpl());
        Test.startTest();
        vertic_Response response = new FixApexClassAccessProc().process(new Map<String, Object>{
            'profile' => 'Admin',
            'apexClasses' => FixApexClassAccessProc.getApexClassNames()
        });
        List<MetadataService.SaveResult> results = (List<MetadataService.SaveResult>) response.get('results');
        System.assertEquals(true, results.get(0).success, 'Changes applied successfully!');
        Test.stopTest();
    }

    @IsTest
    static void testFailedChangeApexClassAccess() {
        Test.setMock(WebServiceMock.class, new FailedWebServiceMockImpl());
        Test.startTest();
        try {
            new FixApexClassAccessProc().process(new Map<String, Object>{
                'profile' => 'Admin',
                'apexClasses' => FixApexClassAccessProc.getApexClassNames()
            });
        } catch (vertic_Structs.ProcessException ex) {
            System.assertEquals(true, ex.getMessage() != null, 'Changes wasn\'t applied!');
        }
        Test.stopTest();
    }

    @IsTest
    static void testEnqueueChangeApexClassAccess() {
        Test.startTest();
            FixApexClassAccessProc.enqueue();
        Test.stopTest();
        List<AggregateResult> asyncCountAggregation = [
            SELECT
                COUNT(Id) asyncCount
            FROM Vertic_Async_Process__c
        ];
        Integer asyncCount = Integer.valueOf(asyncCountAggregation.get(0).get('asyncCount'));
        System.assertEquals(true, asyncCount > 1);
    }

}