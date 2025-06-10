import ArgumentParser
import Demark
import Foundation

@main
struct DemarkCLI: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "demark",
        abstract: "Convert HTML to Markdown",
        discussion: """
        A command-line tool for converting HTML content to Markdown format.
        
        Supports two conversion engines:
        - turndown (default): Full DOM parsing with better fidelity
        - html-to-md: Faster lightweight conversion
        """,
        version: "1.0.0"
    )
    
    @Argument(help: "HTML input file path or '-' for stdin")
    var input: String
    
    @Option(name: .shortAndLong, help: "Output file path (default: stdout)")
    var output: String?
    
    @Option(name: .shortAndLong, help: "Conversion engine: turndown (default) or html-to-md")
    var engine: EngineType = .turndown
    
    @Option(name: .shortAndLong, help: "Heading style: setext or atx (default)")
    var headingStyle: HeadingStyleType = .atx
    
    @Option(name: .shortAndLong, help: "Bullet list marker: -, *, or + (default: -)")
    var bulletListMarker: String = "-"
    
    @Option(name: .shortAndLong, help: "Code block style: indented or fenced (default)")
    var codeBlockStyle: CodeBlockStyleType = .fenced
    
    @Flag(name: .shortAndLong, help: "Enable verbose output")
    var verbose = false
    
    enum EngineType: String, ExpressibleByArgument, CaseIterable {
        case turndown
        case htmlToMd = "html-to-md"
        
        var conversionEngine: ConversionEngine {
            switch self {
            case .turndown:
                return .turndown
            case .htmlToMd:
                return .htmlToMd
            }
        }
    }
    
    enum HeadingStyleType: String, ExpressibleByArgument, CaseIterable {
        case setext
        case atx
        
        var demarkStyle: DemarkHeadingStyle {
            switch self {
            case .setext:
                return .setext
            case .atx:
                return .atx
            }
        }
    }
    
    enum CodeBlockStyleType: String, ExpressibleByArgument, CaseIterable {
        case indented
        case fenced
        
        var demarkStyle: DemarkCodeBlockStyle {
            switch self {
            case .indented:
                return .indented
            case .fenced:
                return .fenced
            }
        }
    }
    
    mutating func run() async throws {
        let htmlContent: String
        
        if input == "-" {
            if verbose {
                FileHandle.standardError.write(Data("Reading from stdin...\n".utf8))
            }
            htmlContent = try readFromStdin()
        } else {
            if verbose {
                FileHandle.standardError.write(Data("Reading from file: \(input)\n".utf8))
            }
            let url = URL(fileURLWithPath: input)
            htmlContent = try String(contentsOf: url, encoding: .utf8)
        }
        
        let options = DemarkOptions(
            engine: engine.conversionEngine,
            headingStyle: headingStyle.demarkStyle,
            bulletListMarker: bulletListMarker,
            codeBlockStyle: codeBlockStyle.demarkStyle
        )
        
        if verbose {
            FileHandle.standardError.write(Data("Using engine: \(engine.rawValue)\n".utf8))
            FileHandle.standardError.write(Data("Converting HTML to Markdown...\n".utf8))
        }
        
        let demark = await Demark()
        let markdown = try await demark.convertToMarkdown(htmlContent, options: options)
        
        if let outputPath = output {
            if verbose {
                FileHandle.standardError.write(Data("Writing to file: \(outputPath)\n".utf8))
            }
            let outputURL = URL(fileURLWithPath: outputPath)
            try markdown.write(to: outputURL, atomically: true, encoding: String.Encoding.utf8)
        } else {
            print(markdown)
        }
        
        if verbose {
            FileHandle.standardError.write(Data("Conversion complete!\n".utf8))
        }
    }
    
    private func readFromStdin() throws -> String {
        let data = FileHandle.standardInput.readDataToEndOfFile()
        guard let content = String(data: data, encoding: .utf8) else {
            throw ValidationError("Failed to read valid UTF-8 data from stdin")
        }
        return content
    }
}