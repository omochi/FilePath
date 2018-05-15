import Foundation

private let fm = FileManager.default

public struct FilePath :
    CustomStringConvertible,
    Equatable,
    Hashable,
    Comparable,
    Codable
{
    public init(_ value: String) {
        self.value = value
    }
    
    public init(url: URL) {
        precondition(url.isFileURL)
        self.init(url.path)
    }
    
    public var description: String {
        return asString()
    }
    
    public func asString() -> String {
        return value
    }
    
    public func asURL() -> URL {
        return URL(fileURLWithPath: asString())
    }
    
    public init(from decoder: Decoder) throws {
        let c = try decoder.singleValueContainer()
        let str = try c.decode(String.self)
        self.init(str)
    }
    
    public func encode(to encoder: Encoder) throws {
        var c = encoder.singleValueContainer()
        try c.encode(asString())
    }
    
    public var isAbsolute: Bool {
        return asString().hasPrefix("/")
    }
    
    public var isRelative: Bool {
        return !isAbsolute
    }
    
    public func absolute() -> FilePath {
        if isAbsolute {
            return normalized()
        }
        
        return (FilePath.current + self).normalized()
    }

    public mutating func formAbsolute() {
        self = absolute()
    }

    public func normalized() -> FilePath {
        return FilePath(asNSString().standardizingPath)
    }
    
    public mutating func normalize() {
        self = normalized()
    }
    
    public var components: [FilePath] {
        return asNSString().pathComponents.map(FilePath.init)
    }
    
    public var lastComponent: FilePath {
        return FilePath(asNSString().lastPathComponent)
    }
    
    public var lastComponentWithoutExtension: FilePath {
        return FilePath(lastComponent.asNSString().deletingPathExtension)
    }
    
    public var `extension`: String {
        return asNSString().pathExtension
    }
    
    public var parent: FilePath {
        return FilePath(asNSString().deletingLastPathComponent)
    }
    
    public func children() throws -> [FilePath] {
        return try fm.contentsOfDirectory(atPath: asString())
            .map(FilePath.init)
    }
    
    public func subpaths() throws -> [FilePath] {
        return try fm.subpathsOfDirectory(atPath: asString())
            .map(FilePath.init)
    }
    
    public var exists: Bool {
        return fm.fileExists(atPath: asString())
    }
    
    public var isDirectory: Bool {
        var isDir = ObjCBool(false)
        return fm.fileExists(atPath: asString(), isDirectory: &isDir) && isDir.boolValue
    }
    
    public var isSymbolicLink: Bool {
        guard let _ = try? fm.destinationOfSymbolicLink(atPath: asString()) else {
            return false
        }
        return true
    }
    
    public func createDirectory(withIntermediates: Bool = false) throws {
        try fm.createDirectory(atPath: asString(),
                               withIntermediateDirectories: withIntermediates,
                               attributes: nil)
    }
    
    public func delete(ifExists: Bool = false) throws {
        if ifExists && !exists {
            return
        }
        
        try fm.removeItem(atPath: asString())
    }
    
    public func copy(to destination: FilePath) throws {
        try fm.copyItem(atPath: asString(), toPath: destination.asString())
    }
    
    public func move(to destination: FilePath,
                     deleteDestination: Bool = false,
                     createDirectory: Bool = false) throws
    {
        if deleteDestination {
            try destination.delete(ifExists: true)
        }
        if createDirectory {
            try destination.parent.createDirectory(withIntermediates: true)
        }
        try fm.moveItem(atPath: asString(), toPath: destination.asString())
    }
    
    public func read() throws -> Data {
        return try Data(contentsOf: asURL())
    }
    
    public func write(data: Data, createDirectory: Bool = false) throws {
        if createDirectory {
            try parent.createDirectory(withIntermediates: true)
        }
        try data.write(to: asURL(), options: Data.WritingOptions.atomic)
    }
    
    public func attributes() throws -> [FileAttributeKey: Any] {
        return try fm.attributesOfItem(atPath: asString())
    }
    
    public func openReadingHandle() throws -> FileHandle {
        guard let handle = FileHandle(forReadingAtPath: asString()) else {
            throw FilePathError(message: "open reading handle failed: \(self)")
        }
        return handle
    }
    
    public func openWritingHandle() throws -> FileHandle {
        guard let handle = FileHandle(forWritingAtPath: asString()) else {
            throw FilePathError(message: "open writing handle failed: \(self)")
        }
        return handle
    }
    
    public static var current: FilePath {
        return FilePath(fm.currentDirectoryPath)
    }
    
    public static var temporary: FilePath {
        return FilePath(NSTemporaryDirectory())
    }
    
    public static var permanent: FilePath {
        return FilePath(NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory,
                                                            .userDomainMask,
                                                            true)[0])
    }
    
    public static var cache: FilePath {
        return FilePath(NSSearchPathForDirectoriesInDomains(.cachesDirectory,
                                                            .userDomainMask,
                                                            true)[0])
    }
    
    public var hashValue: Int {
        return value.hashValue
    }
    
    public static func +(a: FilePath, b: FilePath) -> FilePath {
        return FilePath(a.asNSString().appendingPathComponent(b.asString()))
    }
    
    public static func +=(a: inout FilePath, b: FilePath) {
        a = a + b
    }
    
    public static func ==(a: FilePath, b: FilePath) -> Bool {
        return a.value == b.value
    }
    
    public static func <(a: FilePath, b: FilePath) -> Bool {
        return a.value < b.value
    }
    
    private func asNSString() -> NSString {
        return NSString(string: value)
    }
    
    private let value: String
}
