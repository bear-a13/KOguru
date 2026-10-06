//
//  DrillResultsStore.swift
//  KOguru
//
//  Created by Bernardo on 06/10/26.
//

import Foundation
import Combine

final class DrillResultsStore: ObservableObject {
    @Published private(set) var sessions: [DrillResultsModel] = []
    @Published private(set) var lastErrorMessage: String?

    private let fileURL: URL
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    init(fileManager: FileManager = .default) {
        encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        do {
            let applicationSupport = try fileManager.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
            let directory = applicationSupport.appendingPathComponent(
                "KOguru",
                isDirectory: true
            )
            try fileManager.createDirectory(
                at: directory,
                withIntermediateDirectories: true
            )
            fileURL = directory.appendingPathComponent("drill-results.json")
        } catch {
            // Fallback válido para o sandbox do aplicativo.
            fileURL = fileManager.temporaryDirectory
                .appendingPathComponent("drill-results.json")
            lastErrorMessage = "Não foi possível abrir a pasta de dados: \(error.localizedDescription)"
        }

        load()
    }

    func add(_ result: DrillResultsModel) {
        sessions.insert(result, at: 0)
        save()
    }

    func delete(_ result: DrillResultsModel) {
        sessions.removeAll { $0.id == result.id }
        save()
    }

    func deleteAll() {
        sessions.removeAll()
        save()
    }

    private func load() {
        guard FileManager.default.fileExists(atPath: fileURL.path) else { return }

        do {
            let data = try Data(contentsOf: fileURL)
            sessions = try decoder.decode([DrillResultsModel].self, from: data)
            lastErrorMessage = nil
        } catch {
            sessions = []
            lastErrorMessage = "Não foi possível carregar os drills: \(error.localizedDescription)"
        }
    }

    private func save() {
        do {
            let data = try encoder.encode(sessions)
            try data.write(to: fileURL, options: .atomic)
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = "Não foi possível salvar o drill: \(error.localizedDescription)"
        }
    }
}