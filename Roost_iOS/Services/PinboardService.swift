import Foundation
import Supabase

struct PinboardService {
    func fetchNotes(for homeID: UUID) async throws -> [PinboardNote] {
        let client = try SupabaseClientProvider.shared.requireClient()
        return try await client
            .from("pinboard_notes")
            .select("*, pinboard_note_acknowledgements(*)")
            .eq("home_id", value: homeID)
            .order("created_at", ascending: false)
            .execute()
            .value
    }

    func createNote(_ note: CreatePinboardNote) async throws -> PinboardNote {
        let client = try SupabaseClientProvider.shared.requireClient()
        return try await client
            .from("pinboard_notes")
            .insert(note)
            .select("*, pinboard_note_acknowledgements(*)")
            .single()
            .execute()
            .value
    }

    func deleteNote(id: UUID) async throws {
        let client = try SupabaseClientProvider.shared.requireClient()
        try await client
            .from("pinboard_notes")
            .delete()
            .eq("id", value: id)
            .execute()
    }

    func acknowledge(noteID: UUID, userID: UUID) async throws {
        let client = try SupabaseClientProvider.shared.requireClient()
        let payload = PinboardAcknowledgementUpsert(noteID: noteID, userID: userID, seenAt: .now)
        try await client
            .from("pinboard_note_acknowledgements")
            .upsert(payload, onConflict: "note_id,user_id")
            .execute()
    }
}
