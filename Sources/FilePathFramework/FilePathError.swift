import Foundation

public struct FilePathError : Error, CustomStringConvertible {
    public init(message: String) {
        self.message = message
    }
    
    public var description: String {
        return message
    }
    
    public var message: String
}
