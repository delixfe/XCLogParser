//
//  SonarIssuesReporter.swift
//  XCLogParser
//
//  Created by Felix Deierlein on 29.01.21.
//

import Foundation

//# https://github.com/SonarSource/sonarqube/blob/9c4f81390e6739fa09f596d359d66c181db9ad1c/sonar-scanner-engine/src/main/java/org/sonar/scanner/externalissue/ReportParser.java
//#  private Report validate(Report report) {
//#     for (Issue issue : report.issues) {
//#       mandatoryField(issue.primaryLocation, "primaryLocation");
//#       mandatoryField(issue.engineId, "engineId");
//#       mandatoryField(issue.ruleId, "ruleId");
//#       mandatoryField(issue.severity, "severity");
//#       mandatoryField(issue.type, "type");
//#       mandatoryField(issue.primaryLocation, "primaryLocation");
//#       mandatoryFieldPrimaryLocation(issue.primaryLocation.filePath, "filePath");
//#       mandatoryFieldPrimaryLocation(issue.primaryLocation.message, "message");
//#
//#       if (issue.primaryLocation.textRange != null) {
//#         mandatoryFieldPrimaryLocation(issue.primaryLocation.textRange.startLine, "startLine of the text range");
//#       }
//#
//#       if (issue.secondaryLocations != null) {
//#         for (Location l : issue.secondaryLocations) {
//#           mandatoryFieldSecondaryLocation(l.filePath, "filePath");
//#           mandatoryFieldSecondaryLocation(l.textRange, "textRange");
//#           mandatoryFieldSecondaryLocation(l.textRange.startLine, "startLine of the text range");
//#         }
//#       }
//#     }
//#
//#     return report;
//#   }

struct SonarIssues: Codable {
    let issues: [SonarIssue]
}

struct SonarIssue: Codable {
    let engineId: String
    let ruleId: String
    let severity: String
    let type: String
    
    init(from notice: Notice) {
        engineId = "swiftCompiler"
        ruleId = "rule1"
        severity = "CRITICAL"
        type = "BUG"
    }
}

public struct SonarIssuesReporter: LogReporter {

    public func report(build: Any, output: ReporterOutput, rootOutput: String) throws {
        guard let steps = build as? BuildStep else {
            throw XCLogParserError.errorCreatingReport("Type not supported \(type(of: build))")
        }
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let json = try encoder.encode(getIssues(from: steps))
        try output.write(report: json)
    }

}

private func getIssues(from step: BuildStep) -> SonarIssues {
    let warnings = getIssues(from: step, keyPath: \.warnings)
//    let errors = getIssues(from: step, keyPath: \.errors)
    let issues = warnings.map {
        return SonarIssue(from: $0)
    }
    
    return SonarIssues(issues: issues)
}

private func getIssues(from step: BuildStep, keyPath: KeyPath<BuildStep, [Notice]?>) -> [Notice] {
    return (step[keyPath: keyPath] ?? [])
        + step.subSteps.flatMap { getIssues(from: $0, keyPath: keyPath )}
}
