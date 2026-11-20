import Foundation
import Testing

@testable import LimitsCore

@Suite("Provider branding (FR-005, IV.2)")
@MainActor
struct ProviderBrandingTests {
    @Test func claudeHasOrangeSVGLogo() {
        let branding = ClaudeCodeProvider.branding
        #expect(branding.logoSVG.hasPrefix("<svg"))
        #expect(branding.logoSVG.contains("<path"))
        #expect(branding.tintRGB == 0xD97757)
    }

    @Test func codexHasMonochromeSVGLogo() {
        let branding = CodexProvider.branding
        #expect(branding.logoSVG.hasPrefix("<svg"))
        #expect(branding.logoSVG.contains("<path"))
        #expect(branding.tintRGB == nil)  // цвет текста (адаптируется к теме)
    }

    @Test func antigravityHasSVGLogo() {
        let branding = AntigravityProvider.branding
        #expect(branding.logoSVG.hasPrefix("<svg"))
        #expect(branding.logoSVG.contains("<path"))
        #expect(branding.tintRGB == 0x4285F4)
    }

    @Test func storeExposesBrandingByProviderID() {
        let store = LimitsStore(providers: [
            FakeProvider(id: "a"),
            CodexProvider(codexHome: FileManager.default.temporaryDirectory),
        ])
        #expect(store.branding(for: "codex")?.logoSVG == CodexProvider.branding.logoSVG)
        #expect(store.branding(for: "a") == nil)  // провайдер без логотипа
        #expect(store.branding(for: "missing") == nil)
    }
}
