import Foundation

/// Which query parameters count as identifying/tracking parameters.
public struct TrackingRules: Sendable {
    /// Parameter names stripped on every host (compared case-insensitively).
    public var globalNames: Set<String>
    /// Parameter-name prefixes stripped on every host (e.g. `utm_`).
    public var globalPrefixes: [String]
    /// Extra names stripped only on matching hosts. Keys are registrable
    /// domains; a rule for `amazon.com` also applies to `www.amazon.com`.
    public var hostNames: [String: Set<String>]
    /// Extra prefixes stripped only on matching hosts.
    public var hostPrefixes: [String: [String]]

    public init(
        globalNames: Set<String>,
        globalPrefixes: [String],
        hostNames: [String: Set<String>] = [:],
        hostPrefixes: [String: [String]] = [:]
    ) {
        self.globalNames = Set(globalNames.map { $0.lowercased() })
        self.globalPrefixes = globalPrefixes.map { $0.lowercased() }
        self.hostNames = hostNames.mapValues { Set($0.map { $0.lowercased() }) }
        self.hostPrefixes = hostPrefixes.mapValues { $0.map { $0.lowercased() } }
    }

    public func shouldStrip(parameter: String, host: String) -> Bool {
        let name = parameter.lowercased()
        if globalNames.contains(name) { return true }
        if globalPrefixes.contains(where: name.hasPrefix) { return true }
        for (domain, names) in hostNames where Self.host(host, matches: domain) {
            if names.contains(name) { return true }
        }
        for (domain, prefixes) in hostPrefixes where Self.host(host, matches: domain) {
            if prefixes.contains(where: name.hasPrefix) { return true }
        }
        return false
    }

    static func host(_ host: String, matches domain: String) -> Bool {
        host == domain || host.hasSuffix("." + domain)
    }

    public static let `default` = TrackingRules(
        globalNames: [
            // Google / Google Ads
            "gclid", "gclsrc", "dclid", "gbraid", "wbraid", "_ga", "_gl",
            // Meta / Instagram
            "fbclid", "igshid", "igsh",
            // Microsoft / Bing
            "msclkid",
            // TikTok, Twitter/X, LinkedIn, Yandex, Reddit
            "ttclid", "twclid", "li_fat_id", "yclid", "rdt_cid",
            // Mailchimp
            "mc_cid", "mc_eid",
            // HubSpot
            "_hsenc", "_hsmi", "__hssc", "__hstc", "__hsfp", "hsctatracking",
            // Marketo
            "mkt_tok",
            // Adobe / Omniture
            "s_cid", "s_kwcid", "ef_id",
            // Misc. email / analytics platforms
            "vero_id", "vero_conv", "oly_anon_id", "oly_enc_id", "_openstat",
            "wickedid", "rb_clickid", "irclickid", "ncid", "sr_share",
            "_branch_match_id", "_bta_tid", "_bta_c", "trk_contact", "trk_msg",
            "trk_module", "trk_sid", "ml_subscriber", "ml_subscriber_hash",
            "spm", "scm", "cvid", "oicd", "zanpid", "epik",
        ],
        globalPrefixes: [
            "utm_", "pk_", "piwik_", "mtm_", "matomo_", "stm_", "hsa_",
        ],
        hostNames: [
            "youtube.com": ["si", "feature", "pp"],
            "youtu.be": ["si", "feature"],
            "spotify.com": ["si", "context", "nd"],
            "twitter.com": ["s", "t", "ref_src", "ref_url"],
            "x.com": ["s", "t", "ref_src", "ref_url"],
            "linkedin.com": ["trk", "trkinfo", "trackingid", "refid", "lipi", "midtoken", "midsig", "trkemail", "eid", "otptoken"],
            "facebook.com": ["mibextid", "rdid", "share_url", "__tn__", "__cft__", "eav", "paipv", "sfnsn", "extid", "acontext"],
            "instagram.com": ["img_index", "utm_source"],
            "tiktok.com": ["_t", "_r", "is_from_webapp", "sender_device", "sender_web_id", "share_app_id", "share_item_id", "share_link_id", "social_sharing", "tt_from", "u_code", "user_id", "timestamp", "checksum", "sec_uid", "web_id"],
            "reddit.com": ["share_id", "rdt", "correlation_id", "ref", "ref_source", "ref_campaign"],
            "medium.com": ["source", "sk"],
            "google.com": ["ved", "ei", "sei", "sxsrf", "gs_lcp", "gs_lp", "gs_ssp", "gs_lcrp", "oq", "aqs", "sclient", "uact", "bih", "biw", "sourceid", "ie", "rlz", "client", "sca_esv", "sca_upv", "iflsig", "dpr"],
            "bing.com": ["form", "sp", "qs", "pq", "sc", "sk", "cvid", "ghsh", "ghacc", "ghpl"],
            "ebay.com": ["_trkparms", "_trksid", "amdata", "mkcid", "mkevt", "mkrid", "campid", "customid", "toolid", "hash"],
            "aliexpress.com": ["aff_platform", "aff_trace_key", "algo_expid", "algo_pvid", "btsid", "ws_ab_test", "pdp_npi", "sk", "pvid", "gatewayadapt"],
        ].merging(amazonDomains.map { ($0, amazonNames) }) { $1 },
        hostPrefixes: [
            "ebay.com": ["_trk"],
        ].merging(amazonDomains.map { ($0, amazonPrefixes) }) { $1 }
    )

    /// Every Amazon storefront; they all share the same tracking parameters.
    static let amazonDomains = [
        "amazon.com", "amazon.ca", "amazon.com.mx", "amazon.com.br",
        "amazon.co.uk", "amazon.ie", "amazon.de", "amazon.fr", "amazon.it",
        "amazon.es", "amazon.nl", "amazon.be", "amazon.com.be", "amazon.se",
        "amazon.pl", "amazon.com.tr", "amazon.ae", "amazon.sa", "amazon.eg",
        "amazon.in", "amazon.co.jp", "amazon.cn", "amazon.sg", "amazon.com.au",
        "amazon.co.za", "amazon.com.ng",
    ]
    static let amazonNames: Set<String> = [
        "ref", "ref_", "tag", "smid", "linkcode", "linkid", "camp", "creative",
        "creativeasin", "content-id", "dib", "dib_tag", "qid", "sr", "sprefix", "crid",
    ]
    static let amazonPrefixes = ["pd_rd_", "pf_rd_", "ref_"]
}
