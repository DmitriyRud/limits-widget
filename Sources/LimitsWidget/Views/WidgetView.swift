import LimitsCore
import SwiftUI

/// Компактная карточка со всеми провайдерами (FR-005, FR-008).
struct WidgetView: View {
    let model: AppModel

    var body: some View {
        let store = model.store
        VStack(alignment: .leading, spacing: 12) {
            if !model.hasEnabledProviders {
                Text(StatusText.noProvidersHint)
                    .font(.callout).foregroundStyle(.secondary)
            } else if store.snapshots.isEmpty {
                Text("Загрузка…").font(.callout).foregroundStyle(.secondary)
            } else {
                ForEach(store.snapshots) { snapshot in
                    ProviderSection(
                        snapshot: snapshot, branding: store.branding(for: snapshot.providerID),
                        now: store.now,
                        isStale: store.staleProviderIDs.contains(snapshot.providerID))
                }
            }
        }
        .padding(16)
        .frame(width: 260, alignment: .leading)
        .background(WidgetBackground())
    }
}

struct ProviderSection: View {
    let snapshot: ProviderSnapshot
    let branding: ProviderBranding?
    let now: Date
    let isStale: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if let branding { ProviderLogo(branding: branding) }
                Text(snapshot.displayName).font(.headline)
            }
            if snapshot.status == .ok {
                ForEach(snapshot.windows, id: \.kind) { window in
                    WindowRow(window: window, now: now)
                }
                Text(footer)
                    .font(.caption2)
                    .foregroundStyle(isStale ? Color.orange : Color.secondary)
            } else {
                Text(StatusText.message(for: snapshot))
                    .font(.callout).foregroundStyle(.secondary)
            }
        }
    }

    private var footer: String {
        let base = ResetFormatter.dataAge(snapshot.fetchedAt, now: now)
        return isStale ? "\(base) · \(StatusText.staleMark)" : base
    }
}
