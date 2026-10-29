from pathlib import Path
import hashlib, plistlib
root=Path(__file__).resolve().parents[1]
# The reduced Watch app does not receive Handoff activities.
main_info=plistlib.loads((root/'Resources/Info.plist').read_bytes())
main_info['NSUserActivityTypes']=['org.example.homeview.recipe.v1']
(root/'Resources/MainInfo.plist').write_bytes(plistlib.dumps(main_info,sort_keys=False))
objects={}
def uid(s):return hashlib.sha1(s.encode()).hexdigest()[:24].upper()
def obj(name,body):objects[uid(name)]=body;return uid(name)
def arr(xs):return '( '+', '.join(xs)+' )'
def q(s):return '"'+s.replace('"','\\"')+'"'
def buildsettings(d):return '{ '+ ' '.join((q(k) if '[' in k else k)+' = '+(v if v.startswith('(') else q(v))+';' for k,v in d.items())+' }'
files=[]
for p in sorted(p for p in (root/'Sources').rglob('*') if p.suffix in ['.swift', '.metal']):
    rel=str(p.relative_to(root));kind='sourcecode.metal' if p.suffix=='.metal' else 'sourcecode.swift';obj(rel,'{isa = PBXFileReference; lastKnownFileType = '+kind+'; path = '+q(rel)+'; sourceTree = SOURCE_ROOT;}');files.append(rel)
for rel,kind in [('Resources/Assets.xcassets','folder.assetcatalog'),('Resources/demo-tone.wav','audio.wav'),('Resources/podcast-test-audio.wav','audio.wav'),('Resources/podcast-caption-test.mp4','file'),('Resources/FeedKit-LICENSE.txt','text'),('Tests/UITests/HomeViewUITests.swift','sourcecode.swift'),('Tests/TVUITests/HomeViewTVUITests.swift','sourcecode.swift'),('Tests/WatchUITests/HomeViewWatchUITests.swift','sourcecode.swift'),('Tests/VisionUITests/HomeViewVisionUITests.swift','sourcecode.swift')]:obj(rel,'{isa = PBXFileReference; lastKnownFileType = '+kind+'; path = '+q(rel)+'; sourceTree = SOURCE_ROOT;}')
products=[];targets=[];schemes=[]
package=obj('FeedKitPackage','{isa = XCRemoteSwiftPackageReference; repositoryURL = '+q('https://github.com/nmdias/FeedKit.git')+'; requirement = {kind = exactVersion; version = 10.9.4;};}')
feedproduct=obj('FeedKitProduct','{isa = XCSwiftPackageProductDependency; package = '+package+'; productName = FeedKit;}')
def make_target(name,platform,sources,uitest=False,widget=False,test_target='HomeViewReplica'):
    product=name+('.xctest' if uitest else '.appex' if widget else '.app');pid=obj('product'+name,'{isa = PBXFileReference; explicitFileType = '+('wrapper.cfbundle' if uitest else 'wrapper.app-extension' if widget else 'wrapper.application')+'; path = '+q(product)+'; sourceTree = BUILT_PRODUCTS_DIR;}');products.append(pid)
    src=[]
    for f in sources:src.append(obj(name+f,'{isa = PBXBuildFile; fileRef = '+uid(f)+';}'))
    sp=obj(name+'sources','{isa = PBXSourcesBuildPhase; buildActionMask = 2147483647; files = '+arr(src)+'; runOnlyForDeploymentPostprocessing = 0;}')
    res=[]
    if not uitest and not widget:
        for f in ['Resources/Assets.xcassets','Resources/demo-tone.wav','Resources/podcast-test-audio.wav','Resources/podcast-caption-test.mp4','Resources/FeedKit-LICENSE.txt']:res.append(obj(name+f,'{isa = PBXBuildFile; fileRef = '+uid(f)+';}'))
    rp=obj(name+'resources','{isa = PBXResourcesBuildPhase; buildActionMask = 2147483647; files = '+arr(res)+'; runOnlyForDeploymentPostprocessing = 0;}')
    frameworks=[obj(name+'FeedKitLink','{isa = PBXBuildFile; productRef = '+feedproduct+';}')] if name=='HomeViewReplica' else []
    fp=obj(name+'frameworks','{isa = PBXFrameworksBuildPhase; buildActionMask = 2147483647; files = '+arr(frameworks)+'; runOnlyForDeploymentPostprocessing = 0;}')
    settings={'PRODUCT_NAME':name,'PRODUCT_BUNDLE_IDENTIFIER':'org.example.'+name,'SWIFT_VERSION':'6.0','GENERATE_INFOPLIST_FILE':'YES','INFOPLIST_FILE':'Resources/Info.plist','CODE_SIGN_STYLE':'Automatic','SWIFT_STRICT_CONCURRENCY':'complete','ENABLE_USER_SCRIPT_SANDBOXING':'YES','MARKETING_VERSION':'0.1.0','CURRENT_PROJECT_VERSION':'1','INFOPLIST_KEY_CFBundleDisplayName':'HomeView','SWIFT_EMIT_LOC_STRINGS':'YES','INFOPLIST_KEY_NSHomeKitUsageDescription':'Use your explicitly connected home only in a separately enabled live build.','INFOPLIST_KEY_NSCalendarsFullAccessUsageDescription':'Show calendars you explicitly authorize in HomeView.','INFOPLIST_KEY_NSRemindersFullAccessUsageDescription':'Show reminders you explicitly authorize in HomeView.','INFOPLIST_KEY_NSAppleMusicUsageDescription':'Play music you explicitly select.','INFOPLIST_KEY_NSCameraUsageDescription':'Use the camera only when you explicitly open the live mirror.','INFOPLIST_KEY_NSMicrophoneUsageDescription':'Use the microphone only when you explicitly start voice input.'}
    if platform=='universal':settings.update({'INFOPLIST_FILE':'Resources/MainInfo.plist','INFOPLIST_FILE[sdk=appletv*]':'Resources/Info.plist','INFOPLIST_FILE[sdk=xr*]':'Resources/Info.plist','SDKROOT':'auto','SUPPORTED_PLATFORMS':'(iphoneos, iphonesimulator, macosx, xros, xrsimulator, appletvos, appletvsimulator)','TARGETED_DEVICE_FAMILY':'1,2','TARGETED_DEVICE_FAMILY[sdk=appletv*]':'3','TARGETED_DEVICE_FAMILY[sdk=xr*]':'7','TARGETED_DEVICE_FAMILY[sdk=macosx*]':'','IPHONEOS_DEPLOYMENT_TARGET':'26.1','MACOSX_DEPLOYMENT_TARGET':'15.0','TVOS_DEPLOYMENT_TARGET':'26.0','XROS_DEPLOYMENT_TARGET':'26.0','SUPPORTS_MACCATALYST':'YES','ASSETCATALOG_COMPILER_APPICON_NAME[sdk=iphone*]':'AppIcon','INFOPLIST_KEY_UIApplicationSceneManifest_Generation':'YES','INFOPLIST_KEY_UILaunchScreen_Generation':'YES','INFOPLIST_KEY_UISupportedInterfaceOrientations':'UIInterfaceOrientationPortrait UIInterfaceOrientationPortraitUpsideDown UIInterfaceOrientationLandscapeLeft UIInterfaceOrientationLandscapeRight','INFOPLIST_KEY_NSAlarmKitUsageDescription':'Schedule timers and alarms you explicitly create in HomeView.','INFOPLIST_KEY_ITSAppUsesNonExemptEncryption':'NO'})
    if platform=='watch':settings.update({'SDKROOT':'watchos','SUPPORTED_PLATFORMS':'(watchos, watchsimulator)','TARGETED_DEVICE_FAMILY':'4','WATCHOS_DEPLOYMENT_TARGET':'26.0','INFOPLIST_KEY_WKApplication':'YES','INFOPLIST_KEY_WKWatchOnly':'YES'})
    if uitest:settings.update({'SDKROOT':'iphoneos','SUPPORTED_PLATFORMS':'(iphoneos, iphonesimulator)','TARGETED_DEVICE_FAMILY':'1,2','IPHONEOS_DEPLOYMENT_TARGET':'26.1','TEST_TARGET_NAME':'HomeViewReplica'})
    if uitest and platform=='tvos':settings.update({'SDKROOT':'appletvos','SUPPORTED_PLATFORMS':'(appletvos, appletvsimulator)','TARGETED_DEVICE_FAMILY':'3','TVOS_DEPLOYMENT_TARGET':'26.0'})
    if uitest and platform=='watch':settings.update({'SDKROOT':'watchos','SUPPORTED_PLATFORMS':'(watchos, watchsimulator)','TARGETED_DEVICE_FAMILY':'4','WATCHOS_DEPLOYMENT_TARGET':'26.0','TEST_TARGET_NAME':test_target})
    if uitest and platform=='vision':settings.update({'SDKROOT':'xros','SUPPORTED_PLATFORMS':'(xros, xrsimulator)','TARGETED_DEVICE_FAMILY':'7','XROS_DEPLOYMENT_TARGET':'26.0'})
    if widget:settings.update({'SDKROOT':'iphoneos','SUPPORTED_PLATFORMS':'(iphoneos, iphonesimulator)','TARGETED_DEVICE_FAMILY':'1,2','IPHONEOS_DEPLOYMENT_TARGET':'26.1','GENERATE_INFOPLIST_FILE':'NO','INFOPLIST_FILE':'Resources/TimerWidgetInfo.plist','SKIP_INSTALL':'YES','APPLICATION_EXTENSION_API_ONLY':'YES','SUPPORTS_MACCATALYST':'NO','INFOPLIST_KEY_CFBundleDisplayName':'HomeView Timers'})
    if widget:settings['PRODUCT_BUNDLE_IDENTIFIER']='org.example.HomeViewReplica.TimerWidget'
    configs=[]
    for conf in ['Debug','Release']:
        s=dict(settings);s['SWIFT_OPTIMIZATION_LEVEL']='-Onone' if conf=='Debug' else '-O';s['DEBUG_INFORMATION_FORMAT']='dwarf';s['SWIFT_ACTIVE_COMPILATION_CONDITIONS']='DEBUG' if conf=='Debug' else ''
        configs.append(obj(name+conf,'{isa = XCBuildConfiguration; buildSettings = '+buildsettings(s)+'; name = '+conf+';}'))
    cl=obj(name+'config','{isa = XCConfigurationList; buildConfigurations = '+arr(configs)+'; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;}')
    deps=[]
    if uitest:
        proxy=obj(name+'testproxy','{isa = PBXContainerItemProxy; containerPortal = '+uid('project')+'; proxyType = 1; remoteGlobalIDString = '+uid(test_target)+'; remoteInfo = '+test_target+';}')
        deps.append(obj(name+'testdep','{isa = PBXTargetDependency; target = '+uid(test_target)+'; targetProxy = '+proxy+';}'))
    phases=[sp,fp,rp]
    if name=='HomeViewReplica':
        embed=obj('timerwidgetembedfile','{isa = PBXBuildFile; fileRef = '+uid('productHomeViewTimerWidget')+'; platformFilters = (ios); settings = {ATTRIBUTES = (RemoveHeadersOnCopy);};}')
        phases.append(obj('timerwidgetembed','{isa = PBXCopyFilesBuildPhase; buildActionMask = 2147483647; dstPath = ""; dstSubfolderSpec = 13; files = '+arr([embed])+'; name = "Embed Timer Widget"; runOnlyForDeploymentPostprocessing = 0;}'))
        proxy=obj('timerwidgetproxy','{isa = PBXContainerItemProxy; containerPortal = '+uid('project')+'; proxyType = 1; remoteGlobalIDString = '+uid('HomeViewTimerWidget')+'; remoteInfo = HomeViewTimerWidget;}')
        deps.append(obj('timerwidgetdep','{isa = PBXTargetDependency; platformFilters = (ios); target = '+uid('HomeViewTimerWidget')+'; targetProxy = '+proxy+';}'))
    tid=obj(name,'{isa = PBXNativeTarget; buildConfigurationList = '+cl+'; buildPhases = '+arr(phases)+'; buildRules = (); dependencies = '+arr(deps)+'; packageProductDependencies = '+arr([feedproduct] if name=='HomeViewReplica' else [])+'; name = '+q(name)+'; productName = '+q(name)+'; productReference = '+pid+'; productType = '+q('com.apple.product-type.bundle.ui-testing' if uitest else 'com.apple.product-type.app-extension' if widget else 'com.apple.product-type.application')+';}');targets.append(tid)
    return tid
make_target('HomeViewReplica','universal',[f for f in files if not f.startswith('Sources/Widgets/')])
make_target('HomeViewTimerWidget','ios',[f for f in files if f.split('/')[-1] in ['TimerLiveActivity.swift','HomeViewTimerAttributes.swift','HomeViewTimerWidget.swift']],widget=True)
watchfiles=[f for f in files if f.split('/')[-1] in ['AlarmRecurrence.swift','Models.swift','GuestAccessPolicy.swift','DataConnection.swift','SetupIntroduction.swift','AssistantResponseDocument.swift','LocalStateFileReader.swift','SnapshotMigration.swift','AlbumDisplay.swift','PersonalHomeConfiguration.swift','EverydayVoiceCommand.swift','AssistantLimits.swift','AssistantConversation.swift','NativeAssistantAnswers.swift','AnswerSpeechSession.swift','NativeAnswerSpeech.swift','AnswerSpeechActions.swift','WorldClock.swift','CalendarPresentation.swift','DemoDoorbell.swift','PodcastLibrary.swift','PhotoPlacement.swift','PhotoClockInk.swift','FaceConfiguration.swift','ConnectedModels.swift','HomeViewApp.swift','AppModel.swift','WatchRoot.swift','LocalAudioEngine.swift','DisplayWakeController.swift']]
watchfiles += [f for f in files if f.split('/')[-1] in ['TimerLiveActivity.swift','NativeTimerLiveActivity.swift']]
make_target('HomeViewWatch','watch',watchfiles)
make_target('HomeViewUITests','ios',['Tests/UITests/HomeViewUITests.swift'],True)
make_target('HomeViewTVUITests','tvos',['Tests/TVUITests/HomeViewTVUITests.swift'],True)
make_target('HomeViewWatchUITests','watch',['Tests/WatchUITests/HomeViewWatchUITests.swift'],True,test_target='HomeViewWatch')
make_target('HomeViewVisionUITests','vision',['Tests/VisionUITests/HomeViewVisionUITests.swift'],True)
pg=obj('products','{isa = PBXGroup; children = '+arr(products)+'; name = Products; sourceTree = "<group>";}')
fg=obj('files','{isa = PBXGroup; children = '+arr([uid(f) for f in files]+[uid('Resources/Assets.xcassets'),uid('Resources/demo-tone.wav'),uid('Resources/podcast-test-audio.wav'),uid('Resources/podcast-caption-test.mp4'),uid('Resources/FeedKit-LICENSE.txt'),uid('Tests/UITests/HomeViewUITests.swift'),uid('Tests/TVUITests/HomeViewTVUITests.swift'),uid('Tests/WatchUITests/HomeViewWatchUITests.swift'),uid('Tests/VisionUITests/HomeViewVisionUITests.swift')])+'; name = Sources; sourceTree = "<group>";}')
mg=obj('main','{isa = PBXGroup; children = '+arr([fg,pg])+'; sourceTree = "<group>";}')
configs=[]
for c in ['Debug','Release']:configs.append(obj('project'+c,'{isa = XCBuildConfiguration; buildSettings = {CLANG_ENABLE_MODULES = YES;}; name = '+c+';}'))
cl=obj('projectconfig','{isa = XCConfigurationList; buildConfigurations = '+arr(configs)+'; defaultConfigurationIsVisible = 0; defaultConfigurationName = Release;}')
obj('project','{isa = PBXProject; attributes = {BuildIndependentTargetsInParallel = YES; LastUpgradeCheck = 2700;}; buildConfigurationList = '+cl+'; compatibilityVersion = "Xcode 14.0"; developmentRegion = en; hasScannedForEncodings = 0; knownRegions = (en, Base); mainGroup = '+mg+'; productRefGroup = '+pg+'; projectDirPath = ""; projectRoot = ""; packageReferences = '+arr([package])+'; targets = '+arr(targets)+';}')
p=root/'HomeViewReplica.xcodeproj';p.mkdir(exist_ok=True)
(p/'project.pbxproj').write_text('// !$*UTF8*$!\n{ archiveVersion = 1; classes = {}; objectVersion = 56; objects = {\n'+''.join(k+' = '+v+';\n' for k,v in objects.items())+'}; rootObject = '+uid('project')+'; }\n')
scheme=p/'xcshareddata/xcschemes';scheme.mkdir(parents=True,exist_ok=True)
for scheme_name,name,test_name in [('HomeViewReplica','HomeViewReplica','HomeViewUITests'),('HomeViewWatch','HomeViewWatch','HomeViewWatchUITests'),('HomeViewTV','HomeViewReplica','HomeViewTVUITests'),('HomeViewVision','HomeViewReplica','HomeViewVisionUITests')]:
    test='<TestableReference skipped="NO"><BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="'+uid(test_name)+'" BuildableName="'+test_name+'.xctest" BlueprintName="'+test_name+'" ReferencedContainer="container:HomeViewReplica.xcodeproj"/></TestableReference>' if test_name else ''
    ref='<BuildableReference BuildableIdentifier="primary" BlueprintIdentifier="'+uid(name)+'" BuildableName="'+name+'.app" BlueprintName="'+name+'" ReferencedContainer="container:HomeViewReplica.xcodeproj"/>'
    (scheme/(scheme_name+'.xcscheme')).write_text('<?xml version="1.0" encoding="UTF-8"?><Scheme LastUpgradeVersion="2700" version="1.3"><BuildAction parallelizeBuildables="YES" buildImplicitDependencies="YES"><BuildActionEntries><BuildActionEntry buildForTesting="YES" buildForRunning="YES" buildForProfiling="YES" buildForArchiving="YES" buildForAnalyzing="YES">'+ref+'</BuildActionEntry></BuildActionEntries></BuildAction><TestAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" shouldUseLaunchSchemeArgsEnv="YES"><Testables>'+test+'</Testables></TestAction><LaunchAction buildConfiguration="Debug" selectedDebuggerIdentifier="Xcode.DebuggerFoundation.Debugger.LLDB" selectedLauncherIdentifier="Xcode.IDEFoundation.Launcher.LLDB" launchStyle="0" useCustomWorkingDirectory="NO" ignoresPersistentStateOnLaunch="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">'+ref+'</BuildableProductRunnable></LaunchAction><ProfileAction buildConfiguration="Release" shouldUseLaunchSchemeArgsEnv="YES" savedToolIdentifier="" useCustomWorkingDirectory="NO" debugDocumentVersioning="YES"><BuildableProductRunnable runnableDebuggingMode="0">'+ref+'</BuildableProductRunnable></ProfileAction><AnalyzeAction buildConfiguration="Debug"/><ArchiveAction buildConfiguration="Release" revealArchiveInOrganizer="YES"/></Scheme>')
