//
//  PacketTunnelProvider.swift
//  ByeByeDPITun
//
//  Created by developer on 25.03.2026.
//

import CoreFoundation
import SystemConfiguration
import NetworkExtension
import Tun2SocksKit
#if canImport(ByeDPIKit)
import ByeDPIKit
#elseif canImport(ByeDPIKitLib)
import ByeDPIKitLib
#endif
//import OSLog

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    // Redirects Tun2SOCKS, byedpi stdout/stderr to Console.app
    /*fileprivate static func setupLogRedirection() {
        let pipe = Pipe()
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDERR_FILENO)
        let logger = Logger(subsystem: Constants.PSEUDO_BUNDLE_ID, category: "BBD-NETUN")
        
        Thread.detachNewThread {
            let fileHandle = pipe.fileHandleForReading
            while true {
                let data = fileHandle.availableData
                if data.isEmpty { break }
                if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines), !output.isEmpty {
                    // Записываем в системный лог Apple
                    logger.debug("\(output, privacy: .public)")
                }
            }
        }
    }*/
    
    private enum NetworkInterface: UInt8 {
        case none
        case wifi
        case wwan
    }
    
    private static var enabledNetworkInterface: NetworkInterface {
        get {
            var zeroAddress = sockaddr_in()
            zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
            zeroAddress.sin_family = sa_family_t(AF_INET)
            
            guard let reachability = withUnsafePointer(to: &zeroAddress, {
                $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                    SCNetworkReachabilityCreateWithAddress(nil, $0)
                }
            }) else {
                return .none
            }
            
            var flags: SCNetworkReachabilityFlags = []
            if (!SCNetworkReachabilityGetFlags(reachability, &flags)) {
                return .none
            }
            
            let isReachable = flags.contains(.reachable)
            let needsConnection = flags.contains(.connectionRequired)
            let canConnectAutomatically = flags.contains(.connectionOnDemand) || flags.contains(.connectionOnTraffic)
            let canConnectWithoutUserInteraction = canConnectAutomatically && !flags.contains(.interventionRequired)
            
            let isNetworkReachable = isReachable && (!needsConnection || canConnectWithoutUserInteraction)
            
            if !isNetworkReachable {
                return .none
            }
            
            #if os(iOS)
            if flags.contains(.isWWAN) {
                return .wwan
            }
            #endif
            
            return .wifi
        }
    }

    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        let cachedConfig = protocolConfiguration as? NETunnelProviderProtocol
        let stockSocksListenIp = options?[UserDefaultsAppKeys.selectedByeDPIListenIpAddrKey.rawValue] as? String ?? cachedConfig?.byeDPIListenIp ?? "127.0.0.1"
        var socksListenIp = stockSocksListenIp
        if (socksListenIp == "127.0.0.1" || socksListenIp == "::1" || socksListenIp == "0.0.0.0" || socksListenIp == "::") {
            //Update listen IP
            if (PacketTunnelProvider.enabledNetworkInterface == .wifi) {
                //Wi-Fi or Ethernet -> Get device local IP address
                if let localAddress = getLNWAddress(), !localAddress.isEmpty {
                    socksListenIp = localAddress
                } else {
                    socksListenIp = "0.0.0.0"
                }
            }/* else {
                if let cellularAddress = getCellularAddress(), !cellularAddress.isEmpty {
                   socksListenIp = cellularAddress
                } else {
                    socksListenIp = "0.0.0.0"
                }
            }*/
        }
        
        var port = options?[UserDefaultsAppKeys.selectedByeDPIListenPortKey.rawValue] as? UInt16 ?? cachedConfig?.byeDPIListenPort ?? 10800
        if (port == 0) {
            port = 10800
        }
        var bufSize = options?[UserDefaultsAppKeys.selectedByeDPIBufSizeKey.rawValue] as? UInt32 ?? cachedConfig?.byeDPIBufSize ?? 16384
        if (bufSize == 0) {
            bufSize = 16384
        }
        var maxConn = options?[UserDefaultsAppKeys.selectedByeDPIMaxConn.rawValue] as? UInt16 ?? cachedConfig?.byeDPIMaxConn ?? 512
        if (maxConn == 0) {
            maxConn = 512
        }
        let ttl = options?[UserDefaultsAppKeys.selectedByeDPITTL.rawValue] as? UInt8 ?? cachedConfig?.byeDPITTL
        let noDomain = options?[UserDefaultsAppKeys.byeDPIRestrictDomainResolve.rawValue] as? Bool ?? cachedConfig?.byeDPINoDomains ?? false
        let noUDP = options?[UserDefaultsAppKeys.byeDPIRestrictUDP.rawValue] as? Bool ?? cachedConfig?.byeDPINoUDP ?? false
        let logLevelRaw = options?[UserDefaultsAppKeys.selectedbyeDPILogLevel.rawValue] as? UInt8 ?? cachedConfig?.byeDPILogLevel
        var args: [String] = [
            "-i", socksListenIp,
            "-p", String(port),
            "-b", String(bufSize),
            "-c", String(maxConn)
        ]
        if let safeTtl = ttl, safeTtl != 0 {
            args.append(contentsOf: ["-g", String(safeTtl)])
        }
        if (noDomain) {
            args.append("-N")
        }
        if (noUDP) {
            args.append("-U")
        }
        if let safeLogLevel = logLevelRaw {
            args.append(contentsOf: ["-x", String(safeLogLevel)])
        }
        
        if let safeArgs = options?[UserDefaultsAppKeys.selectedByeDPICmdArgsKey.rawValue] as? [String] ?? cachedConfig?.byeDPICmdArgs, !safeArgs.isEmpty {
            args = safeArgs
            if (args[0] == "-i" && args.count > 1) {
                //Override config bind ip address
                args[1] = socksListenIp
            }
        }
        
        let tunMtu = options?[UserDefaultsAppKeys.selectedTunMtuKey.rawValue] as? UInt16 ?? cachedConfig?.tunMtu ?? 1500
        let tunIpAddr = "10.0.0.1"
        //iOS <10 - ~5mb memory max
        //iOS 10..14 - 15 mb memory max
        //iOS 15+ - 50 mb memory max
        //iOS Low memory usage tips - https://github.com/heiher/hev-socks5-tunnel?tab=readme-ov-file#low-memory-usage
        var tun2SocksConfigYAML = """
tunnel:
  mtu: \(tunMtu)

socks5:
  port: \(port)
  address: \(socksListenIp)
  udp: 'udp'

misc:
  task-stack-size: 24576 # 20480 + tcp-buffer-size 
  tcp-buffer-size: 4096 
  max-session-count: 1200 
"""
#if DEBUG
        //args.insert("-x2", at: 0)
        //tun2SocksConfigYAML += "\n  log-file: stdout\n  log-level: debug"
        //PacketTunnelProvider.setupLogRedirection()
#endif
        
        let tunnelSettings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: socksListenIp)
        tunnelSettings.mtu = NSNumber(integerLiteral: Int(tunMtu))
        //Set default DNS
        let dnsSettings = NEDNSSettings(servers: ["8.8.8.8", "8.8.4.4", "1.1.1.1"])
        dnsSettings.matchDomains = [""]
        tunnelSettings.dnsSettings = dnsSettings
        if let safeDnsAddr = options?[UserDefaultsAppKeys.selectedDnsOverAddrKey.rawValue] as? String ?? cachedConfig?.dnsOverAddr, !safeDnsAddr.isEmpty {
            if (safeDnsAddr.hasPrefix("http") || safeDnsAddr.split(separator: ".").count != 4) {
                //DoH or DoT
                if let safeResolvedServers = options?[UserDefaultsAppKeys.resolvedDnsServersKey.rawValue] as? [String] ?? cachedConfig?.resolvedDnsServers, !safeResolvedServers.isEmpty {
                    if (safeDnsAddr.hasPrefix("http")) {
                        //DoH
                        let dohSettings = NEDNSOverHTTPSSettings(servers: safeResolvedServers)
                        if let safeUrl = URL(string: safeDnsAddr) {
                            dohSettings.serverURL = safeUrl
                            dohSettings.matchDomains = [""]
                            tunnelSettings.dnsSettings = dohSettings
                        }
                    } else {
                        //DoT
                        let dotSettings = NEDNSOverTLSSettings(servers: safeResolvedServers)
                        dotSettings.serverName = safeDnsAddr
                        dotSettings.matchDomains = [""]
                        tunnelSettings.dnsSettings = dotSettings
                    }
                }
            } else {
                //General plain DNS
                let dnsSettings = NEDNSSettings(servers: [safeDnsAddr])
                dnsSettings.matchDomains = [""]
                tunnelSettings.dnsSettings = dnsSettings
            }
        }
        let ipv4Settings = NEIPv4Settings(addresses: [tunIpAddr], subnetMasks: ["255.255.255.0"])
        ipv4Settings.includedRoutes = [
            NEIPv4Route.default()
        ]
        ipv4Settings.excludedRoutes = [
            NEIPv4Route(destinationAddress: "192.168.0.0", subnetMask: "255.255.0.0"),
            NEIPv4Route(destinationAddress: "172.16.0.0", subnetMask: "255.240.0.0"),
            NEIPv4Route(destinationAddress: "10.0.0.0",    subnetMask: "255.0.0.0"),
            NEIPv4Route(destinationAddress: "100.64.0.0",  subnetMask: "255.192.0.0"),
            //Check https://dns.quic.best/
            // Google DNS
            NEIPv4Route(destinationAddress: "8.8.8.8", subnetMask: "255.255.255.255"),
            NEIPv4Route(destinationAddress: "8.8.4.4", subnetMask: "255.255.255.255"),
            // Cloudflare DNS
            NEIPv4Route(destinationAddress: "1.1.1.1", subnetMask: "255.255.255.255"),
            NEIPv4Route(destinationAddress: "1.0.0.1", subnetMask: "255.255.255.255"),
            // Quad9 DNS
            NEIPv4Route(destinationAddress: "9.9.9.9", subnetMask: "255.255.255.255"),
            NEIPv4Route(destinationAddress: "149.112.112.112", subnetMask: "255.255.255.255"),
            // Comss DNS
            NEIPv4Route(destinationAddress: "83.220.169.155", subnetMask: "255.255.255.255"),
            NEIPv4Route(destinationAddress: "195.133.25.16", subnetMask: "255.255.255.255"),
            NEIPv4Route(destinationAddress: "212.109.195.93", subnetMask: "255.255.255.255"),
            // Adguard DNS
            NEIPv4Route(destinationAddress: "94.140.14.14", subnetMask: "255.255.255.255"),
            NEIPv4Route(destinationAddress: "94.140.14.15", subnetMask: "255.255.255.255"),
        ]
        if (socksListenIp != "0.0.0.0") {
            ipv4Settings.excludedRoutes?.append(NEIPv4Route(destinationAddress: socksListenIp, subnetMask: "255.255.255.255"))
        }
        tunnelSettings.ipv4Settings = ipv4Settings
    
        let tun2SocksConfig = Socks5Tunnel.Config.string(content: tun2SocksConfigYAML)
        
        setTunnelNetworkSettings(tunnelSettings) { setErr in
            if let safeSetErr = setErr {
                completionHandler(safeSetErr)
                return
            }
            Task(priority: .high) {
                if let byeDPIStartErr = await ByeDPI.start(args: args) {
                    completionHandler(byeDPIStartErr)
                    UserDefaultsAppProperties.byeDPIVPNRunning = false
                    if let safeCenter = CFNotificationCenterGetDarwinNotifyCenter() {
                        CFNotificationCenterPostNotification(safeCenter, .byeDPIVpnStopped, nil, nil, true)
                    }
                    return
                }
                let hevSocksStartOpCode = await Socks5Tunnel.run(with: tun2SocksConfig)
                if (hevSocksStartOpCode == 0) {
                    UserDefaultsAppProperties.byeDPIVPNRunning = true
                    if let safeCenter = CFNotificationCenterGetDarwinNotifyCenter() {
                        CFNotificationCenterPostNotification(safeCenter, .byeDPIVpnStarted, nil, nil, true)
                    }
                    completionHandler(nil)
                    return
                }
                _ = ByeDPI.forceStop()
                UserDefaultsAppProperties.byeDPIVPNRunning = false
                if let safeCenter = CFNotificationCenterGetDarwinNotifyCenter() {
                    CFNotificationCenterPostNotification(safeCenter, .byeDPIVpnStopped, nil, nil, true)
                }
                completionHandler(NSError(domain: NEVPNErrorDomain, code: Int(hevSocksStartOpCode)))
            }
        }
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        UserDefaultsAppProperties.byeDPIVPNRunning = false
        if let safeCenter = CFNotificationCenterGetDarwinNotifyCenter() {
            CFNotificationCenterPostNotification(safeCenter, .byeDPIVpnStopped, nil, nil, true)
        }
        Socks5Tunnel.stop()
        if (ByeDPI.proxyStarted) {
            _ = ByeDPI.forceStop()
        }
        completionHandler()
    }
    
    override func handleAppMessage(_ messageData: Data, completionHandler: ((Data?) -> Void)?) {
        if let handler = completionHandler {
            handler(messageData)
        }
    }
    
    override func sleep(completionHandler: @escaping () -> Void) {
        UserDefaultsAppProperties.byeDPIVPNRunning = false
        if let safeCenter = CFNotificationCenterGetDarwinNotifyCenter() {
            CFNotificationCenterPostNotification(safeCenter, .byeDPIVpnStopped, nil, nil, true)
        }
        completionHandler()
    }
    
    override func wake() {
        UserDefaultsAppProperties.byeDPIVPNRunning = true
        if let safeCenter = CFNotificationCenterGetDarwinNotifyCenter() {
            CFNotificationCenterPostNotification(safeCenter, .byeDPIVpnStarted, nil, nil, true)
        }
    }
    
    func getLNWAddress() -> String? {
        var address: String?

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family

            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if (!name.hasPrefix("en")) {
                    // Not Wi-Fi -> Skip
                    continue
                }
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                            &hostname, socklen_t(hostname.count),
                            nil, socklen_t(0), NI_NUMERICHOST)
                address = String(cString: hostname)
                if (name == "en0") {
                    break
                }
            }
        }
        freeifaddrs(ifaddr)

        return address
    }
    
    func getCellularAddress() -> String? {
        var address: String?

        var ifaddr: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&ifaddr) == 0 else { return nil }
        guard let firstAddr = ifaddr else { return nil }

        for ptr in sequence(first: firstAddr, next: { $0.pointee.ifa_next }) {
            let interface = ptr.pointee
            let addrFamily = interface.ifa_addr.pointee.sa_family

            if addrFamily == UInt8(AF_INET) {
                let name = String(cString: interface.ifa_name)
                if (!name.hasPrefix("pdp_ip")) {
                    // Not cellular -> Skip
                    continue
                }
                var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                getnameinfo(interface.ifa_addr, socklen_t(interface.ifa_addr.pointee.sa_len),
                            &hostname, socklen_t(hostname.count),
                            nil, socklen_t(0), NI_NUMERICHOST)
                address = String(cString: hostname)
                if (name == "pdp_ip0") {
                    break
                }
            }
        }
        freeifaddrs(ifaddr)

        return address
    }
}
