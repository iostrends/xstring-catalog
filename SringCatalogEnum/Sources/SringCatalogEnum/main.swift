import ArgumentParser
import Foundation

// TODO: make XCStrings Decodable by listing all possible models
/*
struct XCStrings: Decodable {
    let sourceLanguage: String
    let version: String
    let strings: [String: String]
}
*/

struct SringCatalogEnum: ParsableCommand {
    enum Error: Swift.Error {
        case unexpectedJSON(message: String? = nil)
    }

    // @Argument(help: "The phrase to repeat.")
    // var phrase: String

    // @Flag(help: "Include a counter with each repetition.")
    // var includeCounter = false

    @Option(name: .shortAndLong, help: "Full path and filename of the 'xcstrings' file.")
    var xcstringsPath: String

    func run() throws {
        print("LOADING: \(xcstringsPath)")
        let url = URL(fileURLWithPath: xcstringsPath)
        // let contents = try String(contentsOf: url, encoding: .utf8)
        // print(contents)
        let data = try Data(contentsOf: url)
        print(data)
        // let obj = try JSONDecoder().decode(XCStrings.self, from: data)

        guard let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any] else {
            throw Error.unexpectedJSON(message: "cannot parse first level object")
        }
            
        guard let strings = json["strings"] as? [String: Any] else {
            throw Error.unexpectedJSON(message: "cannot parse `strings`")
        }
        // print(strings)

        for (key, _) in strings {
            guard let name = convertToVariableName(key) else {
                print("SKIPPING: \(key)")
                continue
            }
            print("\(name):\t\(key)")
        }
    }

    private func convertToVariableName(_ str: String) -> String? {
        // str.components(separatedBy: CharacterSet.alphanumerics.inverted).joined().lowercased()
        var result = str.components(separatedBy: CharacterSet.letters.union(CharacterSet.alphanumerics).inverted).joined()
        // let result = String(str.unicodeScalars.filter(CharacterSet.letters.contains || CharacterSet.alphanumerics.contains))
        // return str.removeNonLetters()

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

        // Only 1 character
        guard result.count > 1 else {
            return result.lowercased()
        }

        let firstLetter = result.prefix(1).lowercased()
        let remainingLetters = result.dropFirst()
        result = firstLetter + remainingLetters

        // TODO: uppercase remaining words, e.g. "an example" to "anExample"; currently it's "anexample"
        // TODO: lowercase capitalized words, e.g. "EXAMPLE" to "example"; currently it's "eXAMPLE"

        return result


        // Generated from: 
        // in swift, write a function to convert a string into a variable name, which means it starts with a lowercase letter, and contains only letters and numbers
        /*
        let regex = try! NSRegularExpression(pattern: "^[a-z][a-zA-Z0-9]*$", options: [])
        let range = NSRange(location: 0, length: str.utf16.count)
        if regex.firstMatch(in: str, options: [], range: range) != nil {
            return str
        }
        return nil
        */
    }
}

SringCatalogEnum.main()