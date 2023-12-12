module.exports = {
    lastSync: {
        ref: "4f26a6bc28032c068b4db7207ef077aec7c89902",
        conversionToolVersion: "ef4bcc5c0d0fc3c5ca56cc84212d267b598f9de6"
    },
    upstream: {
        owner: "graphql",
        repo: "graphql-js",
        primaryBranch: "main"
    },
    downstream: {
        owner: "roblox",
        repo: "graphql-lua-internal",
        primaryBranch: "master",
        patterns: [
            "src/**/*.lua"
        ]
    },
    releasePattern: /^v?\d+\.\d+\.\d+$/,
    renameFiles: [
        [
            (filename) => filename.endsWith(".test.lua"),
            (filename) => filename.replace(".test.lua", ".spec.lua")

        ],
        [
            (filename) => filename.endsWith('index.lua'),
            (filename) => filename.replace("index.lua", "init.lua")
        ],
        [
            (filename) => filename.endsWith("-test.lua"),
            (filename) => filename.replace("-test.lua", ".spec.lua")
        ],
        [
            (filename) => filename.endsWith(".test.ts.lua"),
            (filename) => filename.replace(".test.ts.lua", ".spec.snap.lua")
        ],
        [
            (filename) => filename.endsWith(".ts.lua") && !filename.endsWith(".test.ts.lua"),
            (filename) => filename.replace(".ts.lua", ".spec.snap.lua")
        ],
        [
            (filename) => filename.endsWith(".snap.lua") && !filename.endsWith(".spec.snap.lua"),
            (filename) => filename.replace(".snap.lua", ".spec.snap.lua")
        ],
        // specific fixes
        [
            (filename) => filename.includes('src/language/__tests__/blockString-fuzz.lua'),
            () => 'src/language/__tests__/blockString-fuzz.spec.lua'
        ],
        [
            (filename) => filename.includes('src/utilities/__tests__/stripIgnoredCharacters-fuzz.lua'),
            () => 'src/utilities/__tests__/stripIgnoredCharacters-fuzz.spec.lua'
        ],
    ]
}
