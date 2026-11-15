//
//  AppProperties.swift
//  SwByeDPI
//
//  Created by Developer on 21.02.2026.
//

import Foundation
import SwByeDPI

class AppProperties: Codable, ObservableObject
{
    fileprivate static let _defaultDoH = "https://dns.comss.one/dns-query"
    fileprivate static let _defaultResolvedDnsServers = ["83.220.169.155", "195.133.25.16", "212.109.195.93"]
    fileprivate static let _plistFilename = Constants.PSEUDO_BUNDLE_ID
    
    @Published var byeDPILaunchConfig: SBDConfig {
        willSet {
            UserDefaultsAppProperties.byeDPIListenIp = newValue.listenIP
            UserDefaultsAppProperties.byeDPIListenPort = newValue.listenPort
            UserDefaultsAppProperties.byeDPIBufSize = newValue.bufSize
            UserDefaultsAppProperties.byeDPIMaxConn = newValue.maxConn
            UserDefaultsAppProperties.byeDPITTL = newValue.ttl
            UserDefaultsAppProperties.byeDPIRestrictDomainResolve = newValue.noDomain
            UserDefaultsAppProperties.byeDPIRestrictUDP = newValue.noUDP
            UserDefaultsAppProperties.byeDPILogLevel = newValue.logLevelRaw
            UserDefaultsAppProperties.byeDPICmdArgs = newValue.args
            let cmdLine = newValue.cmdArgs.joined(separator: " ")
            if (_byeDPICmdEditorHistorySet.contains(cmdLine)) {
                for i in 0..<byeDPICmdEditorHistory.count {
                    if (byeDPICmdEditorHistory[i] != cmdLine) {
                        continue
                    }
                    byeDPICmdEditorHistory.remove(at: i)
                    break
                }
            } else {
                _byeDPICmdEditorHistorySet.insert(cmdLine)
            }
            byeDPICmdEditorHistory.insert(cmdLine, at: 0)
        }
    }
    
    @Published var byeDPITestConfig: SBDTestConfig
    
    @Published fileprivate(set) var byeDPICmdEditorHistory: [String]
    fileprivate var _byeDPICmdEditorHistorySet: Set<String>
    var byeDPICmdEditorHistorySet: Set<String> {
        get {
            return Set<String>(byeDPICmdEditorHistory)
        }
    }
    
    @Published var byeDPIDomainListsIDsBypass: Set<String>
    
    @Published var dnsOverAddr: String {
        didSet {
            UserDefaultsAppProperties.dnsOverAddr = dnsOverAddr
        }
    }
    
    @Published var resolvedDnsServers: [String] {
        didSet {
            UserDefaultsAppProperties.resolvedDnsServers = resolvedDnsServers
        }
    }
    
    @Published var tunMtu: UInt16 {
        didSet {
            UserDefaultsAppProperties.tunMtu = tunMtu
        }
    }
    
#if DEBUG
    init() {
        byeDPILaunchConfig = SBDConfig(commandArgs: ["-s1", "-d1", "-r1+s", "-a1", "-Ar", "-o1", "-a1", "-At", "-r1+s", "-a1"])
        byeDPITestConfig = SBDTestConfig(domainRequestsCount: 2, parallelRequestsCount: 5, domainAnswerTimeoutInS: 3, delayBetweenRequestsInS: 1, fakeSNI: "google.com", domainListIDs: Set(), strategyListIDs: Set())
        byeDPICmdEditorHistory = [
            SBDConfig(commandArgs: ["-s1", "-d1", "-r1+s", "-a1", "-Ar", "-o1", "-a1", "-At", "-r1+s", "-a1"]).cmdArgs.joined(separator: " "),
            SBDConfig(commandArgs: ["-n", "google.com", "-d1", "-s1+s", "-r1+s", "-e1", "-m1", "-o1+s", "-t2", "-a1"]).cmdArgs.joined(separator: " ")
        ]
        _byeDPICmdEditorHistorySet = Set<String>([
            SBDConfig(commandArgs: ["-s1", "-d1", "-r1+s", "-a1", "-Ar", "-o1", "-a1", "-At", "-r1+s", "-a1"]).cmdArgs.joined(separator: " "),
            SBDConfig(commandArgs: ["-n", "google.com", "-d1", "-s1+s", "-r1+s", "-e1", "-m1", "-o1+s", "-t2", "-a1"]).cmdArgs.joined(separator: " ")
        ])
        byeDPIDomainListsIDsBypass = [
            YandexDPIBypassSLD.domainsList.id
        ]
        resolvedDnsServers = AppProperties._defaultResolvedDnsServers
        dnsOverAddr = AppProperties._defaultDoH
        tunMtu = 1500
    }
#endif
    
    init(byeDPILaunchConfig: SBDConfig, byeDPITestConfig: SBDTestConfig, byeDPICmdEditorHistory: [String], byeDPIDomainListsIDsBypass: Set<String>, resolvedDnsServers: [String], dnsOverAddr: String, tunMtu: UInt16)
    {
        self.byeDPILaunchConfig = byeDPILaunchConfig
        self.byeDPITestConfig = byeDPITestConfig
        self.byeDPICmdEditorHistory = byeDPICmdEditorHistory
        self._byeDPICmdEditorHistorySet = Set<String>(byeDPICmdEditorHistory)
        self.byeDPIDomainListsIDsBypass = byeDPIDomainListsIDsBypass
        self.resolvedDnsServers = resolvedDnsServers
        self.dnsOverAddr = dnsOverAddr
        self.tunMtu = tunMtu
    }
    
    func removeRecentCmd(at index: Int) -> String? {
        if (index < 0 || index >= byeDPICmdEditorHistory.count) {
            return nil
        }
        return byeDPICmdEditorHistory.remove(at: index)
    }
    
    ///Save application properties
    func save()
    {
        if (PlistUtil.savePropertyList(self, filename: AppProperties._plistFilename)) {
            return
        }
#if DEBUG
            print("Application properties not saved")
#endif
    }
    
    ///Load application properties with specific filename
    class func load() -> AppProperties
    {
        if let loadedProperties: AppProperties = PlistUtil.parsePropertyList(filename: AppProperties._plistFilename)
        {
            syncUserDefaults(properties: loadedProperties)
            return loadedProperties
        }
        let cpuCores = UInt8(ProcessInfo.processInfo.processorCount)
        let properties = AppProperties(byeDPILaunchConfig: SBDConfig(), byeDPITestConfig: SBDTestConfig(domainRequestsCount: 2, parallelRequestsCount: cpuCores * 2, domainAnswerTimeoutInS: 5, delayBetweenRequestsInS: 1, fakeSNI: "google.com", domainListIDs: Set<String>([
            YouTubeTestDomains.domainsList.id,
            GoogleVideoTestDomains.domainsList.id
        ]), strategyListIDs: Set<String>([
            BuiltInDPIeStrategies.strategiesList.id
        ])), byeDPICmdEditorHistory: [], byeDPIDomainListsIDsBypass: [
            AlfaBankDPIBypassSLD.domainsList.id,
            GazpromDPIBypassSLD.domainsList.id,
            GitDPIBypassSLD.domainsList.id,
            GovDPIBypassSLD.domainsList.id,
            MAXDPIBypassSLD.domainsList.id,
            MiscDPIBypassSLD.domainsList.id,
            NewsDPIBypassSLD.domainsList.id,
            SberDPIBypassSLD.domainsList.id,
            TBankDPIBypassSLD.domainsList.id,
            TwoGISDPIBypassSLD.domainsList.id,
            VKDPIBypassSLD.domainsList.id,
            VTBDPIBypassSLD.domainsList.id,
            YandexDPIBypassSLD.domainsList.id,
        ], resolvedDnsServers: AppProperties._defaultResolvedDnsServers, dnsOverAddr: AppProperties._defaultDoH, tunMtu: 1500)
        properties.save()
        syncUserDefaults(properties: properties)
        return properties
    }
    
    fileprivate class func syncUserDefaults(properties: AppProperties) {
        UserDefaultsAppProperties.byeDPIListenIp = properties.byeDPILaunchConfig.listenIP
        UserDefaultsAppProperties.byeDPIListenPort = properties.byeDPILaunchConfig.listenPort
        UserDefaultsAppProperties.byeDPIBufSize = properties.byeDPILaunchConfig.bufSize
        UserDefaultsAppProperties.byeDPITTL = properties.byeDPILaunchConfig.ttl
        UserDefaultsAppProperties.byeDPIRestrictDomainResolve = properties.byeDPILaunchConfig.noDomain
        UserDefaultsAppProperties.byeDPIRestrictUDP = properties.byeDPILaunchConfig.noUDP
        UserDefaultsAppProperties.byeDPILogLevel = properties.byeDPILaunchConfig.logLevelRaw
        UserDefaultsAppProperties.byeDPICmdArgs = properties.byeDPILaunchConfig.args
        UserDefaultsAppProperties.dnsOverAddr = properties.dnsOverAddr
        UserDefaultsAppProperties.resolvedDnsServers = properties.resolvedDnsServers
        UserDefaultsAppProperties.tunMtu = properties.tunMtu
    }
}
