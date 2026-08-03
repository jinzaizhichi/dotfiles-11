(() => {
    'use strict';

    const order = [
        ['Jitendex', /^Jitendex\.org(?: \[[^\]]+\])?$/],
        ['新和英', /^新和英$/],
        ['旺文社国語辞典 第十一版', /^旺文社国語辞典 第十一版(?: 画像無し)?$/],
        ['Dictionary of Japanese Grammar', /^日本語文法辞典\(全集\)$/],
        ['JPDB frequency', /^JPDBv2㋕$/],
        ['CC100 frequency', /^CC100$/],
        ['KANJIDIC', /^KANJIDIC(?: \[[^\]]+\])?$/],
        ['NHK2016 pitch accent', /^NHK$/],
    ];

    function sortDictionaries(dictionaries) {
        const remaining = [...dictionaries];
        const ordered = [];
        const missing = [];

        for (const [label, pattern] of order) {
            const matches = remaining.filter(({name}) => pattern.test(name));
            if (matches.length > 1) {
                throw new Error(`${label} matches multiple installed dictionaries`);
            }
            if (matches.length === 0) {
                missing.push(label);
                continue;
            }

            const [match] = matches;
            ordered.push(match);
            remaining.splice(remaining.indexOf(match), 1);
        }

        const sorted = [...ordered, ...remaining].map((dictionary, index, dictionaries2) => ({
            ...dictionary,
            priority: (dictionaries2.length - index) * 10,
        }));
        if (sorted.length !== dictionaries.length) {
            throw new Error('Dictionary count changed; refusing to save');
        }

        return {
            dictionaries: sorted,
            missing,
            unknown: remaining.map(({name}) => name),
        };
    }

    async function run() {
        const [{Application}, {SettingsController}] = await Promise.all([
            import('./js/application.js'),
            import('./js/pages/settings/settings-controller.js'),
        ]);

        await Application.main(true, async (application) => {
            const controller = new SettingsController(application);
            const {profileCurrent} = await controller.getOptionsFull();
            controller.profileIndex = profileCurrent;

            const current = await controller.getOptions();
            const result = sortDictionaries(current.dictionaries);
            await controller.modifyProfileSettings([{
                action: 'set',
                path: 'dictionaries',
                value: result.dictionaries,
            }]);

            if (result.missing.length > 0) {
                console.warn('Missing dictionaries:', result.missing);
            }
            if (result.unknown.length > 0) {
                console.warn('Unknown dictionaries left at the end:', result.unknown);
            }
            console.table(result.dictionaries.map(({name, priority, enabled}) => ({name, priority, enabled})));
            console.info(`Sorted active Yomitan profile ${profileCurrent}.`);
        });
    }

    if (typeof module !== 'undefined') {
        module.exports = {sortDictionaries};
    }
    if (typeof window !== 'undefined') {
        void run().catch(console.error);
    }
})();
