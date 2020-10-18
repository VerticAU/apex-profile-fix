public without sharing class FixApexClassAccessProc extends vertic_AbstractProcessor {

    /**
     * ==============================================================================================================
     *                                              PROCESS
     * ==============================================================================================================
     */

    public override vertic_Response process(vertic_Request request) {
        this.request = request;

        this.doSubmit();

        return this.response;
    }


    /**
     * ==============================================================================================================
     *                                             PRIVATE METHODS
     * ==============================================================================================================
     */

    private void doSubmit() {

        String profileName = this.request.getRequiredString('profile');
        List<String> apexClassesToEnable = this.request.getListAsStrings('apexClasses');


        MetadataService.MetadataPort service = new MetadataService.MetadataPort();
        service.SessionHeader = new MetadataService.SessionHeader_element();
        service.SessionHeader.sessionId = UserInfo.getSessionId();

        MetadataService.Profile profile = new MetadataService.Profile();
        profile.fullName = profileName;
        profile.classAccesses = new List<MetadataService.ProfileApexClassAccess>();

//        MetadataService.Profile profile = (MetadataService.Profile) vertic_Utils.arrays.firstOrException(
//            service.readMetadata('Profile', new String[]{
//                profileName
//            }).getRecords(),
//            'No profile with Name: ' + profileName
//        );

        for (String apexClassToEnable : apexClassesToEnable) {
            MetadataService.ProfileApexClassAccess profileApexClassAccess = new MetadataService.ProfileApexClassAccess();
            profileApexClassAccess.apexClass = apexClassToEnable;
            profileApexClassAccess.enabled = true;

            profile.classAccesses.add(profileApexClassAccess);
        }

        List<MetadataService.SaveResult> results =
            service.updateMetadata(
                new MetadataService.Metadata[]{
                    profile
                });

        if (results.get(0).success != true) {
            throw new vertic_Structs.ProcessException(JSON.serializePretty(results.get(0).errors));
        }

    }


    /**
     * ==============================================================================================================
     *                                               STRUCTURES
     * ==============================================================================================================
     */

    // Proposed Live Templates to override Super properties: 
    // vertic_request
    // vertic_response

    public static List<String> getApexClassNames() {
        Set<String> classMasks = new Set<String>{
            'vertic%',
            '%Ctrl',
            'strike%',
            'Google%'
        };

        List<ApexClass> apexClasses = [
            SELECT Id, Name, NamespacePrefix
            FROM ApexClass
            WHERE
            Name LIKE :classMasks AND
            NamespacePrefix = null AND
            (NOT Name LIKE '%Test')
        ];
        System.debug(apexClasses.size());

        List<String> results = new List<String>();

        for (ApexClass apexClassVar : apexClasses) {
            String className = String.isNotBlank(apexClassVar.NamespacePrefix) ? apexClassVar.NamespacePrefix + '.' : '';
            className += apexClassVar.Name;
            results.add(className);
        }

        return results;
    }

    public static List<String> getProfiles() {
        List<Profile> profiles = [SELECT Id, Name FROM Profile];

        final Map<String, String> nameMapping = new Map<String, String>{
            'System Administrator' => 'Admin',
            'Read Only' => 'ReadOnly',
            'Marketing User' => 'MarketingProfile',
            'Solution Manager' => 'SolutionManager',
            'Contract Manager' => 'ContractManager',
            'Standard Guest' => 'StandardGuest',
            'Guest License User' => 'Guest'
        };

        List<String> results = new List<String>();
        for (Profile profileVar : profiles) {
            results.add(nameMapping.containsKey(profileVar.Name) ? nameMapping.get(profileVar.Name) : profileVar.Name);
        }

        return results;
    }

    public static void enqueue(List<String> profileNames, List<String> apexClasses) {
        vertic_AsyncProcess asyncProcess = new vertic_AsyncProcess();

        for (String profileName : profileNames) {
            asyncProcess.add(FixApexClassAccessProc.class, new Map<String, Object>{
                'profile' => profileName,
                'apexClasses' => apexClasses
            });
        }

        asyncProcess.enqueueAndRun();
    }

    public static void enqueue() {
        enqueue(getProfiles(), getApexClassNames());
    }

}