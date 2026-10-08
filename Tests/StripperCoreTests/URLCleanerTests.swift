import Testing
@testable import StripperCore

struct URLCleanerTests {
    let cleaner = URLCleaner()

    @Test func stripsUTMAndKeepsRealParameters() {
        let r = cleaner.clean("https://example.com/article?id=42&utm_source=news&utm_medium=email&page=2")
        #expect(r?.cleaned == "https://example.com/article?id=42&page=2")
        #expect(r?.removedParameters == ["utm_source", "utm_medium"])
    }

    @Test func dropsQuestionMarkWhenAllParamsRemoved() {
        let r = cleaner.clean("https://example.com/a?fbclid=abc123&gclid=xyz")
        #expect(r?.cleaned == "https://example.com/a")
    }

    @Test func preservesFragmentPortAndPercentEncoding() {
        let r = cleaner.clean("https://example.com:8443/p%20q?q=a%26b&utm_campaign=x#section-2")
        #expect(r?.cleaned == "https://example.com:8443/p%20q?q=a%26b#section-2")
    }

    @Test func caseInsensitiveNames() {
        #expect(cleaner.clean("https://example.com/?UTM_Source=x&FBCLID=y&a=1")?.cleaned == "https://example.com/?a=1")
    }

    @Test func trimsSurroundingWhitespace() {
        #expect(cleaner.clean("  https://example.com/?gclid=1\n")?.cleaned == "https://example.com/")
    }

    @Test func hostSpecificRules() {
        #expect(cleaner.clean("https://youtu.be/dQw4w9WgXcQ?si=abcDEF")?.cleaned == "https://youtu.be/dQw4w9WgXcQ")
        #expect(cleaner.clean("https://www.youtube.com/watch?v=dQw4w9WgXcQ&si=abc")?.cleaned
                == "https://www.youtube.com/watch?v=dQw4w9WgXcQ")
        // `si` is only a tracker on specific hosts.
        #expect(cleaner.clean("https://example.com/?si=keep") == nil)
        #expect(cleaner.clean("https://www.amazon.com/dp/B00X?pd_rd_w=1&pf_rd_p=2&tag=aff-20")?.cleaned
                == "https://www.amazon.com/dp/B00X")
    }

    @Test(arguments: TrackingRules.amazonDomains)
    func allAmazonStorefronts(_ domain: String) {
        #expect(cleaner.clean("https://www.\(domain)/dp/B00X?pd_rd_w=1&tag=aff-21&th=1")?.cleaned
                == "https://www.\(domain)/dp/B00X?th=1")
    }

    @Test func returnsNilWhenNothingToStrip() {
        #expect(cleaner.clean("https://example.com/search?q=swift") == nil)
        #expect(cleaner.clean("https://example.com/") == nil)
    }

    @Test(arguments: [
        "not a url",
        "example.com/?utm_source=x",                       // no scheme
        "ftp://example.com/?utm_source=x",                 // not http(s)
        "mailto:a@example.com?utm_source=x",
        "javascript:alert(1)//?utm_source=x",
        "file:///etc/hosts?utm_source=x",
        "https://?utm_source=x",                           // no host
        "https://exa mple.com/?utm_source=x",              // whitespace
        "Check this out https://example.com/?utm_source=x", // prose containing a link
        "https://-bad-.com/?utm_source=x",                 // invalid label
        "https://nodot/?utm_source=x",                     // single-label host
        "",
    ])
    func rejectsInvalidInput(_ input: String) {
        #expect(cleaner.clean(input) == nil)
    }

    @Test func acceptsLocalhostAndIPs() {
        #expect(cleaner.clean("http://localhost:3000/?utm_source=x")?.cleaned == "http://localhost:3000/")
        #expect(cleaner.clean("http://192.168.1.1/?utm_source=x")?.cleaned == "http://192.168.1.1/")
        #expect(cleaner.clean("http://[::1]:8080/?utm_source=x")?.cleaned == "http://[::1]:8080/")
    }
}
