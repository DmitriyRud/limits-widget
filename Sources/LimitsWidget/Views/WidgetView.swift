import LimitsCore
import SwiftUI

/// Compact desktop card showing all enabled providers.
struct WidgetView: View {
    let model: AppModel

    var body: some View {
        let store = model.store
        let lang = model.language
        VStack(alignment: .leading, spacing: 12) {
            if !model.hasEnabledProviders {
                Text(StatusText.noProvidersHint(language: lang))
                    .font(.callout).foregroundStyle(.secondary)
            } else if store.snapshots.isEmpty {
                Text(L10n.loading(lang)).font(.callout).foregroundStyle(.secondary)
            } else {
                ForEach(store.snapshots) { snapshot in
                    ProviderSection(
                        snapshot: snapshot, branding: store.branding(for: snapshot.providerID),
                        now: store.now,
                        isStale: store.staleProviderIDs.contains(snapshot.providerID),
                        language: lang)
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
    let language: AppLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                if let branding { ProviderLogo(branding: branding) }
                Text(snapshot.displayName).font(.headline)
            }
            if snapshot.status == .ok {
                ForEach(snapshot.windows, id: \.kind) { window in
                    WindowRow(window: window, now: now, language: language)
                }
                Text(footer)
                    .font(.caption2)
                    .foregroundStyle(isStale ? Color.orange : Color.secondary)
            } else {
                Text(StatusText.message(for: snapshot, language: language))
                    .font(.callout).foregroundStyle(.secondary)
            }
        }
    }

    private var footer: String {
        let base = ResetFormatter.dataAge(snapshot.fetchedAt, now: now, language: language)
        return isStale ? "\(base) · \(StatusText.staleMark(language: language))" : base
    }
}
