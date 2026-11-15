#  SwByeDPI - Swift wrapper for [byedpi](https://github.com/hufrea/byedpi)

<div align="center">
  <p>
    <img src="https://github.com/mIwr/SwByeDPI/raw/master/RepoAssets/app.svg" alt="ByeDPI Logo" width="200" />
  </p>
</div>

[Русский](./README-ru.md) | English

[![Swift5](https://img.shields.io/badge/language-swift5-orange.svg)](https://github.com/apple/swift)
[![Swift6](https://img.shields.io/badge/language-swift6-orange.svg)](https://github.com/apple/swift)
[![LatestRelease](https://img.shields.io/github/v/release/mIwr/SwByeDPI)](https://github.com/mIwr/SwByeDPI/releases/latest)

[![Swift Package Manager compatible](https://img.shields.io/badge/SPM-compatible-brightgreen.svg?style=flat&colorA=28a745&&colorB=4E4E4E)](https://github.com/apple/swift-package-manager)
[![SPMPlatform](https://img.shields.io/badge/Platforms-iOS%20%7CmacOS%20%7C%20watchOS%20%7C%20tvOS%20%7C%20visionOS%20%7C%20Linux-4E4E4E.svg?colorA=28a745)](#установка-и-настройка)
[![SPMLicense](https://img.shields.io/github/license/mIwr/SwByeDPI)](./LICENSE)

[![PodVersion](https://img.shields.io/cocoapods/v/SwByeDPI.svg?style=flat)](https://cocoapods.org/pods/SwByeDPI)
[![PodPlatform](https://img.shields.io/cocoapods/p/SwByeDPI.svg?style=flat)](https://cocoapods.org/pods/SwByeDPI)
[![PodLicense](https://img.shields.io/cocoapods/l/SwByeDPI.svg?style=flat)](./LICENSE)

Repository represents the Swift framework, which is [native C byedpi](https://github.com/hufrea/byedpi) wrapper

Thanks to [romanvht](https://github.com/romanvht) for his [byedpi-based Android app fork](https://github.com/romanvht/ByeByeDPI). It inspired the creation of this project [along with an iOS app running on this module](./Example/Sources/ByeByeDPI)

## Content

- [Introduction](#introduction)

- [Setup](#setup)

- [Working with ByeDPI](#working-with-byedpi)

- [Additional](#additional)

- [Example app](#example-app)

## Introduction

The module is primarily targeted at iOS, min version 10.0 and newer. Other Apple platforms (macOS 10.12+, tvOS 10.0+, watchOS 3.0+, visionOS 1.0+) are listed as available but have experimental support.

It's also possible to build a solution for other platforms (Android, Linux), but it's not guaranteed to work properly. It's better to build byedpi natively for a specific platform as an executable and use it directly. Such feature also can be used for module development on Linux, which is what was used, as this solution was written in parallel on macOS (XCode) and Linux (VSCode with Swift SDK).

## Setup

### Swift Package Manager

SwByeDPI is available through SPM

There are 3 modules-libraries:

1. [ByeDPIC](./Sources/ByeDPIC) - Low-level compiled C-module. It doesn't contain any ObjC/Swift sources, so it can be used on the oldest Apple devices (supports macOS 10.12+, iOS 9.0+, tvOS 9.0+, watchOS 2.0+, visionOS 1.0+). Not recomended for use
2. [ByeDPIKit](./Sources/ByeDPIKit) - ByeDPIC minimal wrapper. It allows to start/stop native byedpi SOCKS proxy with DPI-evasion parameters. Supports Apple macOS 10.12+, tvOS 10.0+, watchOS 3.0+, visionOS 1.0+. This module doesn't contain any Apple platform-specific checks for byedpi command-line arguments
3. [SwByeDPI](./Sources/SwByeDPI) - ByeDPIC extended wrapper, which is based on ByeDPIKit. It contains byedpi launch config abstractions, proxified (SOCKS) URLSession's init tools, [bundled strategies' and domains' sets for testing and further use](./Assets). Also it contains strategy testing and analyzing features

**SwByeDPI SPM setup**

```swift
//Package dependencies parameter
.package(url: "https://github.com/mIwr/SwByeDPI.git", .from(from: "0.17.3"))

//Target dependencies parameter (SwByeDPI)
.product(name: "SwByeDPI", package: "SwByeDPI")
//Target dependencies parameter (ByeDPIKit)
.product(name: "ByeDPIKit", package: "SwByeDPI")
//Target dependencies parameter (ByeDPIC)
.product(name: "ByeDPIC", package: "SwByeDPI")
```

### CocoaPods

All three pods, similar to SPM, are available for import via CocoaPods. The pod names are identical to those of SPM.

**Note**: [According to CocoaPods information](https://blog.cocoapods.org/CocoaPods-Specs-Repo/), module updates will be published on CocoaPods until December 2026.

## Working with ByeDPI

Launching byedpi in ByeDPIKit and SwByeDPI is identical:

1) Define the command to launch the byedpi SOCKS proxy [according to the documentation](https://github.com/hufrea/byedpi)
2) Launch by passing the byedpi SOCKS proxy command-line arguments
```swift
#if canImport(SwByeDPI)
import SwByeDPI
#else
    #if canImport(ByeDPIKit)
import ByeDPIKit
    #endif
#endif

var args: [String] = []
//...Define the command-line arguments
ByeDPI.start(args: args) { BDError in
    //byedpi launch error processing
}
```
3) After some time, ByeDPI stop
```swift
// General stop procedure
_ = ByeDPI.stop()
// If, upon restarting, the error bind error: Address already in use occurs, it is better to stop using via force stop
_ = ByeDPI.forceStop()
```

## Additional

### SwByeDPI. Strategy testing

To ensure ByeDPI operates more efficiently under various conditions (different internet providers, geolocation, devices, operating systems, etc.), a strategy testing mechanism was implemented on a domain lists

The following parameters can be set for testing:

- Delay between domain requests (seconds). Increasing this value improves test reliability. *Optimal value during testing* - 1 second
- Domain requests count. Increasing this value improves accuracy but reduces overall testing speed. *Optimal value during testing* - 2 requests
- Worker threads count. Increasing this value speeds up testing but reduces test reliability. *Optimal value during testing* - Number of CPU cores * 2
- Response wait timeout (seconds). Increasing this value slows down overall testing speed but improves test reliability. *Optimal value during testing* - 5 seconds
- Domain lists for testing. To select a more comprehensive strategy and analyze the results later, it is recommended to select more domains. If the goal is to open access to only certain resources, then it is worth selecting only those (if there are none, then first add a new list). A large pool of domains for testing naturally slows overall test speed.
- Strategy lists for testing. By default, only the strategy list built into SwByeDPI is available.

A *successful* request to a domain via ByeDPI is defined as a response with a status code of 200..299 or any other, but with a Content-Length header (the fact that information was sent and received in the response body).

So, after testing, you can select a universal strategy (**Important clarification - not the best one for the specific domains being tested**) based on the criterion **More successful requests to domains count - better strategy**

For more fine-tuning, you should analyze the strategy testing results.

### SwByeDPI. Testing results analyzing and optimal strategy define

Strategies tested on specific domains and proven effective (highest number of successful requests passed DPI) can already be used in ByeDPI. However, when fine-tuning ByeDPI's operation is required (configuring bypass for specific domains, using the most effective strategies for specific domains, or defining a universal strategy), simply selecting a strategy from test results is not enough.

To achieve this, a results analysis module was implemented in SwByeDPI, the output of which will be a composite strategy consisting of:

- Bypass for DNS (port 53) - more used when ByeDPI is running in a tunnel
- A Domain lists on which ByeDPI won't work - a blacklist block or ByeDPI-bypass. [According to the byedpi documentation, in the "More details --auto --hosts" section](https://github.com/hufrea/byedpi?tab=readme-ov-file#%D0%BF%D0%BE%D0%B4%D1%80%D0%BE%D0%B1%D0%BD%D0%B5%D0%B5), this block will always appear at the beginning of the composite strategy.
- A list or lists of domains for which the most effective strategies have been selected from those tested - a ByeDPI whitelist block. This block can be located at the beginning if there is no blacklist of domains, or in the middle/end of the composite strategy.
- A strategy that may not be the best for a specific domain, but has demonstrated the best results (the highest number of successful requests that passed DPI), is a universal strategy and can be used for "other" domains when ByeDPI is enabled. This block will always be located at the end of the composite strategy.

The basic operation on strategy testing results, which underlies all analysis, is calculating strategy coverage for a domain list (successful queries to domains in the list). All analysis logic is located in [SBDTestResultAnalyticsUtil.swift](./Sources/SwByeDPI/Util/SBDTestResultAnalyticsUtil.swift)

**Note 1**: Using each block is optional, meaning you can specify the use of all blocks in the composite, use only whitelists, etc.

**Note 2**: Using the default domain lists for testing in ByeDPI --hosts is not optimal. Since ByeDPI only needs to specify second-level domains (Example: if you specify googlevideo.com in --hosts, ByeDPI will also process all subdomains), you can generate a new list (this is what the Strategy Analyzer does) consisting only of unique second-level domains. To do this, you can use the [retrieveSLDList()](./Sources/SwByeDPI/Model/SBDDomainList.swift) function.

```swift
var domainList: SBDDomainList
//...
let sldList = domainList.retrieveSLDList()
```

**Note 3**: To ensure consistency between blocks (Black/White List and Universal Strategy) and the strategies within them (Strategies for Different Domain Lists in the Whitelist), a **-An**-like mapping is used.

### SwByeDPI. Code generation

SwByeDPI module includes lists of sites for testing and ByeDPI bypass, as well as strategies in the form of text files. These files are then used to generate *.swift files, which are then compiled into the resulting module (Built-in domains and strategies). You can edit or delete existing lists, or add new ones.

Generation is performed manually using the [code generator script](./assets_codegen.sh), which defines all files with the *.strategies and *.domains extensions in [Assets](./Assets). **Note**: The list file format is the same for both strategies and domains—one list per line.

## Example app

The [Example app](./Example/Sources/ByeByeDPI) is an iOS app (iOS 14+, SwiftUI). The project can be built for other platforms (Experimental support for tvOS 17.0+ and macOS 11.0+).

The app runs ByeDPI locally and can redirect traffic from other apps and devices on the local network through it.

### Capabilities

The application allows you to:

- Set byedpi launch settings (bind IP address, SOCKS proxy port, command-line arguments)
- Automatically correct byedpi strategy parameters if they are not supported by the device and/or OS
- Test strategies and save the last test run
- Analyze and create the most optimal strategies based on test results
- When creating optimal strategies, you can specify blacklists (byedpi bypass) and whitelists (specific strategies only work for specific domains). [More details --auto --hosts](https://github.com/hufrea/byedpi?tab=readme-ov-file#%D0%BF%D0%BE%D0%B4%D1%80%D0%BE%D0%B1%D0%BD%D0%B5%D0%B5)
- Add/modify/remove domains for testing strategies, filtering domains for byedpi bypass
- Add/modify/remove strategies for testing
- Set DNS (DoH/DoT) - **available only when building a full VPN client**

**Note**: Compared to Android, the VPN Network Extension in iOS cannot manage tunneling for specific apps. This is done using byedpi's own functionality, specifying specific second-level domains (blacklists/whitelists).

For advanced use, you can refer to the [comprehensive instructions from the ByeByeDPI-Manual community](https://github.com/BDManual/ByeByeDPI-Manual).

### Build

There are 3 possible app build options:

- **VPN client (ByeByeDPI)** ByeDPI -> Tun2SocksKit -> NEVPN + DNS - **requires a paid developer license**: an individual account is sufficient for development, debugging, and uploading to TestFlight; a legal entity or sole proprietorship account is required for release in the App Store [according to Apple Developer Guidelines 5.4](https://developer.apple.com/app-store/review/guidelines/#legal). **Note**: The app is not a general VPN client, as ByeDPI runs locally on the device. The VPN trick is needed to enable ByeDPI functionality in the background (when the app is minimized or not running) and to process ByeDPI internet traffic from all apps on the phone and devices on the local network (you must grant the app permission to access the local network). Support for DoH/DoT in the app allows you to bypass geoblocks imposed by the services themselves.
- **ByeDPI SOCKS proxy server (ByeDPI)** - for running on your own devices, **does not require a paid developer license**. This build is ideal for debugging and testing app functionality on endpoints: you can test strategies and create an optimal composite using an analyzer. The caveat here is that ByeDPI will only work while the app is open (foreground).
- **ByeDPI SOCKS proxy server with background support (ByeDPIBg)** - Same as the above option, but with background support when the app is minimized via endlessly playing silent audio that doesn't interrupt regular audio (mixWithOthers)

1. Clone the current repository:

```
git clone https://github.com/mIwr/SwByeDPI
```

2. Add certificates and private keys for signing the application to your keyring, import the development profiles

In Apple Developer, for your app (VPN client), you need to do the following (assuming you already have at least a development certificate and are managing signatures manually):

- Register an App Group ID that will link the host app and Network Extension
- Register an App ID for the host app. In Entitlements, specify App Groups (indicating the one you created earlier), Network Extensions, and Personal VPN
- Register an App ID for the Network Extension. In Entitlements, specify the same items as for the host app
- Create development profiles for the host app and Network Extension
- Import the profiles into Xcode

3. Run the application build (ByeByeDPI or ByeDPI) via the XCode GUI or Terminal

**Unsigned build create (AltStore/SideStore/TrollStore/LiveContainer etc.)**

Two schemes (ByeDPIBg, ByeByeDPI) are built using *xcodebuild* and packaged into an IPA using [xcodebuild_unsigned.sh](./xcodebuild_unsigned.sh)

Artifacts from the script's output are located in [Releases](https://github.com/mIwr/SwByeDPI/releases/latest)

### Problems and solutions

- The VPN tunnel has started, but websites don't open, and the logs (Console.app) show a cyclical 'udp session start - connect - destruct' message. This is related to the ByeDPI address 127.0.0.1/localhost. In Network Extension, the OS drops all packets to this address. You must specify a different local address. **Note**: When connected to Wi-Fi, the local IP address from your ISP will be automatically substituted if 127.0.0.1, ::1, 0.0.0.0, or :: is specified.
- Before iOS 14, the app will be extremely unstable due to the [hard limits for Network Extension](http://www.openradar.appspot.com/27660401) - 15 MB. After exceeding this limit, the OS will kill the VPN tunnel without warning or crash. The solution is to use the app on iOS 15+ smartphones, where the limit is already 50 MB. **Note**: During testing, it was found that with the [correct Tun2SOCKS config](https://github.com/heiher/hev-socks5-tunnel?tab=readme-ov-file#low-memory-usage) RAM consumption does not even exceed **15 MB (On average, it remained at 4.3-4.8 MB)**, so, theoretically, this NetworkExtension can be ported to UIKit rails to provide support even for iOS 10.0+ with a 15 MB limitation per Network Extension
- Constant increase in RAM usage during tunnel operation (web surfing, etc.) from the very start up until SIGKILL from the OS - log redirection from stdout/stderr is enabled (hev-socks-tunnel, byedpi), which must be disabled/commented out in the code, including the commands for setting the logging level for byedpi/Tun2SOCKS

### Screenshots

<p align="center">
<img src="https://github.com/mIwr/SwByeDPI/blob/master/RepoAssets/home.png?raw=true"> 
<img src="https://github.com/mIwr/SwByeDPI/blob/master/RepoAssets/settings.png?raw=true"> 
<img src="https://github.com/mIwr/SwByeDPI/blob/master/RepoAssets/domains.png?raw=true"> 
<img src="https://github.com/mIwr/SwByeDPI/blob/master/RepoAssets/strategies.png?raw=true"> 
<img src="https://github.com/mIwr/SwByeDPI/blob/master/RepoAssets/tester.png?raw=true"> 
<img src="https://github.com/mIwr/SwByeDPI/blob/master/RepoAssets/test_settings.png?raw=true"> 
<img src="https://github.com/mIwr/SwByeDPI/blob/master/RepoAssets/analyzer.png?raw=true"> 
</p>

