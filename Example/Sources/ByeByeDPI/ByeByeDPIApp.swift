//
//  ByeDPIApp.swift
//  ByeByeDPI
//
//  Created by developer on 24.02.2026.
//

import SwiftUI
import SwByeDPI

#if DEBUG
let previewProperties = AppProperties()
let previewLnwPermissionManager = LNWPermissionManager()
let previewDomainsManager = DomainsManager(lists: [
    BookTestDomains.domainsList,
    GoogleVideoTestDomains.domainsList,
    InstagramTestDomains.domainsList,
    YouTubeTestDomains.domainsList,
])
let previewStrategiesManager = StrategiesManager(lists: [
    BuiltInDPIeStrategies.strategiesList
])
let previewByeDPIManager = ByeDPIManager()
let previewTestManager = TestManager()
let previewNeManager = NEObservableManager { _, _ in }
#endif

@main
struct ByeByeDPIApp: App {
    
    @StateObject fileprivate var appProps: AppProperties
    @StateObject fileprivate var lnwPermissionManager: LNWPermissionManager
    @StateObject fileprivate var domainsManager: DomainsManager
    @StateObject fileprivate var strategiesManager: StrategiesManager
    @StateObject fileprivate var byeDPIManager: ByeDPIManager
    @StateObject fileprivate var neManager: NEObservableManager
    @StateObject fileprivate var testManager: TestManager
    
    init() {
        //App Delegate launch analogue
        let props = AppProperties.load()
        _appProps = StateObject(wrappedValue: props)
        _lnwPermissionManager = StateObject(wrappedValue: LNWPermissionManager())
        let domainsMngr = DomainsManager()
        if (domainsMngr.lists.isEmpty) {
            //Define default lists for empty manager
            domainsMngr.controller.addListItems([
                //Domains for strategy tests
                BookTestDomains.domainsList,
                CloudflareTestDomains.domainsList,
                DeepSeekTestDomains.domainsList,
                DiscordTestDomains.domainsList,
                FacebookTestDomains.domainsList,
                GithubTestDomains.domainsList,
                GoogleVideoTestDomains.domainsList,
                GoogleAiTestDomains.domainsList,
                GoogleMeetTestDomains.domainsList,
                GooglePlayTestDomains.domainsList,
                InstagramTestDomains.domainsList,
                LinkedInTestDomains.domainsList,
                MiscTestDomains.domainsList,
                RobloxTestDomains.domainsList,
                SocialTestDomains.domainsList,
                SoundCloudTestDomains.domainsList,
                SteamTestDomains.domainsList,
                SuperCellTestDomains.domainsList,
                TelegramTestDomains.domainsList,
                TikTokTestDomains.domainsList,
                TorrentTestDomains.domainsList,
                TorTestDomains.domainsList,
                TwitchTestDomains.domainsList,
                TwitterTestDomains.domainsList,
                VideoTestDomains.domainsList,
                WhatsappTestDomains.domainsList,
                YouTubeTestDomains.domainsList,
                FacebookShortTestDomains.domainsList,
                InstagramShortTestDomains.domainsList,
                TwitterShortTestDomains.domainsList,
                VideoShortTestDomains.domainsList,
                WhatsappShortTestDomains.domainsList,
                
                //Filter --hosts (black lists  for ByeDPI)
                AlfaBankDPIBypassSLD.domainsList,
                GazpromDPIBypassSLD.domainsList,
                GitDPIBypassSLD.domainsList,
                GovDPIBypassSLD.domainsList,
                MAXDPIBypassSLD.domainsList,
                MiscDPIBypassSLD.domainsList,
                NewsDPIBypassSLD.domainsList,
                SberDPIBypassSLD.domainsList,
                TBankDPIBypassSLD.domainsList,
                TwoGISDPIBypassSLD.domainsList,
                VKDPIBypassSLD.domainsList,
                VTBDPIBypassSLD.domainsList,
                YandexDPIBypassSLD.domainsList,
            ])
        }
        _domainsManager = StateObject(wrappedValue: domainsMngr)
        let strategiesMngr = StrategiesManager()
        if (strategiesMngr.lists.isEmpty) {
            //Define built-in strategies for empty manager
            strategiesMngr.controller.addListItems([
                BuiltInDPIeStrategies.strategiesList,
                ExternalDPIeStrategies.strategiesList,
            ])
        }
        _strategiesManager = StateObject(wrappedValue: strategiesMngr)
        _byeDPIManager = StateObject(wrappedValue: ByeDPIManager())
        _neManager = StateObject(wrappedValue: NEObservableManager(initCompletion: { _, _ in }))
        _testManager = StateObject(wrappedValue: TestManager())
    }
    
    var body: some Scene {
        WindowGroup {
            NavigationView {
                HomeScreen()
            }
            .environmentObject(appProps)
            .environmentObject(lnwPermissionManager)
            .environmentObject(domainsManager)
            .environmentObject(strategiesManager)
            .environmentObject(byeDPIManager)
            .environmentObject(neManager)
            .environmentObject(testManager)
        }
    }
}
