import ArgumentParser
import Foundation
import XCTest

// MARK: - Helper Class

struct StringCatalogEnum: ParsableCommand {

    struct Error: Swift.Error {
        case unexpectedJSON(message: String? = nil)
    }

    enum Keyword: String, CaseIterable {
        case `continue`, `default`
    }

    private let xcstringsPath: String
    private let outputFilename: String
    private let enumName: String
    private let enumTypealias: String


     func run() throws {
        print("LOADING: \(xcstringsPath)")
        let url = URL(fileURLWithPath: xcstringsPath)
        let data = try Data(contentsOf: url)
        print(data)

        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw Error.unexpectedJSON(message: "cannot parse first level object")
        }

        guard let strings = json["strings"] as? [String: Any] else {
            throw Error.unexpectedJSON(message: "cannot parse `strings`")
        }

        var output = """
            // This file is generated by XcodeStringEnum. Please do *NOT* update it manually.
            // As a common practice, swiftLint is disabled for generated files.
            // swiftlint:disable all

            import SwiftUI

            /// Makes it a bit easier to type.
            typealias \(enumTypealias) = \(enumName)

            /// Generated by StringCatalogEnum, this enum contains all existing Strin Category keys.
            enum \(enumName): String, CaseIterable {

            """

        var cases = [String]()
        var knownCases = [String]()
        for (key, _) in strings {
            guard let name = convertToVariableName(key: key) else {
                print("SKIPPING: \(key)")
                continue
            }
            guard key == name else {
                continue
            }
            guard !knownCases.contains(name) else {
                cases.append("    // TODO: fix duplicated entry - case \(name)\n")
                continue
            }
            knownCases.append(name)

            if Keyword.allCases.map({ $0.rawValue }).contains(name) {
                cases.append("    case `\(name)`\n")
            } else {
                cases.append("    case \(name)\n")
            }
        }
        cases.sort()
        cases.forEach { string in
            output += string
        }

        // ... (rest of the code remains the same)
        
        let outputURL = URL(fileURLWithPath: outputFilename)
        try output.write(to: outputURL, atomically: true, encoding: .utf8)
        print("Written to: \(outputFilename)")
    }

    private func convertToVariableName(key: String) -> String? {
        // Leave only letters and numeric characters
        var result = key.components(separatedBy: CharacterSet.letters.union(CharacterSet.alphanumerics).inverted).joined()

        // Remove leading numeric characters
        while !result.isEmpty {
            let firstLetter = result.prefix(1)
            let digitsCharacters = CharacterSet(charactersIn: "0123456789")
            if CharacterSet(charactersIn: String(firstLetter)).isSubset(of: digitsCharacters) {
                // print("dropping first of: \(result)")
                result = String(result.dropFirst())
            } else {
                break
            }
        }

        // Return nil if empty
        guard !result.isEmpty else {
            return nil
        }

        // Return lowercased string if there's only 1 character
        guard result.count > 1 else {
            return result.lowercased()
        }

        // Change the first character to lowercase
        let firstLetter = result.prefix(1).lowercased()
        let remainingLetters = result.dropFirst()
        result = firstLetter + remainingLetters

        // TODO: uppercase remaining words, e.g. "an example" to "anExample"; currently it's "anexample"
        // TODO: lowercase capitalized words, e.g. "EXAMPLE" to "example"; currently it's "eXAMPLE"

        return result
    }
}

// MARK: - Run Command

StringCatalogEnum.main()
