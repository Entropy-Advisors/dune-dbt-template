{{
    config(
        alias = 'dim_dex_factory_addresses',
        materialized = 'view'
    )
}}

-- Single source of truth for all DEX factory contract addresses.
-- Agent jobs add rows directly (see jobs/refresh_*.md). For bulk imports from a spreadsheet, use scripts/sync_factory_addresses.py.
-- Columns: protocol, version, blockchain, contract_address, min_block_number

select *
from (
    values

        -- Uniswap V2
        ('uniswap', '2', 'ethereum', 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f, 10008355),
        ('uniswap', '2', 'arbitrum', 0xf1D7CC64Fb4452F05c498126312eBE29f30Fbcf9, 150778518),
        ('uniswap', '2', 'optimism', 0x0c3c1c532F1e39EdF36BE9Fe0bE1410313E074Bf, 116121726),
        ('uniswap', '2', 'polygon', 0x9e5A52f57b3038F1B8EeE45F28b3C1967e22799C, 53479266),
        ('uniswap', '2', 'avalanche_c', 0x9e5A52f57b3038F1B8EeE45F28b3C1967e22799C, 41630079),
        ('uniswap', '2', 'bnb', 0x8909Dc15e40173Ff4699343b6eB8132c65e18eC6, 36111192),
        ('uniswap', '2', 'base', 0x8909Dc15e40173Ff4699343b6eB8132c65e18eC6, 10526493),
        ('uniswap', '2', 'blast', 0x5C346464d33F90bABaf70dB6388507CC889C1070, 863023),
        ('uniswap', '2', 'zora', 0x0F797dC7efaEA995bB916f268D919d0a1950eE3C, 11227759),
        ('uniswap', '2', 'worldchain', 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f, 4630655),
        ('uniswap', '2', 'unichain', 0x1f98400000000000000000000000000000000002, 23487),
        ('uniswap', '2', 'monad', 0x182a927119d56008d921126764bf884221b10f59, 32036467),
        ('uniswap', '2', 'megaeth', 0xbf56488c857a881ae7e3bed27cf99c10a7ab7e50, 7916355),

        -- Uniswap V3
        ('uniswap', '3', 'ethereum', 0x1F98431c8aD98523631AE4a59f267346ea31F984, 12369739),
        ('uniswap', '3', 'arbitrum', 0x1F98431c8aD98523631AE4a59f267346ea31F984, 185),
        ('uniswap', '3', 'optimism', 0x1F98431c8aD98523631AE4a59f267346ea31F984, 191),
        ('uniswap', '3', 'polygon', 0x1F98431c8aD98523631AE4a59f267346ea31F984, 22757913),
        ('uniswap', '3', 'avalanche_c', 0x740b1c1de25031C31FF4fC9A62f554A55cdC1baD, 31588570),
        ('uniswap', '3', 'bnb', 0xdB1d10011AD0Ff90774D0C6Bb92e5C5c8b4461F7, 26340146),
        ('uniswap', '3', 'base', 0x33128a8fC17869897dcE68Ed026d694621f6FDfD, 2009446),
        ('uniswap', '3', 'blast', 0x792edAdE80af5fC680d96a2eD80A44247D2Cf6Fd, 430250),
        ('uniswap', '3', 'zora', 0x7145F8aeef1f6510E92164038E1B6F8cB2c42Cbb, 11013984),
        ('uniswap', '3', 'worldchain', 0x7a5028BDa40e7B173C278C5342087826455ea25a, 2754576),
        ('uniswap', '3', 'unichain', 0x1f98400000000000000000000000000000000003, 24339),
        ('uniswap', '3', 'celo', 0xAfE208a311B21f13EF87E33A90049fC17A7acDEc, 13924232),
        ('uniswap', '3', 'zksync', 0x8FdA5a7a8dCA67BBcDd10F02Fa0649A937215422, 12646554),
        ('uniswap', '3', 'monad', 0x204faca1764b154221e35c0d20abb3c525710498, 32036467),
        ('uniswap', '3', 'megaeth', 0x3a5f0cd7d62452b7f899b2a5758bfa57be0de478, 32036467),

        -- Uniswap V4
        -- PoolManager contracts (one per chain — V4 has no separate factory)
        
        ('uniswap', '4', 'ethereum',    0x000000000004444c5dc75cB358380D2e3dE08A90, 21688545),
        ('uniswap', '4', 'unichain',    0x1f98400000000000000000000000000000000004, 25565),
        ('uniswap', '4', 'optimism',    0x9a13f98cb987694c9f086b1f5eb990eea8264ec3, 130990676),
        ('uniswap', '4', 'base',        0x498581ff718922c3f8e6a244956af099b2652b2b, 25352561),
        ('uniswap', '4', 'arbitrum',    0x360e68faccca8ca495c1b759fd9eee466db9fb32, 298076243),
        ('uniswap', '4', 'polygon',     0x67366782805870060151383f4bbff9dab53e5cd6, 67012640),
        ('uniswap', '4', 'blast',       0x1631559198a9e474033433b2958dabc135ab6446, 14465585),
        ('uniswap', '4', 'zora',        0x0575338e4c17006ae181b47900a84404247ca30f, 25523641),
        ('uniswap', '4', 'worldchain',  0xb1860d529182ac3bc1f51fa2abd56662b7d13f33, 9125449),
        ('uniswap', '4', 'avalanche_c', 0x06380c0e0912312b5150364b9dc4542ba0dbbc85, 56211242),
        ('uniswap', '4', 'bnb',         0x28e2ea090877bf75740558f6bfb36a5ffee9e9df, 46001486),
        ('uniswap', '4', 'celo',        0x288dc841A52FCA2707c6947B3A777c5E56cd87BC, 48818694),
        ('uniswap', '4', 'monad',       0x188d586ddcf52439676ca21a244753fa19f9ea8e, 30255261),
        ('uniswap', '4', 'megaeth',     0xacb7e78fa05d562e0a5d3089ec896d57d057d38e, 8097067),

        -- Sushiswap V2
        ('sushiswap', '2', 'arbitrum', 0xc35DADB65012eC5796536bD9864eD8773aBc74C4, 70),
        ('sushiswap', '2', 'arbitrum_nova', 0xc35DADB65012eC5796536bD9864eD8773aBc74C4, 721),
        ('sushiswap', '2', 'avalanche_c', 0xc35DADB65012eC5796536bD9864eD8773aBc74C4, 506190),
        ('sushiswap', '2', 'base', 0x71524B4f93c58fcbF659783284E38825f0622859, 2631214),
        ('sushiswap', '2', 'blast', 0x42Fa929fc636e657AC568C0b5Cf38E203b67aC2b, 285621),
        ('sushiswap', '2', 'boba', 0xc35DADB65012eC5796536bD9864eD8773aBc74C4, 822561),
        ('sushiswap', '2', 'boba_avax', 0xc35DADB65012eC5796536bD9864eD8773aBc74C4, 3566),
        ('sushiswap', '2', 'boba_bnb', 0xc35DADB65012eC5796536bD9864eD8773aBc74C4, 3292),
        ('sushiswap', '2', 'bnb', 0xc35DADB65012eC5796536bD9864eD8773aBc74C4, 5205069),
        ('sushiswap', '2', 'bttc', 0xB45e53277a7e0F1D35f2a77160e91e25507f1763, 28215551),
        ('sushiswap', '2', 'celo', 0xc35DADB65012eC5796536bD9864eD8773aBc74C4, 7253488),
        ('sushiswap', '2', 'core', 0xB45e53277a7e0F1D35f2a77160e91e25507f1763, 8051339),
        ('sushiswap', '2', 'ethereum', 0xC0AEe478e3658e2610c5F7A4A2E1777cE9e4f2Ac, 10794229),
        ('sushiswap', '2', 'fantom', 0xc35DADB65012eC5796536bD9864eD8773aBc74C4, 2457879),
        ('sushiswap', '2', 'filecoin', 0x9B3336186a38E1b6c21955d112dbb0343Ee061eE, 3328632),
        ('sushiswap', '2', 'fuse', 0x43eA90e2b786728520e4f930d2A71a477BF2737C, 12943543),
        ('sushiswap', '2', 'haqq', 0xB45e53277a7e0F1D35f2a77160e91e25507f1763, 8673596),
        ('sushiswap', '2', 'harmony', 0xc35DADB65012eC5796536bD9864eD8773aBc74C4, 11256061),
        ('sushiswap', '2', 'heco', 0xc35DADB65012eC5796536bD9864eD8773aBc74C4, 2765001),
        ('sushiswap', '2', 'hemi', 0x9B3336186a38E1b6c21995d112dbb0343Ee061eE, 452730),
        ('sushiswap', '2', 'kava', 0xD408a20f1213286fB3158a2bfBf5bFfAca8bF269, 6891276),
        ('sushiswap', '2', 'linea', 0xFbc12984689e5f15626Bad03Ad60160Fe98B303C, 631714),
        ('sushiswap', '2', 'polygon', 0xc35DADB65012eC5796536bD9864eD8773aBc74C4, 11333218),
        ('sushiswap', '2', 'metis', 0x580ED43F3BBa06555785C81c2957efCCa71f7483, 8940434),
        ('sushiswap', '2', 'moonbeam', 0xc35DADB65012eC5796536bD9864eD8773aBc74C4, 503713),
        ('sushiswap', '2', 'moonriver', 0xc35DADB65012eC5796536bD9864eD8773aBc74C4, 428426),
        ('sushiswap', '2', 'okex', 0xc35DADB65012eC5796536bD9864eD8773aBc74C4, 2678488),
        ('sushiswap', '2', 'optimism', 0xFbc12984689e5f15626Bad03Ad60160Fe98B303C, 110882086),
        ('sushiswap', '2', 'palm', 0xc35DADB65012eC5796536bD9864eD8773aBc74C4, 902496),
        ('sushiswap', '2', 'zkevm', 0xB45e53277a7e0F1D35f2a77160e91e25507f1763, 6312213),
        ('sushiswap', '2', 'rootstock', 0xB45e53277a7e0F1D35f2a77160e91e25507f1763, 6365043),
        ('sushiswap', '2', 'scroll', 0xB45e53277a7e0F1D35f2a77160e91e25507f1763, 81841),
        ('sushiswap', '2', 'skale', 0x1aaF6eB4F85F8775400C1B10E6BbbD98b2FF8483, 5124080),
        ('sushiswap', '2', 'sonic', 0xB45e53277a7e0F1D35f2a77160e91e25507f1763, 347155),
        ('sushiswap', '2', 'telos', 0xc35DADB65012eC5796536bD9864eD8773aBc74C4, 182595783),
        ('sushiswap', '2', 'thundercore', 0xB45e53277a7e0F1D35f2a77160e91e25507f1763, 145330791),
        ('sushiswap', '2', 'gnosis', 0xc35DADB65012eC5796536bD9864eD8773aBc74C4, 14735904),
        ('sushiswap', '2', 'zetachain', 0x33d91116e0370970444B0281AB117e161fEbFcdD, 1552091),

        -- Sushiswap V3
        ('sushiswap', '3', 'arbitrum', 0x1af415a1EbA07a4986a52B6f2e7dE7003D82231e, 75998697),
        ('sushiswap', '3', 'arbitrum_nova', 0xaa26771d497814E81D305c511Efbb3ceD90BF5bd, 4242300),
        ('sushiswap', '3', 'avalanche_c', 0x3e603C14aF37EBdaD31709C4f848Fc6aD5BEc715, 28186391),
        ('sushiswap', '3', 'base', 0xc35DADB65012eC5796536bD9864eD8773aBc74C4, 1759510),
        ('sushiswap', '3', 'blast', 0x7680D4B43f3d1d54d6cfEeB2169463bFa7a6cf0d, 284122),
        ('sushiswap', '3', 'boba', 0x0BE808376Ecb75a5CF9bB6D237d16cd37893d904, 998556),
        ('sushiswap', '3', 'bnb', 0x126555dd55a39328F69400d6aE4F782Bd4C34ABb, 26976538),
        ('sushiswap', '3', 'bttc', 0xBBDe1d67297329148Fe1ED5e6B00114842728e65, 19975843),
        ('sushiswap', '3', 'celo', 0x93395129bd3fcf49d95730D3C2737c17990fF328, 18540094),
        ('sushiswap', '3', 'core', 0xc35DADB65012eC5796536bD9864eD8773aBc74C4, 5211850),
        ('sushiswap', '3', 'ethereum', 0xbACEB8eC6b9355Dfc0269C18bac9d6E2Bdc29C4F, 16955547),
        ('sushiswap', '3', 'fantom', 0x7770978eED668a3ba661d51a773d3a992Fc9DDCB, 58860670),
        ('sushiswap', '3', 'filecoin', 0xc35DADB65012eC5796536bD9864eD8773aBc74C4, 2867560),
        ('sushiswap', '3', 'fuse', 0x1b9d177CcdeA3c79B6c8F40761fc8Dc9d0500EAa, 22556035),
        ('sushiswap', '3', 'gnosis', 0xf78031CBCA409F2FB6876BDFDBc1b2df24cF9bEf, 27232871),
        ('sushiswap', '3', 'haqq', 0xc35DADB65012eC5796536bD9864eD8773aBc74C4, 6541826),
        ('sushiswap', '3', 'hemi', 0xCdBCd51a5E8728E0AF4895ce5771b7d17fF71959, 507517),
        ('sushiswap', '3', 'katana', 0x203e8740894c8955cB8950759876d7E7E45E04c1, 1858972),
        ('sushiswap', '3', 'kava', 0x1e9B24073183d5c6B7aE5FB4b8f0b1dd83FDC77a, 4214966),
        ('sushiswap', '3', 'linea', 0xc35DADB65012eC5796536bD9864eD8773aBc74C4, 53256),
        ('sushiswap', '3', 'metis', 0x145d82bCa93cCa2AE057D1c6f26245d1b9522E6F, 5220532),
        ('sushiswap', '3', 'moonbeam', 0x2ecd58F51819E8F8BA08A650BEA04Fc0DEa1d523, 3264275),
        ('sushiswap', '3', 'moonriver', 0x2F255d3f3C0A3726c6c99E74566c4b18E36E3ce6, 3945310),
        ('sushiswap', '3', 'optimism', 0x9c6522117e2ed1fE5bdb72bb0eD5E3f2bdE7DBe0, 85432013),
        ('sushiswap', '3', 'polygon', 0x917933899c6a5F8E37F31E19f92CdBFF7e8FF0e2, 41024971),
        ('sushiswap', '3', 'zkevm', 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506, 80860),
        ('sushiswap', '3', 'rootstock', 0x46B3fDF7b5CDe91Ac049936bF0bDb12c5d22202e, 6365060),
        ('sushiswap', '3', 'scroll', 0x46B3fDF7b5CDe91Ac049936bF0bDb12c5d22202e, 82522),
        ('sushiswap', '3', 'skale', 0x51d15889b66A2c919dBbD624d53B47a9E8feC4bB, 5124251),
        ('sushiswap', '3', 'sonic', 0x46B3fDF7b5CDe91Ac049936bF0bDb12c5d22202e, 347590),
        ('sushiswap', '3', 'thundercore', 0xc35DADB65012eC5796536bD9864eD8773aBc74C4, 132536332),
        ('sushiswap', '3', 'zetachain', 0xB45e53277a7e0F1D35f2a77160e91e25507f1763, 1551069),

        -- Pancakeswap V2
        ('pancakeswap', '2', 'bnb', 0xcA143Ce32Fe78f1f7019d7d551a6402fC5350c73, 6810423),
        ('pancakeswap', '2', 'ethereum', 0x1097053Fd2ea711dad45caCcc45EfF7548fCB362, 15623381),
        ('pancakeswap', '2', 'zksync', 0xd03D8D566183F0086d8D09A84E1e30b58Dd5619d, 8725632),
        ('pancakeswap', '2', 'zkevm', 0x02a84c1b3BBD7401a5f7fa98a384EBC70bB5749E, 1729938),
        ('pancakeswap', '2', 'arbitrum', 0x02a84c1b3BBD7401a5f7fa98a384EBC70bB5749E, 120027762),
        ('pancakeswap', '2', 'linea', 0x02a84c1b3BBD7401a5f7fa98a384EBC70bB5749E, 267546),
        ('pancakeswap', '2', 'base', 0x02a84c1b3BBD7401a5f7fa98a384EBC70bB5749E, 3350015),
        ('pancakeswap', '2', 'opbnb', 0x02a84c1b3BBD7401a5f7fa98a384EBC70bB5749E, 3352824),
        ('pancakeswap', '2', 'monad', 0x02a84c1b3BBD7401a5f7fa98a384EBC70bB5749E, 25796484),

        -- Pancakeswap V3
        ('pancakeswap', '3', 'bnb', 0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865, 26957718),
        ('pancakeswap', '3', 'ethereum', 0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865, 16951168),
        ('pancakeswap', '3', 'zksync', 0x1BB72E0CbbEA93c08f535fc7856E0338D7F7a8aB, 8723160),
        ('pancakeswap', '3', 'zkevm', 0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865, 750668),
        ('pancakeswap', '3', 'arbitrum', 0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865, 101036145),
        ('pancakeswap', '3', 'linea', 0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865, 1468),
        ('pancakeswap', '3', 'base', 0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865, 2916988),
        ('pancakeswap', '3', 'opbnb', 0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865, 1732543),
        ('pancakeswap', '3', 'monad', 0x0BFbCF9fa4f9C56B0F40a671Ad40E0805A091865, 25819360),

        -- Gammaswap Vdeltaswap
        ('gammaswap', 'deltaswap', 'ethereum', 0x5FbE219e88f6c6F214Ce6f5B1fcAa0294F31aE1b, 20142898),
        ('gammaswap', 'deltaswap', 'arbitrum', 0xCb85E1222f715a81b8edaeB73b28182fa37cffA8, 173467894),
        ('gammaswap', 'deltaswap', 'base', 0x9A9A171c69cC811dc6B59bB2f9990E34a22Fc971, 14457345),

        -- Camelot V2
        ('camelot', '2', 'arbitrum', 0x6EcCab422D763aC031210895C81787E87B43A652, 35061163),

        -- Camelot V3
        ('camelot', '3', 'arbitrum', 0x1a3c9B1d2F0529D97f2afC5136Cc23e58f1FD35B, 101163738),

        -- Curve StableSwap NG
        ('curve', 'stableswap_ng', 'ethereum',    0x6A8cbed756804B16E05E741eDaBd5cB544AE21bf, null),
        ('curve', 'stableswap_ng', 'polygon',     0x1764ee18e8B3ccA4787249Ceb249356192594585, null),
        ('curve', 'stableswap_ng', 'fantom',      0xe61Fb97Ef6eBFBa12B36Ffd7be785c1F5A2DE66b, null),
        ('curve', 'stableswap_ng', 'avalanche_c', 0x1764ee18e8B3ccA4787249Ceb249356192594585, null),
        ('curve', 'stableswap_ng', 'arbitrum',    0x9AF14D26075f142eb3F292D5065EB3faa646167b, null),
        ('curve', 'stableswap_ng', 'optimism',    0x5eeE3091f747E60a045a2E715a4c71e600e31F6E, null),
        ('curve', 'stableswap_ng', 'gnosis',      0xbC0797015fcFc47d9C1856639CaE50D0e69FbEE8, null),
        ('curve', 'stableswap_ng', 'celo',        0x1764ee18e8B3ccA4787249Ceb249356192594585, null),
        ('curve', 'stableswap_ng', 'zksync',      0xFcAb5d04e8e031334D5e8D2C166B08daB0BE6CaE, null),
        ('curve', 'stableswap_ng', 'base',        0xd2002373543Ce3527023C75e7518C274A51ce712, null),
        ('curve', 'stableswap_ng', 'mantle',      0x5eeE3091f747E60a045a2E715a4c71e600e31F6E, null),
        ('curve', 'stableswap_ng', 'kava',        0x1764ee18e8B3ccA4787249Ceb249356192594585, null),
        ('curve', 'stableswap_ng', 'fraxtal',     0xd2002373543Ce3527023C75e7518C274A51ce712, null),

        -- Curve TwoCrypto NG
        ('curve', 'twocrypto_ng', 'ethereum',    0x98EE851a00abeE0d95D08cF4CA2BdCE32aeaAF7F, null),
        ('curve', 'twocrypto_ng', 'polygon',     0x98EE851a00abeE0d95D08cF4CA2BdCE32aeaAF7F, null),
        ('curve', 'twocrypto_ng', 'fantom',      0x98EE851a00abeE0d95D08cF4CA2BdCE32aeaAF7F, null),
        ('curve', 'twocrypto_ng', 'avalanche_c', 0x98EE851a00abeE0d95D08cF4CA2BdCE32aeaAF7F, null),
        ('curve', 'twocrypto_ng', 'arbitrum',    0x98EE851a00abeE0d95D08cF4CA2BdCE32aeaAF7F, null),
        ('curve', 'twocrypto_ng', 'optimism',    0x98EE851a00abeE0d95D08cF4CA2BdCE32aeaAF7F, null),
        ('curve', 'twocrypto_ng', 'gnosis',      0x98EE851a00abeE0d95D08cF4CA2BdCE32aeaAF7F, null),
        ('curve', 'twocrypto_ng', 'celo',        0x98EE851a00abeE0d95D08cF4CA2BdCE32aeaAF7F, null),
        ('curve', 'twocrypto_ng', 'zksync',      0xf3a546AF64aFd6BB8292746BA66DB33aFAE72114, null),
        ('curve', 'twocrypto_ng', 'base',        0xc9Fe0C63Af9A39402e8a5514f9c43Af0322b665F, null),
        ('curve', 'twocrypto_ng', 'bnb',         0x98EE851a00abeE0d95D08cF4CA2BdCE32aeaAF7F, null),
        ('curve', 'twocrypto_ng', 'fraxtal',     0x98EE851a00abeE0d95D08cF4CA2BdCE32aeaAF7F, null),
        ('curve', 'twocrypto_ng', 'mantle',      0x98EE851a00abeE0d95D08cF4CA2BdCE32aeaAF7F, null),

        -- Curve Tricrypto NG
        ('curve', 'tricrypto_ng', 'ethereum',    0x0c0e5f2fF0ff18a3be9b835635039256dC4B4963, null),
        ('curve', 'tricrypto_ng', 'polygon',     0xC1b393EfEF38140662b91441C6710Aa704973228, null),
        ('curve', 'tricrypto_ng', 'fantom',      0x9AF14D26075f142eb3F292D5065EB3faa646167b, null),
        ('curve', 'tricrypto_ng', 'avalanche_c', 0x3d6cB2F6DcF47CDd9C13E4e3beAe9af041d8796a, null),
        ('curve', 'tricrypto_ng', 'arbitrum',    0xbC0797015fcFc47d9C1856639CaE50D0e69FbEE8, null),
        ('curve', 'tricrypto_ng', 'optimism',    0xc6C09471Ee39C7E30a067952FcC89c8922f9Ab53, null),
        ('curve', 'tricrypto_ng', 'gnosis',      0xb47988aD49DCE8D909c6f9Cf7B26caF04e1445c8, null),
        ('curve', 'tricrypto_ng', 'kava',        0x3d6cB2F6DcF47CDd9C13E4e3beAe9af041d8796a, null),
        ('curve', 'tricrypto_ng', 'celo',        0x3d6cB2F6DcF47CDd9C13E4e3beAe9af041d8796a, null),
        ('curve', 'tricrypto_ng', 'zksync',      0x5d4174C40f1246dABe49693845442927d5929f0D, null),
        ('curve', 'tricrypto_ng', 'base',        0xA5961898870943c68037F6848d2D866Ed2016bcB, null),
        ('curve', 'tricrypto_ng', 'bnb',         0xc55837710bc500F1E3c7bb9dd1d51F7c5647E657, null),
        ('curve', 'tricrypto_ng', 'fraxtal',     0xc9Fe0C63Af9A39402e8a5514f9c43Af0322b665F, null),
        ('curve', 'tricrypto_ng', 'mantle',      0x0C9D8c7e486e822C29488Ff51BFf0167B4650953, null),

        -- Curve StableSwap Legacy (pre-NG)
        ('curve', 'stableswap_legacy', 'ethereum',    0xB9fC157394Af804a3578134A6585C0dc9cc990d4, 12913531),
        ('curve', 'stableswap_legacy', 'ethereum',    0x0959158b6040d32d04c301a72cbfd6b39e21c9ae, null),  -- MetaPool factory, may have different event; topic0 filter returns 0 rows safely
        ('curve', 'stableswap_legacy', 'arbitrum',    0xb17b674D9c5CB2e441F8e196a2f048A81355d031, 1428272),
        ('curve', 'stableswap_legacy', 'avalanche_c', 0xb17b674D9c5CB2e441F8e196a2f048A81355d031, 6635966),
        ('curve', 'stableswap_legacy', 'optimism',    0x2db0E83599a91b508Ac268a6197b8B14F5e72840, 3497121),
        ('curve', 'stableswap_legacy', 'polygon',     0x722272d36ef0da72ff51c5a65db7b870e2e8d4ee, 20093387),
        ('curve', 'stableswap_legacy', 'gnosis',      0xD19Baeadc667Cf2015e395f2B08668Ef120f41F5, 21366595),
        ('curve', 'stableswap_legacy', 'fantom',      0x686d67265703d1f124c45e33d47d794c566889ba, 17081767)

) as t(protocol, version, blockchain, contract_address, min_block_number)
