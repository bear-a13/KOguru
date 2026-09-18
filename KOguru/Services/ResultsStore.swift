//
//  ResultsStore.swift
//  KOguru
//
//  Created by Ulisses Bonfim on 09/09/26.
//

import Foundation
import Combine

final class ResultsStore: ObservableObject {
    @Published private(set) var sessions: [ResultsModel] = []
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
            fileURL = directory.appendingPathComponent("workout-results.json")
        } catch {
            // Fallback válido para o sandbox do aplicativo.
            fileURL = fileManager.temporaryDirectory
                .appendingPathComponent("workout-results.json")
            lastErrorMessage = "Não foi possível abrir a pasta de dados: \(error.localizedDescription)"
        }

        load()
    }

    func add(_ result: ResultsModel) {
        sessions.insert(result, at: 0)
        save()
    }

    func delete(_ result: ResultsModel) {
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
            sessions = try decoder.decode([ResultsModel].self, from: data)
            lastErrorMessage = nil
        } catch {
            sessions = []
            lastErrorMessage = "Não foi possível carregar os treinos: \(error.localizedDescription)"
        }
    }

    private func save() {
        do {
            let data = try encoder.encode(sessions)
            try data.write(to: fileURL, options: .atomic)
            lastErrorMessage = nil
        } catch {
            lastErrorMessage = "Não foi possível salvar o treino: \(error.localizedDescription)"
        }
    }
}
