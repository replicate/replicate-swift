import Foundation

import ArgumentParser
import AnyCodable
import Replicate
import OpenAPIKit
import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftFormat
import SwiftFormatConfiguration

@main
struct GenerateModelCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "generate-replicate-model")
    
    @Argument(help: "The model id.")
    var modelID: Model.ID

    @Argument(help: "The model version id.")
    var versionID: Model.Version.ID?

    @Option(name: .customLong("name"),
            help: """
                  The name of the generated model type.
                  If unspecified, a normalized form of the model name is used.
                  """)
    var modelTypeName: String?

    mutating func run() async throws {
        guard let token = ProcessInfo.processInfo.environment["REPLICATE_API_TOKEN"],
              !token.isEmpty
        else {
            fatalError("missing environment variable REPLICATE_API_TOKEN")
        }

        let client = Client(token: token)

        let model = try await client.getModel(modelID)
        let version: Model.Version
        if let versionID {
            version = try await client.getModelVersion(modelID, version: versionID)
        } else {
            guard let latestVersion = model.latestVersion else {
                fatalError("no latest version for model")
            }

            version = latestVersion
        }

        let document = try OpenAPI.document(for: version)

        let modelTypeName = self.modelTypeName ?? camelcase(model.name, uppercasingFirstLetter: true)

        let source = SourceFile {
            // import Foundation
            ImportDecl(path: "Foundation")

            // import AnyCodable
            ImportDecl(path: "AnyCodable")

            // Import Replicate
            ImportDecl(path: "Replicate")

            // public enum <ModelName>: Predictable
            EnumDecl(enumKeyword: .enum,
                     identifier: modelTypeName,
                     inheritanceClause: TypeInheritanceClause {
                InheritedType(typeName: "Predictable")
            },
                modifiersBuilder: {
                   TokenSyntax.public
                       .withLeadingTrivia(model.description.flatMap({ description in
                           .docLineComment("/// \(description)")}) ?? .zero)
                },
                membersBuilder: {

                // static let modelID = "<modelID>"
                VariableDecl(letOrVarKeyword: .let,
                             modifiersBuilder: {
                    TokenSyntax.public
                        .withLeadingTrivia(
                            .newlines(1) +
                            .docLineComment("/// The model ID.")
                        )
                    TokenSyntax.static
                },
                             bindingsBuilder: {
                    PatternBinding(pattern: "modelID",
                                   initializer: InitializerClause(value: StringLiteralExpr(model.id)))
                })

                // static let modelID = "<modelID>"
                VariableDecl(letOrVarKeyword: .let,
                             modifiersBuilder: {
                    TokenSyntax.public
                        .withLeadingTrivia(
                            .newlines(1) +
                            .docLineComment("/// The model version ID.")
                        )
                    TokenSyntax.static
                },
                             bindingsBuilder: {
                    PatternBinding(pattern: "versionID",
                                   initializer: InitializerClause(value: StringLiteralExpr(version.id)))
                })

                for component in (["Input", "Output"] as [OpenAPI.ComponentKey]) {
                    if let context = document.components.schemas[component]?.objectContext,
                       let properties = context.orderedProperties
                    {
                        // public struct <Input|Output>: Codable
                        StructDecl(
                            structKeyword: .struct,
                            identifier: component.rawValue,
                            inheritanceClause: TypeInheritanceClause {
                                InheritedType(typeName: "Codable")
                            },
                            modifiersBuilder: {
                                TokenSyntax.public
                                    .withLeadingTrivia(
                                        .newlines(1) +
                                        .docLineComment("/// The model \(component.rawValue.lowercased()).")
                                    )
                            },
                            membersBuilder: {
                                for case let (offset, (name, schema)) in properties.enumerated() {
                                    // public var <property>: <Type>
                                    VariableDecl(letOrVarKeyword: .var,
                                                 modifiersBuilder: {
                                        TokenSyntax.public
                                            .withLeadingTrivia(
                                                (offset == 0 ? .zero : .newlines(1)) +
                                                schema.swiftDocumentation
                                            )
                                    },
                                                 bindingsBuilder: {
                                        PatternBinding(pattern: camelcase(name, uppercasingFirstLetter: false),
                                                       typeAnnotation: schema.swiftTypeName)
                                    })
                                }

                                // public init(...)
                                InitializerDecl(
                                    initKeyword: .`init`,
                                    parameters: ParameterClause(parameterListBuilder: {
                                        for case let (n, (name, schema)) in zip(1..., properties) {
                                            FunctionParameter(
                                                firstName: .identifier(camelcase(name, uppercasingFirstLetter: false))
                                                    .withLeadingTrivia(.newlines(1)),
                                                colon: .colon,
                                                type: schema.swiftTypeName,
                                                defaultArgument: schema.swiftInitializerClause,
                                                trailingComma: (n == properties.count) ? nil : .comma,
                                                attributesBuilder: { })
                                        }
                                    }),
                                    body: CodeBlock(leftBrace: .leftBrace, rightBrace: .rightBrace, statementsBuilder: {
                                        for (name, _) in properties {
                                            CodeBlockItem(item:
                                                            SequenceExpr(elementsBuilder: {
                                                MemberAccessExpr(base: IdentifierExpr("self"),
                                                                 dot: .period,
                                                                 name: .identifier(camelcase(name, uppercasingFirstLetter: false))
                                                )
                                                AssignmentExpr(assignToken: .equal)
                                                IdentifierExpr(camelcase(name, uppercasingFirstLetter: false))
                                            })
                                            )
                                        }
                                    }),
                                    modifiersBuilder: {
                                        TokenSyntax.public
                                            .withLeadingTrivia(
                                                .newlines(1) +
                                                .docLineComment("/// Creates a new \(component.rawValue).") +
                                                swiftDocumentationForParameters(properties)
                                            )
                                    })

                                // private enum CodingKeys: String, CodingKey
                                EnumDecl(
                                    enumKeyword: .enum,
                                    identifier: "CodingKeys",
                                    inheritanceClause: TypeInheritanceClause {
                                        InheritedType(typeName: "String", trailingComma: .comma)
                                        InheritedType(typeName: "CodingKey")
                                    },
                                    modifiersBuilder: {
                                        TokenSyntax.private
                                            .withLeadingTrivia(.newlines(1))
                                    },
                                    membersBuilder: {
                                        for (name, _) in properties {
                                            EnumCaseDecl(elementsBuilder: {
                                                EnumCaseElement(
                                                    identifier: camelcase(name, uppercasingFirstLetter: false),
                                                    rawValue: InitializerClause(equal: .equal, value: StringLiteralExpr(name)))
                                            })
                                        }
                                    })
                            })
                    } else if let context = document.components.schemas[component]?.arrayContext {
                        // public typealias <Input|Output> = [<Type>]
                        TypealiasDecl(typealiasKeyword: .typealias,
                                      identifier: component.rawValue,
                                      initializer: TypeInitializerClause(equal: .equal,
                                                                         value: SimpleTypeIdentifier("[\(context.items?.swiftTypeName ?? "\(AnyCodable.self)")]")),
                                      modifiersBuilder: {
                            TokenSyntax.public
                                .withLeadingTrivia(
                                    .newlines(1) +
                                    .docLineComment("/// The model \(component.rawValue.lowercased()).")
                                )
                        })
                    } else {
                        // public typealias <Input|Output> = AnyCodable
                        TypealiasDecl(typealiasKeyword: .typealias,
                                      identifier: component.rawValue,
                                      initializer: TypeInitializerClause(equal: .equal,
                                                                         value: SimpleTypeIdentifier("\(AnyCodable.self)")),
                                      modifiersBuilder: {
                            TokenSyntax.public
                                .withLeadingTrivia(
                                    .newlines(1) +
                                    .docLineComment("/// The model \(component.rawValue.lowercased()).")
                                )
                        })
                    }
                }
            })
        }

        let format = Format(indentWidth: 4)
        let syntax = source.buildSyntax(format: format)

        var configuration = Configuration()
        configuration.indentation = .spaces(4)
        configuration.lineBreakAroundMultilineExpressionChainComponents = true
        let formatter = SwiftFormatter(configuration: configuration)

        var standardOutput = FileHandle.standardOutput
        try formatter.format(syntax: .init(syntax)!, assumingFileURL: nil, to: &standardOutput)
    }
}

// MARK: -

private func camelcase(_ string: String, uppercasingFirstLetter: Bool = true) -> String {
    return string.replacingOccurrences(of: "-", with: "_")
                 .split(separator: "_", omittingEmptySubsequences: true)
                 .enumerated()
                 .map { (offset, substring) in
                     if !uppercasingFirstLetter, offset == 0 {
                         return "\(substring)"
                     } else {
                         return "\(substring)".capitalized
                     }
                 }.joined(separator: "")
}


private func swiftDocumentationForParameters(_ properties: OrderedDictionary<String, JSONSchema>) -> Trivia {
    guard !properties.isEmpty else { return .zero }

    var trivia: Trivia = .newlines(1) + .docLineComment("/// - Parameters:")

    for (name, schema) in properties {
        trivia = trivia + .docLineComment("/// - \(camelcase(name, uppercasingFirstLetter: false)): \(schema.description ?? "")")
    }

    return trivia
}

private extension OpenAPI {
    static func document(for version: Replicate.Model.Version) throws -> ResolvedDocument {
        let encoder = JSONEncoder()
        let data = try encoder.encode(version.openAPISchema)

        let decoder = JSONDecoder()
        let document = try decoder.decode(Document.self, from: data)

        return try document.locallyDereferenced().resolved()
    }
}

private extension JSONSchema {
    var swiftDocumentation: Trivia {
        var lines: [String] = []

        if let description {
            lines.append(description)
        }

        if let allowedValues {
            lines.append("Allowed Values:\n" + allowedValues.description.map { "- \($0)" }.joined(separator: "\n"))
        }

        // BUG: SwiftSyntax overwrites the first 4 characters of a doc line
        return lines.map { Trivia.docLineComment("/// \($0)") }
                    .joined(separator: Trivia.docLineComment("/// "))
                    .map { Trivia(pieces: [$0]) }
                    .reduce(.zero, +)
    }

    var swiftInitializerClause: InitializerClause? {
        let literalExpr: ExprBuildable
        switch defaultValue?.value {
        case let value as Bool:
            literalExpr = BooleanLiteralExpr(value)
        case let value as any BinaryInteger:
            literalExpr = IntegerLiteralExpr(Int(value))
        case let value as Float:
            literalExpr = FloatLiteralExpr(value)
        case let value as Double:
            literalExpr = FloatLiteralExpr(floatingDigits: String(describing: value))
        case let value as String:
            literalExpr = StringLiteralExpr(value)
        default:
            literalExpr = NilLiteralExpr()
        }

        return InitializerClause(equal: .equal, value: literalExpr)
    }

    var swiftTypeName: String {
        func swiftTypeName(type: JSONType?, format: JSONTypeFormat?) -> String {
            switch jsonType {
            case .boolean:
                return "\(Bool.self)"
            case .number where format == .number(.float):
                return "\(Float.self)"
            case .number:
                return "\(Double.self)"
            case .integer:
                return "\(Int.self)"
            case .string where format == .string(.binary),
                 .string where format == .string(.byte):
                return "\(Data.self))"
            case .string where format == .string(.date),
                 .string where format == .string(.dateTime):
                return "\(Date.self)"
            case .string where format == .string(.extended(.uri)):
                return "\(URL.self)"
            case .string where format == .string(.extended(.uuid)):
                return "\(UUID.self)"
            case .string:
                return "\(String.self)"
            case .array:
                return "[\(swiftTypeName(type: arrayContext?.items?.jsonType, format: arrayContext?.items?.jsonTypeFormat))]"
            default:
                return "\(AnyCodable.self)"
            }
        }

        var typeName = swiftTypeName(type: jsonType, format: jsonTypeFormat)

        if !required {
            typeName.append("?")
        }

        return typeName
    }
}
